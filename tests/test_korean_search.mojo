from std.testing import TestSuite, assert_equal, assert_true

from yomi import (
    hangul_choseong,
    hangul_keyboard,
    romanize_hangul,
    romanize_hangul_spaced,
)


comptime S_BASE = 0xAC00
comptime L_COUNT = 19
comptime V_COUNT = 21
comptime T_COUNT = 28
comptime N_COUNT = V_COUNT * T_COUNT
comptime S_COUNT = L_COUNT * N_COUNT


def _syllable(initial: Int, vowel: Int, final_consonant: Int) -> String:
    return chr(S_BASE + initial * N_COUNT + vowel * T_COUNT + final_consonant)


def test_yuru_hangeul_fixtures_and_exact_mappings() raises:
    var joined = romanize_hangul("한글")
    assert_equal(joined.text(), "hangeul")
    assert_equal(joined.mapping_count(), 2)
    assert_equal(joined.mapping(0).output_start(), 0)
    assert_equal(joined.mapping(0).output_end(), 3)
    assert_equal(joined.mapping(0).source_start(), 0)
    assert_equal(joined.mapping(0).source_end(), 3)
    assert_equal(joined.mapping(1).output_start(), 3)
    assert_equal(joined.mapping(1).output_end(), 7)
    assert_equal(joined.mapping(1).source_start(), 3)
    assert_equal(joined.mapping(1).source_end(), 6)

    var spaced = romanize_hangul_spaced("한글")
    assert_equal(spaced.text(), "han geul")
    assert_equal(spaced.mapping_count(), 3)
    assert_true(spaced.mapping(0).has_source())
    assert_true(not spaced.mapping(1).has_source())
    assert_equal(spaced.mapping(1).output_start(), 3)
    assert_equal(spaced.mapping(1).output_end(), 4)
    assert_equal(spaced.mapping(2).source_start(), 3)
    assert_equal(spaced.mapping(2).source_end(), 6)

    assert_equal(hangul_choseong("한글").text(), "ㅎㄱ")
    var keyboard = hangul_keyboard("한글")
    assert_equal(keyboard.text(), "gksrmf")
    assert_equal(keyboard.mapping_count(), 2)
    assert_equal(keyboard.mapping(0).output_start(), 0)
    assert_equal(keyboard.mapping(0).output_end(), 3)
    assert_equal(keyboard.mapping(1).output_start(), 3)
    assert_equal(keyboard.mapping(1).output_end(), 6)


def test_romanization_reference_components() raises:
    var initial_outputs = [
        "ga",
        "kka",
        "na",
        "da",
        "tta",
        "ra",
        "ma",
        "ba",
        "ppa",
        "sa",
        "ssa",
        "a",
        "ja",
        "jja",
        "cha",
        "ka",
        "ta",
        "pa",
        "ha",
    ]
    for initial in range(L_COUNT):
        assert_equal(
            romanize_hangul(_syllable(initial, 0, 0)).text(),
            initial_outputs[initial],
        )

    var vowel_outputs = [
        "a",
        "ae",
        "ya",
        "yae",
        "eo",
        "e",
        "yeo",
        "ye",
        "o",
        "wa",
        "wae",
        "oe",
        "yo",
        "u",
        "wo",
        "we",
        "wi",
        "yu",
        "eu",
        "ui",
        "i",
    ]
    for vowel in range(V_COUNT):
        assert_equal(
            romanize_hangul(_syllable(11, vowel, 0)).text(),
            vowel_outputs[vowel],
        )

    var final_outputs = [
        "ga",
        "gak",
        "gak",
        "gak",
        "gan",
        "gan",
        "gan",
        "gat",
        "gal",
        "gak",
        "gam",
        "gap",
        "gal",
        "gal",
        "gap",
        "gal",
        "gam",
        "gap",
        "gap",
        "gat",
        "gat",
        "gang",
        "gat",
        "gat",
        "gak",
        "gat",
        "gap",
        "gat",
    ]
    for final_consonant in range(T_COUNT):
        assert_equal(
            romanize_hangul(_syllable(0, 0, final_consonant)).text(),
            final_outputs[final_consonant],
        )


def test_dubeolsik_reference_components() raises:
    var initial_outputs = [
        "rk",
        "rk",
        "sk",
        "ek",
        "ek",
        "fk",
        "ak",
        "qk",
        "qk",
        "tk",
        "tk",
        "dk",
        "wk",
        "wk",
        "ck",
        "zk",
        "xk",
        "vk",
        "gk",
    ]
    for initial in range(L_COUNT):
        assert_equal(
            hangul_keyboard(_syllable(initial, 0, 0)).text(),
            initial_outputs[initial],
        )

    var vowel_outputs = [
        "dk",
        "do",
        "di",
        "do",
        "dj",
        "dp",
        "du",
        "dp",
        "dh",
        "dhk",
        "dho",
        "dhl",
        "dy",
        "dn",
        "dnj",
        "dnp",
        "dnl",
        "db",
        "dm",
        "dml",
        "dl",
    ]
    for vowel in range(V_COUNT):
        assert_equal(
            hangul_keyboard(_syllable(11, vowel, 0)).text(),
            vowel_outputs[vowel],
        )

    var final_outputs = [
        "rk",
        "rkr",
        "rkr",
        "rkrt",
        "rks",
        "rksw",
        "rksg",
        "rke",
        "rkf",
        "rkfr",
        "rkfa",
        "rkfq",
        "rkft",
        "rkfx",
        "rkfv",
        "rkfg",
        "rka",
        "rkq",
        "rkqt",
        "rkt",
        "rkt",
        "rkd",
        "rkw",
        "rkc",
        "rkz",
        "rkx",
        "rkv",
        "rkg",
    ]
    for final_consonant in range(T_COUNT):
        assert_equal(
            hangul_keyboard(_syllable(0, 0, final_consonant)).text(),
            final_outputs[final_consonant],
        )


def test_nfc_and_canonical_nfd_are_equivalent() raises:
    var nfd = String("한글")
    assert_equal(romanize_hangul(nfd).text(), romanize_hangul("한글").text())
    assert_equal(
        romanize_hangul_spaced(nfd).text(),
        romanize_hangul_spaced("한글").text(),
    )
    assert_equal(hangul_keyboard(nfd).text(), hangul_keyboard("한글").text())

    var joined = romanize_hangul(nfd)
    assert_equal(joined.mapping_count(), 2)
    assert_equal(joined.mapping(0).source_start(), 0)
    assert_equal(joined.mapping(0).source_end(), 9)
    assert_equal(joined.mapping(1).source_start(), 9)
    assert_equal(joined.mapping(1).source_end(), 18)


def test_mixed_text_and_extenders_preserve_source() raises:
    var joined = romanize_hangul("A한글.txt🙂")
    assert_equal(joined.text(), "Ahangeul.txt🙂")
    assert_equal(joined.mapping_count(), 8)

    var spaced = romanize_hangul_spaced("A한글.txt🙂")
    assert_equal(spaced.text(), "Ahan geul.txt🙂")
    assert_equal(spaced.mapping_count(), 9)
    assert_true(not spaced.mapping(2).has_source())

    var keyboard = hangul_keyboard("A한글.txt🙂")
    assert_equal(keyboard.text(), "Agksrmf.txt🙂")

    var extended = romanize_hangul("한\u0301")
    assert_equal(extended.text(), "han")
    assert_equal(extended.mapping_count(), 1)
    assert_equal(extended.mapping(0).source_start(), 0)
    assert_equal(extended.mapping(0).source_end(), 5)

    var nfd_extended = romanize_hangul("한\u0301")
    assert_equal(nfd_extended.text(), "han")
    assert_equal(nfd_extended.mapping(0).source_end(), 11)


def test_spaced_projection_ignores_generated_separator() raises:
    var spaced = romanize_hangul_spaced("한글")
    var separator = spaced.source_ranges_for_output(3, 4)
    assert_equal(len(separator), 0)

    var second = spaced.source_ranges_for_output(4, 8)
    assert_equal(len(second), 1)
    assert_equal(second[0].start(), 3)
    assert_equal(second[0].end(), 6)

    var whole = spaced.source_ranges_for_output(0, 8)
    assert_equal(len(whole), 1)
    assert_equal(whole[0].start(), 0)
    assert_equal(whole[0].end(), 6)


def test_empty_and_incomplete_jamo_inputs() raises:
    assert_equal(romanize_hangul("").text(), "")
    assert_equal(romanize_hangul_spaced("").mapping_count(), 0)
    assert_equal(hangul_keyboard("").text(), "")

    assert_equal(romanize_hangul("ᄀ").text(), "ᄀ")
    assert_equal(hangul_keyboard("ㄱ").text(), "ㄱ")


def test_all_modern_syllables_transform_and_map_once() raises:
    var source = String()
    for index in range(S_COUNT):
        source += chr(S_BASE + index)

    var romanized = romanize_hangul(source)
    var keyboard = hangul_keyboard(source)
    assert_equal(romanized.mapping_count(), S_COUNT)
    assert_equal(keyboard.mapping_count(), S_COUNT)

    for index in range(S_COUNT):
        var romanized_mapping = romanized.mapping(index)
        var keyboard_mapping = keyboard.mapping(index)
        assert_true(romanized_mapping.output_end() > romanized_mapping.output_start())
        assert_true(keyboard_mapping.output_end() > keyboard_mapping.output_start())
        assert_equal(romanized_mapping.source_start(), index * 3)
        assert_equal(romanized_mapping.source_end(), index * 3 + 3)
        assert_equal(keyboard_mapping.source_start(), index * 3)
        assert_equal(keyboard_mapping.source_end(), index * 3 + 3)

    for codepoint in romanized.text().codepoints():
        assert_true(codepoint.to_u32() < 128)
    for codepoint in keyboard.text().codepoints():
        assert_true(codepoint.to_u32() < 128)


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
