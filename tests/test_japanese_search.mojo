from std.collections import List
from std.testing import TestSuite, assert_equal, assert_raises, assert_true

from yomi import (
    PhoneticRepresentation,
    SearchKeyBundle,
    SearchKeyKind,
    japanese_kana_key,
    japanese_candidate_keys,
    japanese_query_kana,
    japanese_query_keys,
    japanese_romaji_key,
    japanese_search_keys,
    japanese_search_representations,
)


def _contains_text(values: List[PhoneticRepresentation], expected: StringSlice) -> Bool:
    for index in range(len(values)):
        if values[index].text() == expected:
            return True
    return False


def test_width_dash_space_and_case_compatibility() raises:
    var kana = japanese_kana_key("ｶﾒﾗ　ＡＢＣ１２３")
    assert_equal(kana.text(), "かめら abc123")

    var dashes = japanese_kana_key("ハッピー-ｰ－―−゠")
    assert_equal(dashes.text(), "はっぴ-------")
    assert_equal(japanese_romaji_key("ハッピー").text(), "happi-")

    var halfwidth = String()
    for value in range(0xFF61, 0xFF9E):
        halfwidth += chr(value)
    assert_equal(
        japanese_kana_key(halfwidth).text(),
        "。「」、・をぁぃぅぇぉゃゅょっ-あいうえおかきくけこさしすせそたちつてとなにぬねのはひふへほまみむめもやゆよらりるれろわん",
    )


def test_halfwidth_voicing_and_romaji_keep_exact_source_ranges() raises:
    var kana = japanese_kana_key("ｶﾞ")
    assert_equal(kana.text(), "が")
    assert_equal(kana.mapping_count(), 1)
    assert_equal(kana.mapping(0).source_start(), 0)
    assert_equal(kana.mapping(0).source_end(), 6)
    assert_equal(japanese_kana_key("ﾊﾟｳﾞ").text(), "ぱゔ")

    var decomposed = String("カ\u3099")
    var decomposed_key = japanese_kana_key(decomposed)
    assert_equal(decomposed_key.text(), "が")
    assert_equal(decomposed_key.mapping_count(), 1)
    assert_equal(decomposed_key.mapping(0).source_end(), 6)

    var extended = String("カ\u0301Ａ\u0301")
    var extended_key = japanese_kana_key(extended)
    assert_equal(extended_key.text(), "か\u0301a\u0301")
    assert_equal(extended_key.mapping_count(), 2)
    assert_equal(extended_key.mapping(0).source_start(), 0)
    assert_equal(extended_key.mapping(0).source_end(), 5)
    assert_equal(extended_key.mapping(1).source_start(), 5)
    assert_equal(extended_key.mapping(1).source_end(), 10)

    var romaji = japanese_romaji_key("キャ")
    assert_equal(romaji.text(), "kya")
    assert_equal(romaji.mapping_count(), 1)
    assert_equal(romaji.mapping(0).source_start(), 0)
    assert_equal(romaji.mapping(0).source_end(), 6)


def test_ime_query_aliases_are_canonicalized_to_kana() raises:
    assert_equal(japanese_query_kana("zyu").text(), "じゅ")
    assert_equal(japanese_query_kana("nn").text(), "ん")
    assert_equal(japanese_query_kana("xn").text(), "ん")
    assert_equal(japanese_query_kana("ltsu").text(), "っ")
    assert_equal(japanese_query_kana("xtu").text(), "っ")
    assert_equal(japanese_query_kana("lyu").text(), "ゅ")
    assert_equal(japanese_query_kana("xya").text(), "ゃ")
    assert_equal(japanese_query_kana("xye").text(), "ぇ")
    assert_equal(japanese_query_kana("gakkou").text(), "がっこう")
    assert_equal(japanese_query_kana("8gatu").text(), "8がつ")


def test_ime_query_mapping_covers_the_complete_alias() raises:
    var query = japanese_query_kana("ＺＹＵ")
    assert_equal(query.text(), "じゅ")
    assert_equal(query.mapping_count(), 1)
    assert_equal(query.mapping(0).output_start(), 0)
    assert_equal(query.mapping(0).output_end(), 6)
    assert_equal(query.mapping(0).source_start(), 0)
    assert_equal(query.mapping(0).source_end(), 9)


def _bundle_contains(
    bundle: SearchKeyBundle,
    kind: SearchKeyKind,
    expected: StringSlice,
) raises -> Bool:
    for index in range(bundle.count()):
        var key = bundle.key(index)
        if key.kind() == kind and key.text() == expected:
            return True
    return False


def test_ambiguous_query_fanout_is_typed_deduped_and_strictly_capped() raises:
    var variants = japanese_query_keys("kanya")
    assert_true(
        _bundle_contains(
            variants,
            SearchKeyKind.QUERY_JAPANESE_ROMAJI_TO_KANA,
            "かにゃ",
        )
    )
    assert_true(
        _bundle_contains(
            variants,
            SearchKeyKind.QUERY_JAPANESE_ROMAJI_TO_KANA,
            "かんや",
        )
    )
    assert_true(variants.count() <= 8)

    var capped = japanese_query_keys("kanya", 2)
    assert_equal(capped.count(), 2)
    assert_true(capped.key(0).kind() == SearchKeyKind.QUERY_ORIGINAL)
    with assert_raises():
        _ = japanese_query_keys("kanya", 9)
    with assert_raises():
        _ = japanese_query_keys("kanya", -1)


def test_query_fanout_trims_ascii_edges_but_preserves_exact_source() raises:
    var variants = japanese_query_keys(" \tkanya\r ")
    var found = False
    for index in range(variants.count()):
        var key = variants.key(index)
        if key.text() != "かんや":
            continue
        var representation = key.representation()
        var nasal = representation.source_ranges_for_output(3, 6)
        assert_equal(len(nasal), 1)
        assert_equal(nasal[0].start(), 4)
        assert_equal(nasal[0].end(), 5)
        found = True
    assert_true(found)


def test_numeric_query_reading_precedes_ordinary_romaji() raises:
    var variants = japanese_query_keys("８gatsu")
    var numeric_index = -1
    var ordinary_index = -1
    for index in range(variants.count()):
        var key = variants.key(index)
        if key.text() == "はちがつ":
            numeric_index = index
            var number = key.representation().source_ranges_for_output(0, 6)
            assert_equal(len(number), 1)
            assert_equal(number[0].start(), 0)
            assert_equal(number[0].end(), 3)
        elif key.text() == "8がつ":
            ordinary_index = index
    assert_true(numeric_index >= 0)
    assert_true(ordinary_index > numeric_index)

    var leading_zero = japanese_query_keys("08gatsu")
    assert_true(
        not _bundle_contains(
            leading_zero,
            SearchKeyKind.QUERY_JAPANESE_ROMAJI_TO_KANA,
            "はちがつ",
        )
    )


def test_long_vowel_query_variants_have_exact_source_mappings() raises:
    var variants = japanese_query_keys("ＴＯＫＹＯ")
    var found = False
    for index in range(variants.count()):
        var key = variants.key(index)
        if key.text() != "とうきょう":
            continue
        assert_true(key.kind() == SearchKeyKind.QUERY_JAPANESE_ROMAJI_TO_KANA)
        var representation = key.representation()
        assert_equal(representation.source_text(), "ＴＯＫＹＯ")
        var first = representation.source_ranges_for_output(0, 6)
        assert_equal(len(first), 1)
        assert_equal(first[0].start(), 0)
        assert_equal(first[0].end(), 6)
        var second = representation.source_ranges_for_output(6, 15)
        assert_equal(len(second), 1)
        assert_equal(second[0].start(), 6)
        assert_equal(second[0].end(), 15)
        found = True
    assert_true(found)


def test_typed_candidate_bundle_preserves_kind_and_legacy_order() raises:
    var bundle = japanese_search_keys("8月")
    assert_true(bundle.count() <= 6)
    assert_true(bundle.key(0).kind() == SearchKeyKind.JAPANESE_KANA)
    assert_true(_bundle_contains(bundle, SearchKeyKind.JAPANESE_ROMAJI, "hachigatsu"))

    var legacy = japanese_search_representations("8月")
    assert_equal(legacy[0].text(), bundle.key(0).text())


def test_unified_candidate_bundle_has_base_keys_and_generated_budget() raises:
    var bundle = japanese_candidate_keys("ｶﾒﾗ　ＡＢＣ")
    assert_true(bundle.count() <= 8)
    assert_true(bundle.key(0).kind() == SearchKeyKind.ORIGINAL)
    assert_equal(bundle.key(0).text(), "ｶﾒﾗ　ＡＢＣ")
    assert_true(bundle.key(1).kind() == SearchKeyKind.NORMALIZED)
    assert_equal(bundle.key(1).text(), "カメラ abc")
    assert_true(_bundle_contains(bundle, SearchKeyKind.JAPANESE_KANA, "かめら abc"))
    assert_true(_bundle_contains(bundle, SearchKeyKind.JAPANESE_ROMAJI, "kamera abc"))

    var base_only = japanese_candidate_keys("カメラ", 2, 18)
    assert_equal(base_only.count(), 2)
    # The required original/normalized bytes do not consume the generated
    # budget, so the six-byte romaji key remains eligible.
    var generated_budget = japanese_candidate_keys("カメラ", 8, 6)
    assert_true(
        _bundle_contains(
            generated_budget,
            SearchKeyKind.JAPANESE_ROMAJI,
            "kamera",
        )
    )
    with assert_raises():
        _ = japanese_candidate_keys("カメラ", 1)
    with assert_raises():
        _ = japanese_candidate_keys("カメラ", 8, -1)


def test_numeric_year_and_month_search_representations() raises:
    var values = japanese_search_representations("2025年8月")
    assert_true(_contains_text(values, "2025年8月"))
    assert_true(_contains_text(values, "にせんにじゅうごねんはちがつ"))
    assert_true(_contains_text(values, "nisennijuugonenhachigatsu"))
    assert_true(_contains_text(values, "2025ねん8がつ"))
    assert_true(_contains_text(values, "2025nen8gatsu"))

    var irregular = japanese_search_representations("３００年600年8000年")
    assert_true(_contains_text(irregular, "sanbyakunenroppyakunenhassennen"))
    assert_true(len(irregular) <= 6)


def test_numeric_reading_projection_maps_to_original_date_parts() raises:
    var values = japanese_search_representations("8月")
    var found = False
    for index in range(len(values)):
        if values[index].text() == "hachigatsu":
            var value = values[index].copy()
            assert_equal(value.mapping_count(), 2)
            assert_equal(value.mapping(0).source_start(), 0)
            assert_equal(value.mapping(0).source_end(), 1)
            assert_equal(value.mapping(1).source_start(), 1)
            assert_equal(value.mapping(1).source_end(), 4)
            var month = value.source_ranges_for_output(5, 10)
            assert_equal(len(month), 1)
            assert_equal(month[0].start(), 1)
            assert_equal(month[0].end(), 4)
            found = True
    assert_true(found)


def test_standalone_month_does_not_silently_choose_gatsu() raises:
    var values = japanese_search_representations("月")
    assert_equal(len(values), 1)
    assert_equal(values[0].text(), "月")

    var ordinary = japanese_search_representations("カメラ")
    assert_equal(len(ordinary), 2)


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
