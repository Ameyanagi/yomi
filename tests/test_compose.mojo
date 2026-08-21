from std.testing import TestSuite, assert_equal, assert_raises

from yomi import compose_hangul, decompose_hangul


comptime S_BASE = 0xAC00
comptime S_COUNT = 11172


def test_all_modern_syllables_round_trip_with_contraction_mappings() raises:
    var lv_count = 0
    var lvt_count = 0

    assert_equal(S_COUNT, 11172)
    for syllable_index in range(S_COUNT):
        var syllable = chr(S_BASE + syllable_index)
        var decomposed = decompose_hangul(syllable).text()
        var representation = compose_hangul(decomposed)
        var composed = representation.text()

        assert_equal(composed, syllable)
        assert_equal(representation.mapping_count(), 1)
        var mapping = representation.mapping(0)
        assert_equal(mapping.output_start(), 0)
        assert_equal(mapping.output_end(), 3)
        assert_equal(mapping.source_start(), 0)
        assert_equal(mapping.source_end(), decomposed.byte_length())

        if decomposed.byte_length() == 6:
            lv_count += 1
        else:
            assert_equal(decomposed.byte_length(), 9)
            lvt_count += 1

        var canonical = decompose_hangul(composed).text()
        assert_equal(canonical, decomposed)

    assert_equal(lv_count, 399)
    assert_equal(lvt_count, 10773)


def test_precomposed_lv_plus_trailing_jamo_composes() raises:
    var source = String("가")
    source += chr(0x11A8)
    var representation = compose_hangul(source)
    assert_equal(representation.text(), "각")
    assert_equal(representation.mapping_count(), 1)

    var mapping = representation.mapping(0)
    assert_equal(mapping.output_start(), 0)
    assert_equal(mapping.output_end(), 3)
    assert_equal(mapping.source_start(), 0)
    assert_equal(mapping.source_end(), 6)


def test_isolated_and_incomplete_jamo_pass_through_per_scalar() raises:
    var leading = compose_hangul("ᄀ")
    assert_equal(leading.text(), "ᄀ")
    assert_equal(leading.mapping_count(), 1)
    assert_equal(leading.mapping(0).output_start(), 0)
    assert_equal(leading.mapping(0).output_end(), 3)
    assert_equal(leading.mapping(0).source_start(), 0)
    assert_equal(leading.mapping(0).source_end(), 3)

    var vowel = compose_hangul("ᅡ")
    assert_equal(vowel.text(), "ᅡ")
    assert_equal(vowel.mapping_count(), 1)
    assert_equal(vowel.mapping(0).output_start(), 0)
    assert_equal(vowel.mapping(0).output_end(), 3)
    assert_equal(vowel.mapping(0).source_start(), 0)
    assert_equal(vowel.mapping(0).source_end(), 3)

    var trailing = compose_hangul("ᆨ")
    assert_equal(trailing.text(), "ᆨ")
    assert_equal(trailing.mapping_count(), 1)
    assert_equal(trailing.mapping(0).output_start(), 0)
    assert_equal(trailing.mapping(0).output_end(), 3)
    assert_equal(trailing.mapping(0).source_start(), 0)
    assert_equal(trailing.mapping(0).source_end(), 3)

    var interrupted = compose_hangul("ᄀa")
    assert_equal(interrupted.text(), "ᄀa")
    assert_equal(interrupted.mapping_count(), 2)
    assert_equal(interrupted.mapping(0).output_start(), 0)
    assert_equal(interrupted.mapping(0).output_end(), 3)
    assert_equal(interrupted.mapping(0).source_start(), 0)
    assert_equal(interrupted.mapping(0).source_end(), 3)
    assert_equal(interrupted.mapping(1).output_start(), 3)
    assert_equal(interrupted.mapping(1).output_end(), 4)
    assert_equal(interrupted.mapping(1).source_start(), 3)
    assert_equal(interrupted.mapping(1).source_end(), 4)


def test_greedy_composition_restarts_after_an_incomplete_leading_jamo() raises:
    var representation = compose_hangul("ᄀ나")
    assert_equal(representation.text(), "ᄀ나")
    assert_equal(representation.mapping_count(), 2)

    var first = representation.mapping(0)
    assert_equal(first.output_start(), 0)
    assert_equal(first.output_end(), 3)
    assert_equal(first.source_start(), 0)
    assert_equal(first.source_end(), 3)

    var second = representation.mapping(1)
    assert_equal(second.output_start(), 3)
    assert_equal(second.output_end(), 6)
    assert_equal(second.source_start(), 3)
    assert_equal(second.source_end(), 9)


def test_mixed_text_and_pass_through_ranges_are_exact() raises:
    var mixed = compose_hangul("a각b")
    assert_equal(mixed.text(), "a각b")
    assert_equal(mixed.mapping_count(), 3)

    var mappings = mixed.mapping_snapshot()
    assert_equal(mappings[0].output_start(), 0)
    assert_equal(mappings[0].output_end(), 1)
    assert_equal(mappings[0].source_start(), 0)
    assert_equal(mappings[0].source_end(), 1)
    assert_equal(mappings[1].output_start(), 1)
    assert_equal(mappings[1].output_end(), 4)
    assert_equal(mappings[1].source_start(), 1)
    assert_equal(mappings[1].source_end(), 10)
    assert_equal(mappings[2].output_start(), 4)
    assert_equal(mappings[2].output_end(), 5)
    assert_equal(mappings[2].source_start(), 10)
    assert_equal(mappings[2].source_end(), 11)

    var passthrough = compose_hangul("🙂e\u0301")
    assert_equal(passthrough.text(), "🙂e\u0301")
    assert_equal(passthrough.mapping_count(), 2)
    assert_equal(passthrough.mapping(0).output_start(), 0)
    assert_equal(passthrough.mapping(0).output_end(), 4)
    assert_equal(passthrough.mapping(0).source_start(), 0)
    assert_equal(passthrough.mapping(0).source_end(), 4)
    assert_equal(passthrough.mapping(1).output_start(), 4)
    assert_equal(passthrough.mapping(1).output_end(), 7)
    assert_equal(passthrough.mapping(1).source_start(), 4)
    assert_equal(passthrough.mapping(1).source_end(), 7)


def test_candidate_extenders_keep_per_scalar_ranges() raises:
    var representation = compose_hangul("각\u0301")
    assert_equal(representation.text(), "각\u0301")
    assert_equal(representation.mapping_count(), 2)

    var syllable = representation.mapping(0)
    assert_equal(syllable.output_start(), 0)
    assert_equal(syllable.output_end(), 3)
    assert_equal(syllable.source_start(), 0)
    assert_equal(syllable.source_end(), 9)

    var extender = representation.mapping(1)
    assert_equal(extender.output_start(), 3)
    assert_equal(extender.output_end(), 5)
    assert_equal(extender.source_start(), 9)
    assert_equal(extender.source_end(), 11)


def test_empty_input_has_empty_composition() raises:
    var representation = compose_hangul("")
    assert_equal(representation.source_text(), "")
    assert_equal(representation.text(), "")
    assert_equal(representation.mapping_count(), 0)


def test_composed_output_projects_to_full_jamo_source_range() raises:
    var representation = compose_hangul("각")
    var ranges = representation.source_ranges_for_output(0, 3)
    assert_equal(len(ranges), 1)
    assert_equal(ranges[0].start(), 0)
    assert_equal(ranges[0].end(), 9)


def test_composition_validate_rejects_reachable_mutation() raises:
    var representation = compose_hangul("각")
    representation._mappings[0]._source_end = 8
    with assert_raises():
        representation.validate()


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
