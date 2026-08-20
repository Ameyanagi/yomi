from yomi import hangul_choseong
from std.testing import assert_equal


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
