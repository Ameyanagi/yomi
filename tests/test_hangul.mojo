from std.testing import TestSuite, assert_equal, assert_raises, assert_true

from yomi import decompose_hangul


comptime S_BASE = 0xAC00
comptime L_BASE = 0x1100
comptime V_BASE = 0x1161
comptime T_BASE = 0x11A7
comptime L_COUNT = 19
comptime V_COUNT = 21
comptime T_COUNT = 28
comptime N_COUNT = V_COUNT * T_COUNT
comptime S_COUNT = L_COUNT * N_COUNT


def test_reference_lv_and_lvt_syllables() raises:
    var lv = decompose_hangul("가")
    assert_equal(lv.text(), "가")
    assert_equal(lv.mapping_count(), 2)

    var lvt = decompose_hangul("각")
    assert_equal(lvt.text(), "각")
    assert_equal(lvt.mapping_count(), 3)

    var final = decompose_hangul("힣")
    assert_equal(final.text(), "힣")


def test_decomposition_preserves_mixed_graphemes_and_exact_mappings() raises:
    var representation = decompose_hangul("A각界🙂e\u0301")
    assert_equal(representation.text(), "A각界🙂e\u0301")
    var mappings = representation.mapping_snapshot()
    assert_equal(len(mappings), 7)

    assert_equal(mappings[0].output_start(), 0)
    assert_equal(mappings[0].output_end(), 1)
    assert_equal(mappings[0].source_start(), 0)
    assert_equal(mappings[0].source_end(), 1)

    for index in range(1, 4):
        assert_equal(mappings[index].source_start(), 1)
        assert_equal(mappings[index].source_end(), 4)

    assert_equal(mappings[4].source_start(), 4)
    assert_equal(mappings[4].source_end(), 7)
    assert_equal(mappings[5].source_start(), 7)
    assert_equal(mappings[5].source_end(), 11)
    assert_equal(mappings[6].source_start(), 11)
    assert_equal(mappings[6].source_end(), 14)


def test_extenders_keep_their_own_source_ranges() raises:
    var representation = decompose_hangul("각\u0301")
    assert_equal(representation.text(), "각\u0301")
    var mappings = representation.mapping_snapshot()
    assert_equal(len(mappings), 4)
    for index in range(3):
        assert_equal(mappings[index].source_start(), 0)
        assert_equal(mappings[index].source_end(), 3)
    assert_equal(mappings[3].output_start(), 9)
    assert_equal(mappings[3].output_end(), 11)
    assert_equal(mappings[3].source_start(), 3)
    assert_equal(mappings[3].source_end(), 5)

    var syllable = representation.source_ranges_for_output(0, 9)
    assert_equal(len(syllable), 1)
    assert_equal(syllable[0].start(), 0)
    assert_equal(syllable[0].end(), 3)
    var extender = representation.source_ranges_for_output(9, 11)
    assert_equal(len(extender), 1)
    assert_equal(extender[0].start(), 3)
    assert_equal(extender[0].end(), 5)


def test_nfc_and_nfd_decompose_to_identical_text() raises:
    var composed = decompose_hangul("각")
    var decomposed = decompose_hangul("각")
    assert_equal(composed.text(), decomposed.text())
    var mappings = decomposed.mapping_snapshot()
    assert_equal(len(mappings), 3)
    for index in range(len(mappings)):
        assert_equal(mappings[index].output_start(), index * 3)
        assert_equal(mappings[index].output_end(), index * 3 + 3)
        assert_equal(mappings[index].source_start(), index * 3)
        assert_equal(mappings[index].source_end(), index * 3 + 3)


def test_isolated_jamo_and_syllable_boundaries_pass_through() raises:
    var leading = decompose_hangul("ᄀ")
    assert_equal(leading.text(), "ᄀ")
    assert_equal(leading.mapping_count(), 1)

    var compatibility = decompose_hangul("ㄱ")
    assert_equal(compatibility.text(), "ㄱ")
    assert_equal(compatibility.mapping_count(), 1)

    var before = chr(S_BASE - 1)
    assert_equal(decompose_hangul(before).text(), before)
    var after = chr(S_BASE + S_COUNT)
    assert_equal(decompose_hangul(after).text(), after)


def test_all_modern_syllables_round_trip_and_map_to_source() raises:
    # Advance an explicit mixed-radix odometer instead of repeating the
    # production quotient/modulus decomposition. With the legal Jamo range
    # checks below, each counter state has exactly one canonical encoding.
    var expected_leading = L_BASE
    var expected_vowel = V_BASE
    var expected_trailing = T_BASE
    var lv_count = 0
    var lvt_count = 0

    assert_equal(S_COUNT, 11172)
    for syllable_index in range(S_COUNT):
        var value = S_BASE + syllable_index
        var representation = decompose_hangul(chr(value))
        var decomposed = representation.text()
        var components = [scalar.to_u32() for scalar in decomposed.codepoints()]

        assert_equal(Int(components[0]), expected_leading)
        assert_equal(Int(components[1]), expected_vowel)
        assert_true(Int(components[0]) >= L_BASE)
        assert_true(Int(components[0]) < L_BASE + L_COUNT)
        assert_true(Int(components[1]) >= V_BASE)
        assert_true(Int(components[1]) < V_BASE + V_COUNT)
        var trailing_index = 0
        if expected_trailing == T_BASE:
            assert_equal(len(components), 2)
            lv_count += 1
        else:
            assert_equal(len(components), 3)
            assert_equal(Int(components[2]), expected_trailing)
            assert_true(Int(components[2]) > T_BASE)
            assert_true(Int(components[2]) < T_BASE + T_COUNT)
            trailing_index = Int(components[2]) - T_BASE
            lvt_count += 1

        var recomposed = S_BASE
        recomposed += (Int(components[0]) - L_BASE) * N_COUNT
        recomposed += (Int(components[1]) - V_BASE) * T_COUNT
        recomposed += trailing_index
        assert_equal(recomposed, value)

        expected_trailing += 1
        if expected_trailing == T_BASE + T_COUNT:
            expected_trailing = T_BASE
            expected_vowel += 1
            if expected_vowel == V_BASE + V_COUNT:
                expected_vowel = V_BASE
                expected_leading += 1

        var mappings = representation.mapping_snapshot()
        assert_equal(len(mappings), len(components))
        for index in range(len(mappings)):
            assert_equal(mappings[index].output_start(), index * 3)
            assert_equal(mappings[index].output_end(), index * 3 + 3)
            assert_equal(mappings[index].source_start(), 0)
            assert_equal(mappings[index].source_end(), 3)

        var source = representation.source_ranges_for_output(
            0, decomposed.byte_length()
        )
        assert_equal(len(source), 1)
        assert_equal(source[0].start(), 0)
        assert_equal(source[0].end(), 3)

    assert_equal(lv_count, 399)
    assert_equal(lvt_count, 10773)
    assert_equal(expected_leading, L_BASE + L_COUNT)
    assert_equal(expected_vowel, V_BASE)
    assert_equal(expected_trailing, T_BASE)


def test_decomposition_revalidates_reachable_mutation() raises:
    var representation = decompose_hangul("각")
    representation._mappings[0]._source_end = 2
    with assert_raises():
        _ = representation.text()
    with assert_raises():
        _ = representation.mapping_snapshot()


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
