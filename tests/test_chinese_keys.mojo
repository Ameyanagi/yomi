"""Typed, budgeted Chinese candidate and query key contracts."""

from std.testing import TestSuite, assert_equal, assert_raises, assert_true
from yomi import (
    ChinesePolyphoneMode,
    SearchKeyKind,
    chinese_candidate_keys,
    chinese_query_keys,
    pinyin_representations,
)


def test_candidate_keys_are_typed_and_differentially_match_pinyin_order() raises:
    var expected = pinyin_representations("还没")
    var bundle = chinese_candidate_keys("还没")
    assert_equal(bundle.count(), 9)
    assert_true(bundle.key(0).kind() == SearchKeyKind.ORIGINAL)
    assert_equal(bundle.key(0).text(), "还没")
    for index in range(len(expected)):
        assert_equal(bundle.key(index + 1).text(), expected[index].text())

    assert_true(bundle.key(1).kind() == SearchKeyKind.CHINESE_PINYIN_FULL)
    assert_true(bundle.key(2).kind() == SearchKeyKind.CHINESE_PINYIN_JOINED)
    assert_true(bundle.key(3).kind() == SearchKeyKind.CHINESE_PINYIN_INITIALS)
    assert_true(bundle.key(4).kind() == SearchKeyKind.CHINESE_PINYIN_FULL)
    assert_true(bundle.key(5).kind() == SearchKeyKind.CHINESE_PINYIN_JOINED)


def test_candidate_deduplication_uses_kind_and_text_together() raises:
    var bundle = chinese_candidate_keys("中", 9, 1024, ChinesePolyphoneMode.NONE)
    assert_equal(bundle.count(), 4)
    assert_equal(bundle.key(1).text(), "zhong")
    assert_equal(bundle.key(2).text(), "zhong")
    assert_true(bundle.key(1).kind() == SearchKeyKind.CHINESE_PINYIN_FULL)
    assert_true(bundle.key(2).kind() == SearchKeyKind.CHINESE_PINYIN_JOINED)
    assert_equal(bundle.key(3).text(), "z")


def test_candidate_caps_and_budget_are_enforced_before_growth() raises:
    var capped = chinese_candidate_keys("北京大学", 4)
    assert_equal(capped.count(), 4)
    assert_equal(capped.key(1).text(), "bei jing da xue")
    assert_equal(capped.key(2).text(), "beijingdaxue")
    assert_equal(capped.key(3).text(), "bjdx")

    var initials_only = chinese_candidate_keys("北京大学", 9, 4)
    assert_equal(initials_only.count(), 2)
    assert_true(initials_only.key(1).kind() == SearchKeyKind.CHINESE_PINYIN_INITIALS)
    assert_equal(initials_only.key(1).text(), "bjdx")

    var full_only = chinese_candidate_keys("北京大学", 9, 15)
    assert_equal(full_only.count(), 2)
    assert_equal(full_only.key(1).text(), "bei jing da xue")

    var long_source = String()
    for _ in range(1024):
        long_source += "中"
    var rejected_growth = chinese_candidate_keys(long_source, 9, 64)
    assert_equal(rejected_growth.count(), 1)
    assert_equal(rejected_growth.key(0).text(), long_source)

    assert_equal(chinese_candidate_keys("北京", 0).count(), 0)
    assert_equal(chinese_candidate_keys("北京", 1).count(), 1)
    assert_equal(chinese_candidate_keys("北京", 9, 0).count(), 1)
    with assert_raises(contains="within [0, 9]"):
        _ = chinese_candidate_keys("北京", 10)
    with assert_raises(contains="must be nonnegative"):
        _ = chinese_candidate_keys("北京", 9, -1)


def test_polyphones_are_single_character_common_substitutions() raises:
    var common = chinese_candidate_keys("还没")
    assert_equal(common.key(4).text(), "huan mei")
    assert_equal(common.key(5).text(), "huanmei")
    assert_equal(common.key(6).text(), "hai mo")
    assert_equal(common.key(7).text(), "haimo")
    assert_equal(common.key(8).text(), "fu mei")

    var none = chinese_candidate_keys("还没", 9, 1024, ChinesePolyphoneMode.NONE)
    assert_equal(none.count(), 4)
    assert_equal(none.key(1).text(), "hai mei")
    assert_equal(none.key(2).text(), "haimei")
    assert_equal(none.key(3).text(), "hm")


def test_candidate_mappings_remain_exact_for_gaps_and_alternates() raises:
    var mixed = chinese_candidate_keys("A北🙂京.txt")
    var joined = mixed.key(2).representation()
    assert_equal(joined.text(), "beijing")
    assert_equal(joined.mapping_count(), 2)
    assert_equal(joined.mapping(0).source_start(), 1)
    assert_equal(joined.mapping(0).source_end(), 4)
    assert_equal(joined.mapping(1).source_start(), 8)
    assert_equal(joined.mapping(1).source_end(), 11)

    var alternate = chinese_candidate_keys("还没").key(5).representation()
    assert_equal(alternate.text(), "huanmei")
    var first = alternate.source_ranges_for_output(0, 4)
    assert_equal(len(first), 1)
    assert_equal(first[0].start(), 0)
    assert_equal(first[0].end(), 3)
    var second = alternate.source_ranges_for_output(4, 7)
    assert_equal(len(second), 1)
    assert_equal(second[0].start(), 3)
    assert_equal(second[0].end(), 6)


def test_query_keys_match_yuru_order_and_preserve_fullwidth_sources() raises:
    var bundle = chinese_query_keys("ＢＪＤＸ")
    assert_equal(bundle.count(), 4)
    assert_true(bundle.key(0).kind() == SearchKeyKind.QUERY_ORIGINAL)
    assert_equal(bundle.key(0).text(), "ＢＪＤＸ")
    assert_true(bundle.key(1).kind() == SearchKeyKind.QUERY_NORMALIZED)
    assert_true(bundle.key(2).kind() == SearchKeyKind.QUERY_INITIALS)
    assert_true(bundle.key(3).kind() == SearchKeyKind.QUERY_CHINESE_PINYIN)
    for index in range(1, 4):
        assert_equal(bundle.key(index).text(), "bjdx")

    var normalized = bundle.key(2).representation()
    assert_equal(normalized.mapping_count(), 4)
    for index in range(4):
        assert_equal(normalized.mapping(index).output_start(), index)
        assert_equal(normalized.mapping(index).output_end(), index + 1)
        assert_equal(normalized.mapping(index).source_start(), index * 3)
        assert_equal(normalized.mapping(index).source_end(), index * 3 + 3)


def test_query_count_and_byte_budgets_are_deterministic() raises:
    var literal = chinese_query_keys("bjdx", 1)
    assert_equal(literal.count(), 1)
    var initials = chinese_query_keys("bjdx", 4, 4)
    assert_equal(initials.count(), 2)
    assert_true(initials.key(1).kind() == SearchKeyKind.QUERY_INITIALS)
    var no_generated = chinese_query_keys("ＢＪＤＸ", 4, 0)
    assert_equal(no_generated.count(), 2)
    assert_true(no_generated.key(1).kind() == SearchKeyKind.QUERY_NORMALIZED)
    assert_equal(chinese_query_keys("a").count(), 1)
    assert_equal(chinese_query_keys("abc-123").count(), 1)
    assert_equal(chinese_query_keys("abc", 0).count(), 0)
    with assert_raises(contains="within [0, 4]"):
        _ = chinese_query_keys("abc", 5)
    with assert_raises(contains="must be nonnegative"):
        _ = chinese_query_keys("abc", 4, -1)


def test_moving_accessors_transfer_owned_storage() raises:
    var bundle = chinese_candidate_keys("北京大学", 4, 1024, ChinesePolyphoneMode.NONE)
    var keys = bundle^.take_keys()
    assert_equal(len(keys), 4)
    var key = keys[1].copy()
    var representation = key^.take_representation()
    assert_equal(representation.text(), "bei jing da xue")


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
