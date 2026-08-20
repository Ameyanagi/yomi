"""Algorithmic composition and decomposition of modern Hangul syllables."""

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


struct _CompositionPendingKind(Copyable, Equatable, ImplicitlyCopyable):
    var _value: Int

    comptime NONE = _CompositionPendingKind(_value=0)
    comptime LEADING = _CompositionPendingKind(_value=1)
    comptime LV_SYLLABLE = _CompositionPendingKind(_value=2)

    def __init__(out self, *, _value: Int):
        self._value = _value

    def __eq__(self, other: Self) -> Bool:
        return self._value == other._value


def _is_modern_syllable(value: Int) -> Bool:
    return value >= _S_BASE and value < _S_BASE + _S_COUNT


def _is_modern_leading_jamo(value: Int) -> Bool:
    return value >= _L_BASE and value < _L_BASE + _L_COUNT


def _is_modern_vowel_jamo(value: Int) -> Bool:
    return value >= _V_BASE and value < _V_BASE + _V_COUNT


def _is_modern_trailing_jamo(value: Int) -> Bool:
    return value > _T_BASE and value < _T_BASE + _T_COUNT


def _is_modern_lv_syllable(value: Int) -> Bool:
    return _is_modern_syllable(value) and (value - _S_BASE) % _T_COUNT == 0


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


def compose_hangul(text: StringSlice) raises -> PhoneticRepresentation:
    """Canonically compose modern conjoining Jamo into Hangul syllables. Each
    contraction maps the consumed source scalars to one emitted syllable, so
    one output mapping covers all source Jamo bytes. A precomposed LV syllable
    plus a modern trailing Jamo contracts with the same mapping shape.

    Isolated or incomplete Jamo pass through unchanged with exact per-scalar
    source ranges. Combining or extender scalars after a composition candidate
    also retain their own ranges. Other grapheme clusters pass through
    unchanged with one mapping per grapheme.
    """
    var source = String(text)
    var transformed = String()
    var mappings = List[SourceMapping]()
    var source_cursor = 0
    var output_cursor = 0

    for grapheme in source.graphemes():
        var first_value = _first_codepoint(grapheme)
        var grapheme_length = grapheme.byte_length()
        if not (
            _is_modern_leading_jamo(first_value) or _is_modern_lv_syllable(first_value)
        ):
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

        # A pending leading Jamo may absorb a vowel; the resulting LV value may
        # then absorb a trailing Jamo. On a mismatch, emit the pending scalar
        # and reconsider the current scalar as the start of another candidate.
        var pending_kind = _CompositionPendingKind.NONE
        var pending_value = 0
        var pending_source_start = source_cursor
        var pending_source_end = source_cursor
        var codepoint_cursor = source_cursor
        for codepoint in grapheme.codepoint_slices():
            var codepoint_length = codepoint.byte_length()
            var codepoint_end = codepoint_cursor + codepoint_length
            var value = _first_codepoint(codepoint)
            var consumed = False

            if pending_kind == _CompositionPendingKind.LEADING:
                if _is_modern_vowel_jamo(value):
                    pending_value = _S_BASE + (
                        (pending_value - _L_BASE) * _N_COUNT
                        + (value - _V_BASE) * _T_COUNT
                    )
                    pending_kind = _CompositionPendingKind.LV_SYLLABLE
                    pending_source_end = codepoint_end
                    consumed = True
                else:
                    _append_segment(
                        chr(pending_value),
                        pending_source_start,
                        pending_source_end,
                        transformed,
                        mappings,
                        output_cursor,
                    )
                    pending_kind = _CompositionPendingKind.NONE
            elif pending_kind == _CompositionPendingKind.LV_SYLLABLE:
                if _is_modern_trailing_jamo(value):
                    _append_segment(
                        chr(pending_value + value - _T_BASE),
                        pending_source_start,
                        codepoint_end,
                        transformed,
                        mappings,
                        output_cursor,
                    )
                    pending_kind = _CompositionPendingKind.NONE
                    consumed = True
                else:
                    _append_segment(
                        chr(pending_value),
                        pending_source_start,
                        pending_source_end,
                        transformed,
                        mappings,
                        output_cursor,
                    )
                    pending_kind = _CompositionPendingKind.NONE

            if not consumed:
                if _is_modern_leading_jamo(value):
                    pending_kind = _CompositionPendingKind.LEADING
                    pending_value = value
                    pending_source_start = codepoint_cursor
                    pending_source_end = codepoint_end
                elif _is_modern_lv_syllable(value):
                    pending_kind = _CompositionPendingKind.LV_SYLLABLE
                    pending_value = value
                    pending_source_start = codepoint_cursor
                    pending_source_end = codepoint_end
                else:
                    _append_segment(
                        codepoint,
                        codepoint_cursor,
                        codepoint_end,
                        transformed,
                        mappings,
                        output_cursor,
                    )

            codepoint_cursor = codepoint_end

        if pending_kind != _CompositionPendingKind.NONE:
            _append_segment(
                chr(pending_value),
                pending_source_start,
                pending_source_end,
                transformed,
                mappings,
                output_cursor,
            )

        source_cursor += grapheme_length

    return PhoneticRepresentation(source^, transformed^, mappings^)


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
