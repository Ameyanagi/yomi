"""Typed Korean candidate-key bundle contracts."""

from std.testing import TestSuite, assert_equal, assert_raises, assert_true
from yomi import SearchKeyKind, korean_candidate_keys


def test_korean_candidate_keys_have_stable_kinds_and_text() raises:
    var keys = korean_candidate_keys("서울")
    assert_equal(keys.count(), 4)
    assert_true(keys.key(0).kind() == SearchKeyKind.ORIGINAL)
    assert_equal(keys.key(0).text(), "서울")
    assert_true(keys.key(1).kind() == SearchKeyKind.KOREAN_ROMANIZED)
    assert_equal(keys.key(1).text(), "seoul")
    assert_true(keys.key(2).kind() == SearchKeyKind.KOREAN_INITIALS)
    assert_equal(keys.key(2).text(), "ㅅㅇ")
    assert_true(keys.key(3).kind() == SearchKeyKind.KOREAN_KEYBOARD)
    assert_equal(keys.key(3).text(), "tjdnf")


def test_korean_candidate_key_caps_and_budget_are_deterministic() raises:
    var limited = korean_candidate_keys("서울", 2)
    assert_equal(limited.count(), 2)
    assert_true(limited.key(1).kind() == SearchKeyKind.KOREAN_ROMANIZED)

    var base_only = korean_candidate_keys("서울", 4, 0)
    assert_equal(base_only.count(), 1)
    assert_equal(base_only.key(0).text(), "서울")

    var exact_romanized_budget = korean_candidate_keys("서울", 4, 5)
    assert_equal(exact_romanized_budget.count(), 2)
    assert_equal(exact_romanized_budget.key(1).text(), "seoul")

    var cumulative_budget = korean_candidate_keys("서울", 4, 11)
    assert_equal(cumulative_budget.count(), 3)
    assert_equal(cumulative_budget.key(2).text(), "ㅅㅇ")

    with assert_raises(contains="within [0, 4]"):
        _ = korean_candidate_keys("서울", 5)
    with assert_raises(contains="must be nonnegative"):
        _ = korean_candidate_keys("서울", 4, -1)


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


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
