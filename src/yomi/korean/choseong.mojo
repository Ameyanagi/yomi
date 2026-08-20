"""Precomposed Hangul syllable to compatibility-choseong conversion."""

from std.collections import List

from ..representation import PhoneticRepresentation, SourceMapping


def _compatibility_choseong(index: Int) -> String:
    if index == 0:
        return "ㄱ"
    if index == 1:
        return "ㄲ"
    if index == 2:
        return "ㄴ"
    if index == 3:
        return "ㄷ"
    if index == 4:
        return "ㄸ"
    if index == 5:
        return "ㄹ"
    if index == 6:
        return "ㅁ"
    if index == 7:
        return "ㅂ"
    if index == 8:
        return "ㅃ"
    if index == 9:
        return "ㅅ"
    if index == 10:
        return "ㅆ"
    if index == 11:
        return "ㅇ"
    if index == 12:
        return "ㅈ"
    if index == 13:
        return "ㅉ"
    if index == 14:
        return "ㅊ"
    if index == 15:
        return "ㅋ"
    if index == 16:
        return "ㅌ"
    if index == 17:
        return "ㅍ"
    return "ㅎ"


def _first_codepoint(grapheme: StringSlice) -> Int:
    for scalar in grapheme.codepoints():
        return Int(scalar.to_u32())
    return -1


def hangul_choseong(text: StringSlice) raises -> PhoneticRepresentation:
    """Convert precomposed Hangul syllables to compatibility choseong.

    A grapheme whose first code point is a modern precomposed Hangul syllable
    becomes that syllable's compatibility choseong. Any combining marks or
    extenders in that grapheme are consumed with the syllable, and the emitted
    choseong maps to the complete source grapheme. Other grapheme clusters pass
    through unchanged.
    """
    var source = String(text)
    var transformed = String()
    var mappings = List[SourceMapping]()
    var source_cursor = 0
    var output_cursor = 0

    for grapheme in source.graphemes():
        var source_length = grapheme.byte_length()
        var value = _first_codepoint(grapheme)
        var emitted = String(grapheme)
        if value >= 0xAC00 and value <= 0xD7A3:
            emitted = _compatibility_choseong((value - 0xAC00) // 588)
        elif value >= 0x1100 and value <= 0x1112:
            emitted = _compatibility_choseong(value - 0x1100)

        var output_length = emitted.byte_length()
        transformed += emitted
        mappings.append(
            SourceMapping(
                output_cursor,
                output_cursor + output_length,
                source_cursor,
                source_cursor + source_length,
            )
        )
        output_cursor += output_length
        source_cursor += source_length

    return PhoneticRepresentation(source^, transformed^, mappings^)
