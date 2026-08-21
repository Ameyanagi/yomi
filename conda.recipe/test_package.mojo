from std.testing import assert_equal

from yomi import decompose_hangul, hangul_choseong, romanize_kana


def main() raises:
    var representation = hangul_choseong("한국")
    assert_equal(representation.source_text(), "한국")
    assert_equal(representation.text(), "ㅎㄱ")
    var mappings = representation.mapping_snapshot()
    assert_equal(len(mappings), 2)
    assert_equal(mappings[0].output_start(), 0)
    assert_equal(mappings[0].output_end(), 3)
    assert_equal(mappings[0].source_start(), 0)
    assert_equal(mappings[0].source_end(), 3)

    var ranges = representation.source_ranges_for_output(0, 6)
    assert_equal(len(ranges), 1)
    assert_equal(ranges[0].start(), 0)
    assert_equal(ranges[0].end(), 6)

    var decomposed = hangul_choseong("한")
    assert_equal(decomposed.text(), "ㅎ")

    var hangul = decompose_hangul("각")
    assert_equal(hangul.source_text(), "각")
    assert_equal(hangul.text(), "각")
    var hangul_mappings = hangul.mapping_snapshot()
    assert_equal(len(hangul_mappings), 3)
    for index in range(len(hangul_mappings)):
        assert_equal(hangul_mappings[index].source_start(), 0)
        assert_equal(hangul_mappings[index].source_end(), 3)

    var hangul_source = hangul.source_ranges_for_output(0, 9)
    assert_equal(len(hangul_source), 1)
    assert_equal(hangul_source[0].start(), 0)
    assert_equal(hangul_source[0].end(), 3)

    var nfd_hangul = decompose_hangul("각")
    assert_equal(nfd_hangul.text(), hangul.text())
    var nfd_mappings = nfd_hangul.mapping_snapshot()
    assert_equal(len(nfd_mappings), 3)
    assert_equal(nfd_mappings[0].source_start(), 0)
    assert_equal(nfd_mappings[0].source_end(), 3)
    assert_equal(nfd_mappings[2].source_start(), 6)
    assert_equal(nfd_mappings[2].source_end(), 9)

    var kana = romanize_kana("ラーメン屋")
    assert_equal(kana.text(), "raamen屋")
    assert_equal(kana.mapping_count(), 5)
    var kana_source = kana.source_ranges_for_output(0, 6)
    assert_equal(len(kana_source), 1)
    assert_equal(kana_source[0].start(), 0)
    assert_equal(kana_source[0].end(), 12)
