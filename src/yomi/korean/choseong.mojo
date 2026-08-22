"""Precomposed Hangul syllable to compatibility-choseong conversion."""

from std.collections import List

from ..representation import PhoneticRepresentation, SourceMapping
from .hangul import (
    _compatibility_choseong,
    _first_codepoint,
    _is_modern_leading_jamo,
    _is_modern_syllable,
    _leading_index,
)


def hangul_choseong(text: StringSlice) -> PhoneticRepresentation:
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
        if _is_modern_syllable(value):
            emitted = _compatibility_choseong(_leading_index(value))
        elif _is_modern_leading_jamo(value):
            emitted = _compatibility_choseong(value - 0x1100)

        var output_length = emitted.byte_length()
        transformed += emitted
        mappings.append(
            SourceMapping._from_validated(
                output_cursor,
                output_cursor + output_length,
                source_cursor,
                source_cursor + source_length,
            )
        )
        output_cursor += output_length
        source_cursor += source_length

    return PhoneticRepresentation._from_validated(source^, transformed^, mappings^)
