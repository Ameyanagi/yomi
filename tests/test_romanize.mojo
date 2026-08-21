from std.testing import TestSuite, assert_equal, assert_raises

from kana_fixture_data import kana_fixtures, kana_voicing_fixtures
from yomi import to_romaji


def test_exhaustive_checked_in_fixture_table() raises:
    var rows = kana_fixtures()
    assert_equal(len(rows), 399)
    for index in range(len(rows)):
        var row = rows[index].copy()
        var representation = to_romaji(row.kana)
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

        var composed = to_romaji(row.composed)
        var combining = to_romaji(decomposed)
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
    var kitte = to_romaji("きって")
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

    assert_equal(to_romaji("っち").text(), "tchi")
    assert_equal(to_romaji("ッチ").text(), "tchi")
    assert_equal(to_romaji("まっちゃ").text(), "matcha")
    assert_equal(to_romaji("あっ").text(), "aっ")
    assert_equal(to_romaji("っあ").text(), "っa")
    assert_equal(to_romaji("っうぃ").text(), "っwi")
    assert_equal(to_romaji("っっか").text(), "kkka")

    var trailing = to_romaji("あっ")
    assert_equal(trailing.mapping(1).output_start(), 1)
    assert_equal(trailing.mapping(1).output_end(), 4)
    assert_equal(trailing.mapping(1).source_start(), 3)
    assert_equal(trailing.mapping(1).source_end(), 6)


def test_prolonged_mark_context_and_exact_source_ranges() raises:
    var ramen = to_romaji("ラーメン")
    assert_equal(ramen.text(), "raamen")
    assert_equal(ramen.mapping_count(), 4)
    assert_equal(ramen.mapping(1).output_start(), 2)
    assert_equal(ramen.mapping(1).output_end(), 3)
    assert_equal(ramen.mapping(1).source_start(), 3)
    assert_equal(ramen.mapping(1).source_end(), 6)

    assert_equal(to_romaji("ーラ").text(), "ーra")
    assert_equal(to_romaji("スーパー").text(), "suupaa")
    assert_equal(to_romaji("カーート").text(), "kaaato")


def test_syllabic_n_context() raises:
    assert_equal(to_romaji("ほん").text(), "hon")
    assert_equal(to_romaji("んあ").text(), "n'a")
    assert_equal(to_romaji("んぁ").text(), "n'a")
    assert_equal(to_romaji("んや").text(), "n'ya")
    assert_equal(to_romaji("かんぱい").text(), "kanpai")


def test_yoon_contracts_to_one_mapping_and_projects_partial_match() raises:
    var representation = to_romaji("きゃ")
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
    var representation = to_romaji("ラーメン屋")
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
    var mixed = to_romaji("カ🙂Ae\u0301")
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
    var passthrough = to_romaji(unmapped)
    assert_equal(passthrough.text(), unmapped)
    assert_equal(passthrough.mapping_count(), 13)

    var excluded_hiragana = String("わ\u3099")
    var excluded = to_romaji(excluded_hiragana)
    assert_equal(excluded.text(), excluded_hiragana)
    assert_equal(excluded.mapping_count(), 1)
    assert_equal(excluded.mapping(0).source_start(), 0)
    assert_equal(excluded.mapping(0).source_end(), 6)

    var excluded_katakana = String("ワ\u3099")
    assert_equal(to_romaji(excluded_katakana).text(), excluded_katakana)

    var orphan_mark = String("\u3099")
    var orphan = to_romaji(orphan_mark)
    assert_equal(orphan.text(), orphan_mark)
    assert_equal(orphan.mapping_count(), 1)
    assert_equal(orphan.mapping(0).source_start(), 0)
    assert_equal(orphan.mapping(0).source_end(), 3)


def test_unlisted_small_kana_pair_is_greedy_only_within_closed_table() raises:
    assert_equal(to_romaji("きぁ").text(), "kia")
    assert_equal(to_romaji("くゃ").text(), "kuya")


def test_empty_input_has_empty_representation() raises:
    var representation = to_romaji("")
    assert_equal(representation.source_text(), "")
    assert_equal(representation.text(), "")
    assert_equal(representation.mapping_count(), 0)


def test_romanization_validate_rejects_reachable_mutation() raises:
    var representation = to_romaji("かな")
    representation._mappings[0]._source_end = 2
    with assert_raises():
        representation.validate()


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
