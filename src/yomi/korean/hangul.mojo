"""Algorithmic decomposition of modern precomposed Hangul syllables."""

from std.collections import List

from ..representation import PhoneticRepresentation, SourceMapping


comptime _S_BASE = 0xAC00
comptime _L_BASE = 0x1100
comptime _V_BASE = 0x1161
comptime _T_BASE = 0x11A7
comptime _L_COUNT = 19
comptime _V_COUNT = 21
comptime _T_COUNT = 28
comptime _N_COUNT = _V_COUNT * _T_COUNT
comptime _S_COUNT = _L_COUNT * _N_COUNT


def _is_modern_syllable(value: Int) -> Bool:
    return value >= _S_BASE and value < _S_BASE + _S_COUNT


def _is_modern_leading_jamo(value: Int) -> Bool:
    return value >= _L_BASE and value < _L_BASE + _L_COUNT


def _leading_index(value: Int) -> Int:
    return (value - _S_BASE) // _N_COUNT


def _first_codepoint(grapheme: StringSlice) -> Int:
    for scalar in grapheme.codepoints():
        return Int(scalar.to_u32())
    return -1


def _append_segment(
    text: StringSlice,
    source_start: Int,
    source_end: Int,
    mut transformed: String,
    mut mappings: List[SourceMapping],
    mut output_cursor: Int,
) raises:
    var output_length = text.byte_length()
    transformed += text
    mappings.append(
        SourceMapping(
            output_cursor,
            output_cursor + output_length,
            source_start,
            source_end,
        )
    )
    output_cursor += output_length


def decompose_hangul(text: StringSlice) raises -> PhoneticRepresentation:
    """Canonically decompose modern precomposed Hangul syllables.

    Each emitted leading, vowel, and optional trailing Jamo maps to the exact
    source syllable code point. Remaining combining/extender code points in the
    same grapheme pass through with their own source ranges. Canonically
    decomposed Hangul passes through with exact scalar mappings. Other
    graphemes pass through unchanged with one mapping per grapheme.
    """
    var source = String(text)
    var transformed = String()
    var mappings = List[SourceMapping]()
    var source_cursor = 0
    var output_cursor = 0

    for grapheme in source.graphemes():
        var first_value = _first_codepoint(grapheme)
        var grapheme_length = grapheme.byte_length()
        if not _is_modern_syllable(first_value):
            if _is_modern_leading_jamo(first_value):
                var codepoint_cursor = source_cursor
                for codepoint in grapheme.codepoint_slices():
                    var codepoint_length = codepoint.byte_length()
                    _append_segment(
                        codepoint,
                        codepoint_cursor,
                        codepoint_cursor + codepoint_length,
                        transformed,
                        mappings,
                        output_cursor,
                    )
                    codepoint_cursor += codepoint_length
            else:
                _append_segment(
                    grapheme,
                    source_cursor,
                    source_cursor + grapheme_length,
                    transformed,
                    mappings,
                    output_cursor,
                )
            source_cursor += grapheme_length
            continue

        var syllable_index = first_value - _S_BASE
        var leading = chr(_L_BASE + syllable_index // _N_COUNT)
        var vowel = chr(_V_BASE + (syllable_index % _N_COUNT) // _T_COUNT)
        var trailing = _T_BASE + syllable_index % _T_COUNT

        var first_length = 0
        for codepoint in grapheme.codepoint_slices():
            first_length = codepoint.byte_length()
            break
        var syllable_end = source_cursor + first_length
        _append_segment(
            leading, source_cursor, syllable_end, transformed, mappings, output_cursor
        )
        _append_segment(
            vowel, source_cursor, syllable_end, transformed, mappings, output_cursor
        )
        if trailing != _T_BASE:
            var trailing_text = chr(trailing)
            _append_segment(
                trailing_text,
                source_cursor,
                syllable_end,
                transformed,
                mappings,
                output_cursor,
            )

        var codepoint_cursor = source_cursor
        var first = True
        for codepoint in grapheme.codepoint_slices():
            var codepoint_length = codepoint.byte_length()
            if first:
                first = False
            else:
                _append_segment(
                    codepoint,
                    codepoint_cursor,
                    codepoint_cursor + codepoint_length,
                    transformed,
                    mappings,
                    output_cursor,
                )
            codepoint_cursor += codepoint_length

        source_cursor += grapheme_length

    return PhoneticRepresentation(source^, transformed^, mappings^)
