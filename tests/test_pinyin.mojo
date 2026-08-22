from std.testing import (
    TestSuite,
    assert_equal,
    assert_raises,
    assert_true,
)
from std.collections import List

from yomi import (
    ChinesePolyphoneMode,
    PhoneticRepresentation,
    pinyin_full,
    pinyin_initials,
    pinyin_joined,
    pinyin_representations,
)


def _contains_text(values: List[PhoneticRepresentation], expected: StringSlice) -> Bool:
    for index in range(len(values)):
        if values[index].text() == expected:
            return True
    return False


def test_beijing_university_primary_forms() raises:
    var full = pinyin_full("北京大学")
    var joined = pinyin_joined("北京大学")
    var initials = pinyin_initials("北京大学")

    assert_equal(full.source_text(), "北京大学")
    assert_equal(full.text(), "bei jing da xue")
    assert_equal(joined.text(), "beijingdaxue")
    assert_equal(initials.text(), "bjdx")


def test_full_pinyin_separators_are_explicitly_unmapped() raises:
    var full = pinyin_full("北京大学")
    assert_equal(full.mapping_count(), 7)
    assert_true(full.mapping(0).has_source())
    assert_true(not full.mapping(1).has_source())
    assert_equal(full.mapping(1).output_start(), 3)
    assert_equal(full.mapping(1).output_end(), 4)

    var separator = full.source_ranges_for_output(3, 4)
    assert_equal(len(separator), 0)
    var jing = full.source_ranges_for_output(4, 8)
    assert_equal(len(jing), 1)
    assert_equal(jing[0].start(), 3)
    assert_equal(jing[0].end(), 6)


def test_joined_and_initials_preserve_each_source_scalar() raises:
    var joined = pinyin_joined("北京大学")
    assert_equal(joined.mapping_count(), 4)
    assert_equal(joined.mapping(0).output_start(), 0)
    assert_equal(joined.mapping(0).output_end(), 3)
    assert_equal(joined.mapping(0).source_start(), 0)
    assert_equal(joined.mapping(0).source_end(), 3)
    assert_equal(joined.mapping(3).output_start(), 9)
    assert_equal(joined.mapping(3).output_end(), 12)
    assert_equal(joined.mapping(3).source_start(), 9)
    assert_equal(joined.mapping(3).source_end(), 12)

    var initials = pinyin_initials("北京大学")
    assert_equal(initials.mapping_count(), 4)
    for index in range(4):
        assert_equal(initials.mapping(index).output_start(), index)
        assert_equal(initials.mapping(index).output_end(), index + 1)
        assert_equal(initials.mapping(index).source_start(), index * 3)
        assert_equal(initials.mapping(index).source_end(), index * 3 + 3)


def test_search_representations_match_yuru_common_polyphone_order() raises:
    var values = pinyin_representations("还没")
    assert_equal(len(values), 8)
    assert_equal(values[0].text(), "hai mei")
    assert_equal(values[1].text(), "haimei")
    assert_equal(values[2].text(), "hm")
    assert_equal(values[3].text(), "huan mei")
    assert_equal(values[4].text(), "huanmei")
    assert_equal(values[5].text(), "hai mo")
    assert_equal(values[6].text(), "haimo")
    assert_equal(values[7].text(), "fu mei")

    var none = pinyin_representations("还没", 8, ChinesePolyphoneMode.NONE)
    assert_equal(len(none), 3)
    assert_true(_contains_text(none, "hai mei"))
    assert_true(_contains_text(none, "haimei"))
    assert_true(not _contains_text(none, "huan mei"))
    assert_true(not _contains_text(none, "huanmei"))


def test_common_alternate_mapping_remains_source_exact() raises:
    var values = pinyin_representations("还没")
    var alternate_index = -1
    for index in range(len(values)):
        if values[index].text() == "huanmei":
            alternate_index = index
            break
    assert_true(alternate_index >= 0)
    var alternate = values[alternate_index].copy()
    assert_equal(alternate.mapping_count(), 2)
    assert_equal(alternate.mapping(0).output_start(), 0)
    assert_equal(alternate.mapping(0).output_end(), 4)
    assert_equal(alternate.mapping(0).source_start(), 0)
    assert_equal(alternate.mapping(0).source_end(), 3)
    assert_equal(alternate.mapping(1).output_start(), 4)
    assert_equal(alternate.mapping(1).output_end(), 7)
    assert_equal(alternate.mapping(1).source_start(), 3)
    assert_equal(alternate.mapping(1).source_end(), 6)


def test_chongqing_phrase_exception_and_mixed_source_gaps() raises:
    assert_equal(pinyin_full("重庆").text(), "chong qing")
    assert_equal(pinyin_joined("重庆").text(), "chongqing")
    assert_equal(pinyin_initials("重庆").text(), "cq")

    var mixed = pinyin_joined("A北🙂京.txt")
    assert_equal(mixed.source_text(), "A北🙂京.txt")
    assert_equal(mixed.text(), "beijing")
    assert_equal(mixed.mapping_count(), 2)
    assert_equal(mixed.mapping(0).source_start(), 1)
    assert_equal(mixed.mapping(0).source_end(), 4)
    assert_equal(mixed.mapping(1).source_start(), 8)
    assert_equal(mixed.mapping(1).source_end(), 11)


def test_table_covers_normal_searchable_bmp_han_text() raises:
    assert_equal(
        pinyin_joined("中国人民文件测试上海广州深圳香港台湾").text(),
        "zhongguorenminwenjianceshishanghaiguangzhoushenzhenxianggangtaiwan",
    )
    assert_equal(pinyin_full("〇").text(), "ling")


def test_empty_unsupported_cap_and_invalid_cap() raises:
    var empty = pinyin_full("")
    assert_equal(empty.source_text(), "")
    assert_equal(empty.text(), "")
    assert_equal(empty.mapping_count(), 0)

    var unsupported = pinyin_full("abc🙂")
    assert_equal(unsupported.source_text(), "abc🙂")
    assert_equal(unsupported.text(), "")
    assert_equal(unsupported.mapping_count(), 0)
    assert_equal(len(pinyin_representations("abc🙂")), 0)
    assert_equal(len(pinyin_representations("还没", 0)), 0)
    assert_equal(len(pinyin_representations("还没", 4)), 4)
    with assert_raises():
        _ = pinyin_representations("还没", -1)


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
