from std.testing import TestSuite, assert_equal, assert_raises

from kana_fixture_data import kana_voicing_fixtures
from yomi import PhoneticRepresentation, to_hiragana, to_katakana


def _assert_single_mapping(
    representation: PhoneticRepresentation,
    expected_source: StringSlice,
    expected_text: StringSlice,
) raises:
    var source = String(expected_source)
    var text = String(expected_text)
    assert_equal(representation.source_text(), source)
    assert_equal(representation.text(), text)
    assert_equal(representation.mapping_count(), 1)

    var mapping = representation.mapping(0)
    assert_equal(mapping.output_start(), 0)
    assert_equal(mapping.output_end(), text.byte_length())
    assert_equal(mapping.source_start(), 0)
    assert_equal(mapping.source_end(), source.byte_length())


def test_full_katakana_range_converts_and_round_trips() raises:
    for value in range(0x30A1, 0x30F7):
        var katakana = chr(value)
        var expected_hiragana = chr(value - 0x60)
        var hiragana = to_hiragana(katakana)
        _assert_single_mapping(hiragana, katakana, expected_hiragana)

        var hiragana_text = hiragana.text()
        var round_trip = to_katakana(hiragana_text)
        assert_equal(round_trip.text(), katakana)

    for value in [0x30FD, 0x30FE]:
        var katakana = chr(value)
        var expected_hiragana = chr(value - 0x60)
        var hiragana = to_hiragana(katakana)
        _assert_single_mapping(hiragana, katakana, expected_hiragana)

        var hiragana_text = hiragana.text()
        var round_trip = to_katakana(hiragana_text)
        assert_equal(round_trip.text(), katakana)


def test_full_hiragana_range_converts_and_round_trips() raises:
    for value in range(0x3041, 0x3097):
        var hiragana = chr(value)
        var expected_katakana = chr(value + 0x60)
        var katakana = to_katakana(hiragana)
        _assert_single_mapping(katakana, hiragana, expected_katakana)

        var katakana_text = katakana.text()
        var round_trip = to_hiragana(katakana_text)
        assert_equal(round_trip.text(), hiragana)

    for value in [0x309D, 0x309E]:
        var hiragana = chr(value)
        var expected_katakana = chr(value + 0x60)
        var katakana = to_katakana(hiragana)
        _assert_single_mapping(katakana, hiragana, expected_katakana)

        var katakana_text = katakana.text()
        var round_trip = to_hiragana(katakana_text)
        assert_equal(round_trip.text(), hiragana)


def test_full_voicing_table_has_nfc_nfd_agreement() raises:
    var rows = kana_voicing_fixtures()
    assert_equal(len(rows), 52)
    for index in range(len(rows)):
        var row = rows[index].copy()
        var decomposed = row.base.copy()
        decomposed += row.mark

        var hiragana_nfd = to_hiragana(decomposed)
        var hiragana_nfc = to_hiragana(row.composed)
        var expected_hiragana = hiragana_nfc.text()
        _assert_single_mapping(hiragana_nfd, decomposed, expected_hiragana)

        var katakana_nfd = to_katakana(decomposed)
        var katakana_nfc = to_katakana(row.composed)
        var expected_katakana = katakana_nfc.text()
        _assert_single_mapping(katakana_nfd, decomposed, expected_katakana)


def test_voicing_contractions_cover_both_source_scalars() raises:
    var katakana_nfd = String("カ\u3099")
    _assert_single_mapping(to_hiragana(katakana_nfd), katakana_nfd, "が")

    var hiragana_nfd = String("か\u3099")
    _assert_single_mapping(to_hiragana(hiragana_nfd), hiragana_nfd, "が")
    _assert_single_mapping(to_katakana(hiragana_nfd), hiragana_nfd, "ガ")


def test_excluded_wa_voicing_pairs_pass_through_as_graphemes() raises:
    var katakana = String("ワ\u3099")
    _assert_single_mapping(to_hiragana(katakana), katakana, katakana.copy())
    _assert_single_mapping(to_katakana(katakana), katakana, katakana.copy())

    var hiragana = String("わ\u3099")
    _assert_single_mapping(to_hiragana(hiragana), hiragana, hiragana.copy())
    _assert_single_mapping(to_katakana(hiragana), hiragana, hiragana.copy())


def test_shared_mark_and_unpaired_katakana_pass_through() raises:
    _assert_single_mapping(to_hiragana("ー"), "ー", "ー")
    _assert_single_mapping(to_katakana("ー"), "ー", "ー")

    var source = String("ヷヸヹヺ")
    var representation = to_hiragana(source)
    assert_equal(representation.source_text(), source)
    assert_equal(representation.text(), source)
    assert_equal(representation.mapping_count(), 4)
    for index in range(4):
        var mapping = representation.mapping(index)
        assert_equal(mapping.output_start(), index * 3)
        assert_equal(mapping.output_end(), (index + 1) * 3)
        assert_equal(mapping.source_start(), index * 3)
        assert_equal(mapping.source_end(), (index + 1) * 3)


def test_mixed_ramen_shop_mappings_and_projection_are_byte_exact() raises:
    var representation = to_hiragana("ラーメン屋")
    assert_equal(representation.text(), "らーめん屋")
    assert_equal(representation.mapping_count(), 5)
    for index in range(5):
        var mapping = representation.mapping(index)
        assert_equal(mapping.output_start(), index * 3)
        assert_equal(mapping.output_end(), (index + 1) * 3)
        assert_equal(mapping.source_start(), index * 3)
        assert_equal(mapping.source_end(), (index + 1) * 3)

    var ranges = representation.source_ranges_for_output(0, 12)
    assert_equal(len(ranges), 1)
    assert_equal(ranges[0].start(), 0)
    assert_equal(ranges[0].end(), 12)


def test_non_kana_graphemes_pass_through_exactly() raises:
    var source = String("A🙂ｶe\u0301。")
    var hiragana = to_hiragana(source)
    assert_equal(hiragana.text(), source)
    assert_equal(hiragana.mapping_count(), 5)

    var first = hiragana.mapping(0)
    assert_equal(first.output_start(), 0)
    assert_equal(first.output_end(), 1)
    assert_equal(first.source_start(), 0)
    assert_equal(first.source_end(), 1)

    var second = hiragana.mapping(1)
    assert_equal(second.output_start(), 1)
    assert_equal(second.output_end(), 5)
    assert_equal(second.source_start(), 1)
    assert_equal(second.source_end(), 5)

    var third = hiragana.mapping(2)
    assert_equal(third.output_start(), 5)
    assert_equal(third.output_end(), 8)
    assert_equal(third.source_start(), 5)
    assert_equal(third.source_end(), 8)

    var fourth = hiragana.mapping(3)
    assert_equal(fourth.output_start(), 8)
    assert_equal(fourth.output_end(), 11)
    assert_equal(fourth.source_start(), 8)
    assert_equal(fourth.source_end(), 11)

    var fifth = hiragana.mapping(4)
    assert_equal(fifth.output_start(), 11)
    assert_equal(fifth.output_end(), 14)
    assert_equal(fifth.source_start(), 11)
    assert_equal(fifth.source_end(), 14)

    var katakana = to_katakana(source)
    assert_equal(katakana.text(), source)
    assert_equal(katakana.mapping_count(), 5)


def test_empty_input_has_empty_representations() raises:
    var hiragana = to_hiragana("")
    assert_equal(hiragana.source_text(), "")
    assert_equal(hiragana.text(), "")
    assert_equal(hiragana.mapping_count(), 0)

    var katakana = to_katakana("")
    assert_equal(katakana.source_text(), "")
    assert_equal(katakana.text(), "")
    assert_equal(katakana.mapping_count(), 0)


def test_conversion_validate_rejects_reachable_mutation() raises:
    var representation = to_hiragana("カ")
    representation._mappings[0]._source_end = 2
    with assert_raises():
        representation.validate()


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
