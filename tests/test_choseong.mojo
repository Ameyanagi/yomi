from std.collections import List
from std.testing import (
    TestSuite,
    assert_equal,
    assert_raises,
)
from yomi import PhoneticRepresentation, SourceMapping, SourceRange, hangul_choseong


def _read_validated_values_without_raises(
    representation: PhoneticRepresentation,
    mapping: SourceMapping,
    source_range: SourceRange,
) -> Int:
    var mappings = representation.mapping_snapshot()
    return (
        representation.source_text().byte_length()
        + representation.text().byte_length()
        + representation.mapping_count()
        + len(mappings)
        + mapping.output_start()
        + mapping.output_end()
        + mapping.source_start()
        + mapping.source_end()
        + source_range.start()
        + source_range.end()
    )


def test_validated_value_reads_are_non_raising() raises:
    var representation = hangul_choseong("한")
    var mapping = SourceMapping(0, 1, 0, 1)
    var source_range = SourceRange(0, 1)
    assert_equal(
        _read_validated_values_without_raises(representation, mapping, source_range),
        11,
    )


def test_empty_input_has_no_mappings() raises:
    var representation = hangul_choseong("")
    assert_equal(representation.source_text(), "")
    assert_equal(representation.text(), "")
    assert_equal(representation.mapping_count(), 0)


def test_precomposed_hangul_uses_compatibility_choseong() raises:
    var representation = hangul_choseong("한국어")
    assert_equal(representation.source_text(), "한국어")
    assert_equal(representation.text(), "ㅎㄱㅇ")
    assert_equal(representation.mapping_count(), 3)

    var first = representation.mapping(0)
    assert_equal(first.output_start(), 0)
    assert_equal(first.output_end(), 3)
    assert_equal(first.source_start(), 0)
    assert_equal(first.source_end(), 3)

    var second = representation.mapping(1)
    assert_equal(second.output_start(), 3)
    assert_equal(second.output_end(), 6)
    assert_equal(second.source_start(), 3)
    assert_equal(second.source_end(), 6)


def test_all_nineteen_initials_are_covered() raises:
    var representation = hangul_choseong("가까나다따라마바빠사싸아자짜차카타파하")
    assert_equal(representation.text(), "ㄱㄲㄴㄷㄸㄹㅁㅂㅃㅅㅆㅇㅈㅉㅊㅋㅌㅍㅎ")
    assert_equal(representation.mapping_count(), 19)


def test_mixed_text_preserves_non_hangul_graphemes() raises:
    var representation = hangul_choseong("A한界🙂e\u0301")
    assert_equal(representation.text(), "Aㅎ界🙂e\u0301")
    assert_equal(representation.mapping_count(), 5)

    var hangul = representation.mapping(1)
    assert_equal(hangul.output_start(), 1)
    assert_equal(hangul.output_end(), 4)
    assert_equal(hangul.source_start(), 1)
    assert_equal(hangul.source_end(), 4)

    var emoji = representation.mapping(3)
    assert_equal(emoji.output_start(), 7)
    assert_equal(emoji.output_end(), 11)
    assert_equal(emoji.source_start(), 7)
    assert_equal(emoji.source_end(), 11)

    var combining = representation.mapping(4)
    assert_equal(combining.output_start(), 11)
    assert_equal(combining.output_end(), 14)
    assert_equal(combining.source_start(), 11)
    assert_equal(combining.source_end(), 14)


def test_canonical_decomposed_hangul_uses_compatible_choseong() raises:
    var representation = hangul_choseong("한")
    assert_equal(representation.text(), "ㅎ")
    assert_equal(representation.mapping_count(), 1)
    var mapping = representation.mapping(0)
    assert_equal(mapping.output_start(), 0)
    assert_equal(mapping.output_end(), 3)
    assert_equal(mapping.source_start(), 0)
    assert_equal(mapping.source_end(), 9)


def test_nfc_and_nfd_hangul_have_the_same_choseong_view() raises:
    var composed = hangul_choseong("한")
    var decomposed = hangul_choseong("한")
    assert_equal(composed.text(), decomposed.text())


def test_precomposed_hangul_consumes_combining_extenders() raises:
    var representation = hangul_choseong("한\u0301")
    assert_equal(representation.source_text(), "한\u0301")
    assert_equal(representation.text(), "ㅎ")
    assert_equal(representation.mapping_count(), 1)
    var mapping = representation.mapping(0)
    assert_equal(mapping.output_start(), 0)
    assert_equal(mapping.output_end(), 3)
    assert_equal(mapping.source_start(), 0)
    assert_equal(mapping.source_end(), 5)


def test_mapping_rejects_out_of_range_indices() raises:
    var representation = hangul_choseong("한")
    with assert_raises():
        _ = representation.mapping(-1)
    with assert_raises():
        _ = representation.mapping(1)


def test_source_mapping_rejects_empty_or_negative_ranges() raises:
    with assert_raises():
        _ = SourceMapping(-1, 1, 0, 1)
    with assert_raises():
        _ = SourceMapping(0, 0, 0, 1)
    with assert_raises():
        _ = SourceMapping(0, 1, -1, 1)
    with assert_raises():
        _ = SourceMapping(0, 1, 0, 0)


def test_representation_rejects_uncovered_output() raises:
    var mappings = List[SourceMapping]()
    mappings.append(SourceMapping(0, 1, 0, 1))
    with assert_raises():
        _ = PhoneticRepresentation("a", "ab", mappings^)


def test_representation_rejects_gaps_and_overlaps() raises:
    var gapped = List[SourceMapping]()
    gapped.append(SourceMapping(0, 1, 0, 1))
    gapped.append(SourceMapping(2, 3, 1, 2))
    with assert_raises():
        _ = PhoneticRepresentation("ab", "abc", gapped^)

    var overlapping = List[SourceMapping]()
    overlapping.append(SourceMapping(0, 2, 0, 1))
    overlapping.append(SourceMapping(1, 3, 1, 2))
    with assert_raises():
        _ = PhoneticRepresentation("ab", "abc", overlapping^)


def test_representation_rejects_utf8_interior_boundaries() raises:
    var mappings = List[SourceMapping]()
    mappings.append(SourceMapping(0, 1, 0, 3))
    mappings.append(SourceMapping(1, 3, 0, 3))
    with assert_raises():
        _ = PhoneticRepresentation("한", "한", mappings^)


def test_representation_rejects_invalid_source_ranges() raises:
    var interior = List[SourceMapping]()
    interior.append(SourceMapping(0, 1, 0, 2))
    with assert_raises():
        _ = PhoneticRepresentation("한", "x", interior^)

    var out_of_bounds = List[SourceMapping]()
    out_of_bounds.append(SourceMapping(0, 1, 0, 2))
    with assert_raises():
        _ = PhoneticRepresentation("a", "x", out_of_bounds^)


def test_representation_validate_rejects_mutated_mapping_storage() raises:
    var representation = hangul_choseong("한")
    representation._mappings[0]._source_end = 2
    with assert_raises():
        representation.validate()


def test_representation_validate_rejects_mutated_text_storage() raises:
    var source_mutated = hangul_choseong("한")
    source_mutated._source = "a"
    with assert_raises():
        source_mutated.validate()

    var output_mutated = hangul_choseong("한")
    output_mutated._text = "x"
    with assert_raises():
        output_mutated.validate()


def test_mapping_validate_rejects_mutated_storage() raises:
    var mapping = SourceMapping(0, 1, 0, 1)
    mapping._source_start = -1
    with assert_raises():
        mapping.validate()


def test_mapping_snapshot_supports_linear_enumeration() raises:
    var representation = hangul_choseong("한국")
    var snapshot = representation.mapping_snapshot()
    assert_equal(len(snapshot), 2)
    assert_equal(snapshot[0].output_start(), 0)
    assert_equal(snapshot[0].source_end(), 3)
    assert_equal(snapshot[1].output_start(), 3)
    assert_equal(snapshot[1].source_end(), 6)

    snapshot[0]._source_start = -1
    with assert_raises():
        snapshot[0].validate()
    assert_equal(representation.mapping(0).source_end(), 3)

    representation._mappings[0]._source_end = 2
    with assert_raises():
        representation.validate()


def test_source_range_rejects_invalid_construction_and_validation() raises:
    with assert_raises():
        _ = SourceRange(-1, 1)
    with assert_raises():
        _ = SourceRange(1, 1)

    var source_range = SourceRange(0, 1)
    source_range._end = 0
    with assert_raises():
        source_range.validate()


def test_output_projection_merges_only_touching_or_overlapping_source() raises:
    var discontiguous_mappings = List[SourceMapping]()
    discontiguous_mappings.append(SourceMapping(0, 1, 0, 1))
    discontiguous_mappings.append(SourceMapping(1, 2, 2, 3))
    var discontiguous = PhoneticRepresentation("A-B", "xy", discontiguous_mappings^)
    var exact = discontiguous.source_ranges_for_output(0, 2)
    assert_equal(len(exact), 2)
    assert_equal(exact[0].start(), 0)
    assert_equal(exact[0].end(), 1)
    assert_equal(exact[1].start(), 2)
    assert_equal(exact[1].end(), 3)

    var overlapping_mappings = List[SourceMapping]()
    overlapping_mappings.append(SourceMapping(0, 1, 0, 2))
    overlapping_mappings.append(SourceMapping(1, 2, 1, 3))
    var overlapping = PhoneticRepresentation("ABC", "xy", overlapping_mappings^)
    var merged = overlapping.source_ranges_for_output(0, 2)
    assert_equal(len(merged), 1)
    assert_equal(merged[0].start(), 0)
    assert_equal(merged[0].end(), 3)


def test_output_projection_sorts_reordered_source_ranges() raises:
    var mappings = List[SourceMapping]()
    mappings.append(SourceMapping(0, 1, 2, 3))
    mappings.append(SourceMapping(1, 2, 0, 1))
    var representation = PhoneticRepresentation("A-B", "xy", mappings^)
    var exact = representation.source_ranges_for_output(0, 2)
    assert_equal(len(exact), 2)
    assert_equal(exact[0].start(), 0)
    assert_equal(exact[1].start(), 2)


def test_output_projection_rejects_invalid_match_ranges() raises:
    var representation = hangul_choseong("한")
    with assert_raises():
        _ = representation.source_ranges_for_output(-1, 3)
    with assert_raises():
        _ = representation.source_ranges_for_output(0, 0)
    with assert_raises():
        _ = representation.source_ranges_for_output(0, 4)
    with assert_raises():
        _ = representation.source_ranges_for_output(1, 2)


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
