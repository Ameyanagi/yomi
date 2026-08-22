"""Typed Korean candidate-key bundle contracts."""

from std.testing import TestSuite, assert_equal, assert_raises, assert_true
from yomi import SearchKeyKind, decompose_hangul, korean_candidate_keys


def test_korean_candidate_keys_have_stable_kinds_and_text() raises:
    var keys = korean_candidate_keys("서울")
    assert_equal(keys.count(), 5)
    assert_true(keys.key(0).kind() == SearchKeyKind.ORIGINAL)
    assert_equal(keys.key(0).text(), "서울")
    assert_true(keys.key(1).kind() == SearchKeyKind.KOREAN_ROMANIZED)
    assert_equal(keys.key(1).text(), "seoul")
    assert_true(keys.key(2).kind() == SearchKeyKind.KOREAN_ROMANIZED)
    assert_equal(keys.key(2).text(), "seo ul")
    assert_true(keys.key(3).kind() == SearchKeyKind.KOREAN_INITIALS)
    assert_equal(keys.key(3).text(), "ㅅㅇ")
    assert_true(keys.key(4).kind() == SearchKeyKind.KOREAN_KEYBOARD)
    assert_equal(keys.key(4).text(), "tjdnf")


def test_korean_candidate_key_caps_and_budget_are_deterministic() raises:
    var limited = korean_candidate_keys("서울", 2)
    assert_equal(limited.count(), 2)
    assert_true(limited.key(1).kind() == SearchKeyKind.KOREAN_ROMANIZED)

    var base_only = korean_candidate_keys("서울", 5, 0)
    assert_equal(base_only.count(), 1)
    assert_equal(base_only.key(0).text(), "서울")

    var exact_romanized_budget = korean_candidate_keys("서울", 5, 5)
    assert_equal(exact_romanized_budget.count(), 2)
    assert_equal(exact_romanized_budget.key(1).text(), "seoul")

    var cumulative_budget = korean_candidate_keys("서울", 5, 11)
    assert_equal(cumulative_budget.count(), 3)
    assert_equal(cumulative_budget.key(2).text(), "seo ul")

    with assert_raises(contains="within [0, 5]"):
        _ = korean_candidate_keys("서울", 6)
    with assert_raises(contains="must be nonnegative"):
        _ = korean_candidate_keys("서울", 5, -1)


def test_korean_bundle_preserves_empty_passthrough_and_decomposed_input() raises:
    var empty = korean_candidate_keys("")
    assert_equal(empty.count(), 4)
    for index in range(empty.count()):
        assert_equal(empty.key(index).text(), "")

    var passthrough = korean_candidate_keys("notes")
    assert_equal(passthrough.count(), 4)
    for index in range(passthrough.count()):
        assert_equal(passthrough.key(index).text(), "notes")

    var composed = korean_candidate_keys("한")
    var decomposed = korean_candidate_keys("한")
    for index in range(1, 4):
        assert_equal(decomposed.key(index).text(), composed.key(index).text())


def test_korean_candidate_key_projection_targets_original_syllables() raises:
    var keys = korean_candidate_keys("서울")
    var romanized = keys.key(1).representation()
    var ranges = romanized.source_ranges_for_output(0, 3)
    assert_equal(len(ranges), 1)
    assert_equal(ranges[0].start(), 0)
    assert_equal(ranges[0].end(), 3)

    var spaced = keys.key(2).representation()
    var separator = spaced.source_ranges_for_output(3, 4)
    assert_equal(len(separator), 0)
    var second = spaced.source_ranges_for_output(4, 6)
    assert_equal(len(second), 1)
    assert_equal(second[0].start(), 3)
    assert_equal(second[0].end(), 6)


def test_all_modern_syllables_have_nfc_nfd_equivalent_generated_keys() raises:
    var source = String()
    for offset in range(11172):
        source += chr(0xAC00 + offset)
    var decomposed = decompose_hangul(source).text()
    var nfc = korean_candidate_keys(source, 5, 1_000_000)
    var nfd = korean_candidate_keys(decomposed, 5, 1_000_000)
    assert_equal(nfc.count(), 5)
    assert_equal(nfd.count(), 5)
    for index in range(1, 5):
        assert_true(nfc.key(index).kind() == nfd.key(index).kind())
        assert_equal(nfc.key(index).text(), nfd.key(index).text())


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
