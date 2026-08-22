from std.testing import TestSuite, assert_equal

from yomi import (
    is_hangul_jamo,
    is_hangul_syllable,
    is_hiragana,
    is_kana,
    is_kanji,
    is_katakana,
)


def test_representative_pure_script_strings() raises:
    assert_equal(is_hiragana("ひらがな"), True)
    assert_equal(is_hiragana("らーめん"), True)
    assert_equal(is_hiragana("か\u3099"), True)
    assert_equal(is_katakana("カタカナ"), True)
    assert_equal(is_katakana("カ\u3099"), True)
    assert_equal(is_kana("ひらがな"), True)
    assert_equal(is_kana("カタカナ"), True)
    assert_equal(is_kana("か\u3099"), True)
    assert_equal(is_kana("らーメン"), True)
    assert_equal(is_kanji("漢字"), True)
    assert_equal(is_hangul_syllable("한국"), True)
    assert_equal(is_hangul_jamo("한"), True)
    assert_equal(is_hangul_jamo("ㅎㅏㄴ"), True)

    assert_equal(is_hiragana("らーメン"), False)


def test_empty_and_mixed_strings_are_rejected() raises:
    assert_equal(is_hiragana(""), False)
    assert_equal(is_katakana(""), False)
    assert_equal(is_kana(""), False)
    assert_equal(is_kanji(""), False)
    assert_equal(is_hangul_syllable(""), False)
    assert_equal(is_hangul_jamo(""), False)

    assert_equal(is_hiragana("かa"), False)
    assert_equal(is_katakana("カ漢"), False)
    assert_equal(is_kana("かa"), False)
    assert_equal(is_kana("カ漢"), False)
    assert_equal(is_kanji("漢a"), False)
    assert_equal(is_hangul_syllable("한a"), False)
    assert_equal(is_hangul_jamo("ㅎa"), False)


def test_hiragana_boundaries() raises:
    for value in [0x3041, 0x3096, 0x309D, 0x309E, 0x3099, 0x309A, 0x30FC]:
        assert_equal(is_hiragana(chr(value)), True)
    for value in [0x3040, 0x3097, 0x309C, 0x309F, 0x3098, 0x309B, 0x30FB, 0x30FD]:
        assert_equal(is_hiragana(chr(value)), False)


def test_katakana_boundaries() raises:
    for value in [0x30A1, 0x30FA, 0x30FD, 0x30FE, 0x30FC, 0x3099, 0x309A]:
        assert_equal(is_katakana(chr(value)), True)
    for value in [0x30A0, 0x30FB, 0x30FF, 0x3098, 0x309B]:
        assert_equal(is_katakana(chr(value)), False)


def test_kana_union_boundaries() raises:
    for value in [
        0x3041,
        0x3096,
        0x3099,
        0x309A,
        0x309B,
        0x309C,
        0x309D,
        0x309E,
        0x30A1,
        0x30FA,
        0x30FC,
        0x30FD,
        0x30FE,
    ]:
        assert_equal(is_kana(chr(value)), True)
    for value in [0x3040, 0x3097, 0x3098, 0x309F, 0x30A0, 0x30FB, 0x30FF]:
        assert_equal(is_kana(chr(value)), False)


def test_kanji_boundaries_and_extensions() raises:
    assert_equal(is_kanji(chr(0x4E00)), True)
    assert_equal(is_kanji(chr(0x9FFF)), True)
    assert_equal(is_kanji(chr(0x4DFF)), False)
    assert_equal(is_kanji(chr(0xA000)), False)


def test_hangul_syllable_boundaries_and_jamo() raises:
    assert_equal(is_hangul_syllable(chr(0xAC00)), True)
    assert_equal(is_hangul_syllable(chr(0xD7A3)), True)
    assert_equal(is_hangul_syllable(chr(0xABFF)), False)
    assert_equal(is_hangul_syllable(chr(0xD7A4)), False)
    assert_equal(is_hangul_syllable("가"), False)


def test_hangul_jamo_boundaries_and_exclusions() raises:
    for value in [0x1100, 0x1112, 0x1161, 0x1175, 0x11A8, 0x11C2, 0x3131, 0x3163]:
        assert_equal(is_hangul_jamo(chr(value)), True)
    for value in [
        0x10FF,
        0x1113,
        0x1160,
        0x1176,
        0x11A7,
        0x11C3,
        0x3130,
        0x3164,
        0xAC00,
    ]:
        assert_equal(is_hangul_jamo(chr(value)), False)


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
