from std.testing import TestSuite, assert_equal, assert_raises

from kana_fixture_data import kana_fixtures, kana_voicing_fixtures
from yomi import romanize_kana


def test_exhaustive_checked_in_fixture_table() raises:
    var rows = kana_fixtures()
    assert_equal(len(rows), 399)
    for index in range(len(rows)):
        var row = rows[index].copy()
        var representation = romanize_kana(row.kana)
        assert_equal(representation.source_text(), row.kana)
        assert_equal(representation.text(), row.romaji)
        assert_equal(representation.mapping_count(), 1)

        var mapping = representation.mapping(0)
        assert_equal(mapping.output_start(), 0)
        assert_equal(mapping.output_end(), row.romaji.byte_length())
        assert_equal(mapping.source_start(), 0)
        assert_equal(mapping.source_end(), row.kana.byte_length())


def test_full_voicing_table_has_nfc_nfd_agreement_and_full_coverage() raises:
    var rows = kana_voicing_fixtures()
    assert_equal(len(rows), 52)
    for index in range(len(rows)):
        var row = rows[index].copy()
        var decomposed = row.base.copy()
        decomposed += row.mark

        var composed = romanize_kana(row.composed)
        var combining = romanize_kana(decomposed)
        assert_equal(composed.text(), row.romaji)
        assert_equal(combining.text(), row.romaji)
        assert_equal(composed.text(), combining.text())
        assert_equal(combining.mapping_count(), 1)

        var mapping = combining.mapping(0)
        assert_equal(mapping.output_start(), 0)
        assert_equal(mapping.output_end(), row.romaji.byte_length())
        assert_equal(mapping.source_start(), 0)
        assert_equal(mapping.source_end(), decomposed.byte_length())


def test_sokuon_context_and_exact_source_ranges() raises:
    var kitte = romanize_kana("きって")
    assert_equal(kitte.text(), "kitte")
    assert_equal(kitte.mapping_count(), 3)
    assert_equal(kitte.mapping(0).output_start(), 0)
    assert_equal(kitte.mapping(0).output_end(), 2)
    assert_equal(kitte.mapping(0).source_start(), 0)
    assert_equal(kitte.mapping(0).source_end(), 3)
    assert_equal(kitte.mapping(1).output_start(), 2)
    assert_equal(kitte.mapping(1).output_end(), 3)
    assert_equal(kitte.mapping(1).source_start(), 3)
    assert_equal(kitte.mapping(1).source_end(), 6)
    assert_equal(kitte.mapping(2).output_start(), 3)
    assert_equal(kitte.mapping(2).output_end(), 5)
    assert_equal(kitte.mapping(2).source_start(), 6)
    assert_equal(kitte.mapping(2).source_end(), 9)

    assert_equal(romanize_kana("っち").text(), "tchi")
    assert_equal(romanize_kana("ッチ").text(), "tchi")
    assert_equal(romanize_kana("まっちゃ").text(), "matcha")
    assert_equal(romanize_kana("あっ").text(), "aっ")
    assert_equal(romanize_kana("っあ").text(), "っa")
    assert_equal(romanize_kana("っうぃ").text(), "っwi")
    assert_equal(romanize_kana("っっか").text(), "kkka")

    var trailing = romanize_kana("あっ")
    assert_equal(trailing.mapping(1).output_start(), 1)
    assert_equal(trailing.mapping(1).output_end(), 4)
    assert_equal(trailing.mapping(1).source_start(), 3)
    assert_equal(trailing.mapping(1).source_end(), 6)


def test_prolonged_mark_context_and_exact_source_ranges() raises:
    var ramen = romanize_kana("ラーメン")
    assert_equal(ramen.text(), "raamen")
    assert_equal(ramen.mapping_count(), 4)
    assert_equal(ramen.mapping(1).output_start(), 2)
    assert_equal(ramen.mapping(1).output_end(), 3)
    assert_equal(ramen.mapping(1).source_start(), 3)
    assert_equal(ramen.mapping(1).source_end(), 6)

    assert_equal(romanize_kana("ーラ").text(), "ーra")
    assert_equal(romanize_kana("スーパー").text(), "suupaa")
    assert_equal(romanize_kana("カーート").text(), "kaaato")


def test_syllabic_n_context() raises:
    assert_equal(romanize_kana("ほん").text(), "hon")
    assert_equal(romanize_kana("んあ").text(), "n'a")
    assert_equal(romanize_kana("んぁ").text(), "n'a")
    assert_equal(romanize_kana("んや").text(), "n'ya")
    assert_equal(romanize_kana("かんぱい").text(), "kanpai")


def test_yoon_contracts_to_one_mapping_and_projects_partial_match() raises:
    var representation = romanize_kana("きゃ")
    assert_equal(representation.text(), "kya")
    assert_equal(representation.mapping_count(), 1)

    var mapping = representation.mapping(0)
    assert_equal(mapping.output_start(), 0)
    assert_equal(mapping.output_end(), 3)
    assert_equal(mapping.source_start(), 0)
    assert_equal(mapping.source_end(), 6)

    var ranges = representation.source_ranges_for_output(1, 2)
    assert_equal(len(ranges), 1)
    assert_equal(ranges[0].start(), 0)
    assert_equal(ranges[0].end(), 6)


def test_mixed_ramen_shop_ranges_and_projection_are_byte_exact() raises:
    var representation = romanize_kana("ラーメン屋")
    assert_equal(representation.text(), "raamen屋")
    assert_equal(representation.mapping_count(), 5)

    var mappings = representation.mapping_snapshot()
    assert_equal(mappings[0].output_start(), 0)
    assert_equal(mappings[0].output_end(), 2)
    assert_equal(mappings[0].source_start(), 0)
    assert_equal(mappings[0].source_end(), 3)
    assert_equal(mappings[1].output_start(), 2)
    assert_equal(mappings[1].output_end(), 3)
    assert_equal(mappings[1].source_start(), 3)
    assert_equal(mappings[1].source_end(), 6)
    assert_equal(mappings[2].output_start(), 3)
    assert_equal(mappings[2].output_end(), 5)
    assert_equal(mappings[2].source_start(), 6)
    assert_equal(mappings[2].source_end(), 9)
    assert_equal(mappings[3].output_start(), 5)
    assert_equal(mappings[3].output_end(), 6)
    assert_equal(mappings[3].source_start(), 9)
    assert_equal(mappings[3].source_end(), 12)
    assert_equal(mappings[4].output_start(), 6)
    assert_equal(mappings[4].output_end(), 9)
    assert_equal(mappings[4].source_start(), 12)
    assert_equal(mappings[4].source_end(), 15)

    var ranges = representation.source_ranges_for_output(0, 6)
    assert_equal(len(ranges), 1)
    assert_equal(ranges[0].start(), 0)
    assert_equal(ranges[0].end(), 12)


def test_kana_emoji_ascii_and_unmapped_graphemes_pass_through_exactly() raises:
    var mixed = romanize_kana("カ🙂Ae\u0301")
    assert_equal(mixed.text(), "ka🙂Ae\u0301")
    assert_equal(mixed.mapping_count(), 4)
    assert_equal(mixed.mapping(0).output_start(), 0)
    assert_equal(mixed.mapping(0).output_end(), 2)
    assert_equal(mixed.mapping(0).source_start(), 0)
    assert_equal(mixed.mapping(0).source_end(), 3)
    assert_equal(mixed.mapping(1).output_start(), 2)
    assert_equal(mixed.mapping(1).output_end(), 6)
    assert_equal(mixed.mapping(1).source_start(), 3)
    assert_equal(mixed.mapping(1).source_end(), 7)
    assert_equal(mixed.mapping(2).output_start(), 6)
    assert_equal(mixed.mapping(2).output_end(), 7)
    assert_equal(mixed.mapping(2).source_start(), 7)
    assert_equal(mixed.mapping(2).source_end(), 8)
    assert_equal(mixed.mapping(3).output_start(), 7)
    assert_equal(mixed.mapping(3).output_end(), 10)
    assert_equal(mixed.mapping(3).source_start(), 8)
    assert_equal(mixed.mapping(3).source_end(), 11)

    var unmapped = "ゝゞヽヾ゛゜ヷヸヹヺｶ。、"
    var passthrough = romanize_kana(unmapped)
    assert_equal(passthrough.text(), unmapped)
    assert_equal(passthrough.mapping_count(), 13)

    var excluded_hiragana = String("わ\u3099")
    var excluded = romanize_kana(excluded_hiragana)
    assert_equal(excluded.text(), excluded_hiragana)
    assert_equal(excluded.mapping_count(), 1)
    assert_equal(excluded.mapping(0).source_start(), 0)
    assert_equal(excluded.mapping(0).source_end(), 6)

    var excluded_katakana = String("ワ\u3099")
    assert_equal(romanize_kana(excluded_katakana).text(), excluded_katakana)

    var orphan_mark = String("\u3099")
    var orphan = romanize_kana(orphan_mark)
    assert_equal(orphan.text(), orphan_mark)
    assert_equal(orphan.mapping_count(), 1)
    assert_equal(orphan.mapping(0).source_start(), 0)
    assert_equal(orphan.mapping(0).source_end(), 3)


def test_unlisted_small_kana_pair_is_greedy_only_within_closed_table() raises:
    assert_equal(romanize_kana("きぁ").text(), "kia")
    assert_equal(romanize_kana("くゃ").text(), "kuya")


def test_empty_input_has_empty_representation() raises:
    var representation = romanize_kana("")
    assert_equal(representation.source_text(), "")
    assert_equal(representation.text(), "")
    assert_equal(representation.mapping_count(), 0)


def test_romanization_validate_rejects_reachable_mutation() raises:
    var representation = romanize_kana("かな")
    representation._mappings[0]._source_end = 2
    with assert_raises():
        representation.validate()


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
