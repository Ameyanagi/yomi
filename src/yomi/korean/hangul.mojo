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
comptime _COMPATIBILITY_CONSONANT_BASE = 0x3131
comptime _COMPATIBILITY_VOWEL_BASE = 0x314F


struct _CompositionPendingKind(Copyable, Equatable, ImplicitlyCopyable):
    var _value: Int

    comptime NONE = _CompositionPendingKind(_value=0)
    comptime LEADING = _CompositionPendingKind(_value=1)
    comptime LV_SYLLABLE = _CompositionPendingKind(_value=2)
    comptime AMBIGUOUS_TRAILING = _CompositionPendingKind(_value=3)

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


def _compatibility_choseong_value(index: Int) -> Int:
    if index == 0:
        return 0x3131
    if index == 1:
        return 0x3132
    if index == 2:
        return 0x3134
    if index == 3:
        return 0x3137
    if index == 4:
        return 0x3138
    if index == 5:
        return 0x3139
    if index == 6:
        return 0x3141
    if index == 7:
        return 0x3142
    if index == 8:
        return 0x3143
    if index == 9:
        return 0x3145
    if index == 10:
        return 0x3146
    if index == 11:
        return 0x3147
    if index == 12:
        return 0x3148
    if index == 13:
        return 0x3149
    if index == 14:
        return 0x314A
    if index == 15:
        return 0x314B
    if index == 16:
        return 0x314C
    if index == 17:
        return 0x314D
    return 0x314E


def _compatibility_choseong(index: Int) -> String:
    return chr(_compatibility_choseong_value(index))


def _compatibility_leading_jamo(value: Int) -> Int:
    if value < 0x3131 or value > 0x314E:
        return -1
    for index in range(_L_COUNT):
        if value == _compatibility_choseong_value(index):
            return _L_BASE + index
    return -1


def _compatibility_trailing_value(trailing_index: Int) -> Int:
    if trailing_index <= 7:
        return _COMPATIBILITY_CONSONANT_BASE + trailing_index - 1
    if trailing_index <= 17:
        return _COMPATIBILITY_CONSONANT_BASE + trailing_index
    if trailing_index <= 22:
        return _COMPATIBILITY_CONSONANT_BASE + trailing_index + 1
    return _COMPATIBILITY_CONSONANT_BASE + trailing_index + 2


def _compatibility_trailing_jamo(value: Int) -> Int:
    if value < 0x3131 or value > 0x314E:
        return -1
    for trailing_index in range(1, _T_COUNT):
        if value == _compatibility_trailing_value(trailing_index):
            return _T_BASE + trailing_index
    return -1


def _fold_vowel_jamo(value: Int) -> Int:
    if _is_modern_vowel_jamo(value):
        return value
    if (
        value >= _COMPATIBILITY_VOWEL_BASE
        and value < _COMPATIBILITY_VOWEL_BASE + _V_COUNT
    ):
        return _V_BASE + value - _COMPATIBILITY_VOWEL_BASE
    return -1


def _starts_composition_candidate(value: Int) -> Bool:
    return (
        _is_modern_leading_jamo(value)
        or _is_modern_lv_syllable(value)
        or _compatibility_leading_jamo(value) >= 0
    )


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
):
    var output_length = text.byte_length()
    transformed += text
    mappings.append(
        SourceMapping._from_validated(
            output_cursor,
            output_cursor + output_length,
            source_start,
            source_end,
        )
    )
    output_cursor += output_length


def compose_hangul(text: StringSlice) -> PhoneticRepresentation:
    """Compose modern Hangul Jamo into precomposed syllables.

    Accepted candidates are conjoining leading U+1100--U+1112, vowel
    U+1161--U+1175, and trailing U+11A8--U+11C2 Jamo; compatibility Jamo
    U+3131--U+3163; and a precomposed LV syllable plus a trailing Jamo. Each
    contraction maps all consumed source scalars to one emitted syllable.

    A compatibility consonant after an LV syllable becomes its trailing Jamo
    unless the next scalar is a vowel and the consonant can instead lead the
    next syllable. Isolated, incomplete, or non-candidate Jamo pass through
    unchanged. Other grapheme clusters retain one exact mapping per grapheme.
    """
    var source = String(text)
    var transformed = String()
    var mappings = List[SourceMapping]()
    var source_cursor = 0
    var output_cursor = 0
    var pending_kind = _CompositionPendingKind.NONE
    var pending_value = 0
    var pending_original_value = 0
    var pending_source_start = 0
    var pending_source_end = 0
    var ambiguous_leading = 0
    var ambiguous_trailing = 0
    var ambiguous_source_start = 0
    var ambiguous_source_end = 0

    for grapheme in source.graphemes():
        var first_value = _first_codepoint(grapheme)
        var grapheme_length = grapheme.byte_length()

        # Resolve a pending candidate before a non-matching grapheme so an
        # unrelated grapheme can retain its existing whole-grapheme mapping.
        if (
            pending_kind == _CompositionPendingKind.LEADING
            and _fold_vowel_jamo(first_value) < 0
        ):
            _append_segment(
                chr(pending_original_value),
                pending_source_start,
                pending_source_end,
                transformed,
                mappings,
                output_cursor,
            )
            pending_kind = _CompositionPendingKind.NONE
        elif (
            pending_kind == _CompositionPendingKind.LV_SYLLABLE
            and not _is_modern_trailing_jamo(first_value)
            and _compatibility_trailing_jamo(first_value) < 0
        ):
            _append_segment(
                chr(pending_value),
                pending_source_start,
                pending_source_end,
                transformed,
                mappings,
                output_cursor,
            )
            pending_kind = _CompositionPendingKind.NONE
        elif (
            pending_kind == _CompositionPendingKind.AMBIGUOUS_TRAILING
            and _fold_vowel_jamo(first_value) < 0
        ):
            _append_segment(
                chr(pending_value + ambiguous_trailing - _T_BASE),
                pending_source_start,
                ambiguous_source_end,
                transformed,
                mappings,
                output_cursor,
            )
            pending_kind = _CompositionPendingKind.NONE

        if (
            pending_kind == _CompositionPendingKind.NONE
            and not _starts_composition_candidate(first_value)
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

        var codepoint_cursor = source_cursor
        for codepoint in grapheme.codepoint_slices():
            var codepoint_length = codepoint.byte_length()
            var codepoint_end = codepoint_cursor + codepoint_length
            var value = _first_codepoint(codepoint)
            var vowel = _fold_vowel_jamo(value)
            var compatibility_leading = _compatibility_leading_jamo(value)
            var compatibility_trailing = _compatibility_trailing_jamo(value)
            var consumed = False

            if pending_kind == _CompositionPendingKind.LEADING:
                if vowel >= 0:
                    pending_value = _S_BASE + (
                        (pending_value - _L_BASE) * _N_COUNT
                        + (vowel - _V_BASE) * _T_COUNT
                    )
                    pending_kind = _CompositionPendingKind.LV_SYLLABLE
                    pending_source_end = codepoint_end
                    consumed = True
                else:
                    _append_segment(
                        chr(pending_original_value),
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
                elif compatibility_trailing >= 0:
                    if compatibility_leading >= 0:
                        pending_kind = _CompositionPendingKind.AMBIGUOUS_TRAILING
                        ambiguous_leading = compatibility_leading
                        ambiguous_trailing = compatibility_trailing
                        ambiguous_source_start = codepoint_cursor
                        ambiguous_source_end = codepoint_end
                    else:
                        _append_segment(
                            chr(pending_value + compatibility_trailing - _T_BASE),
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
            elif pending_kind == _CompositionPendingKind.AMBIGUOUS_TRAILING:
                if vowel >= 0:
                    _append_segment(
                        chr(pending_value),
                        pending_source_start,
                        pending_source_end,
                        transformed,
                        mappings,
                        output_cursor,
                    )
                    pending_value = _S_BASE + (
                        (ambiguous_leading - _L_BASE) * _N_COUNT
                        + (vowel - _V_BASE) * _T_COUNT
                    )
                    pending_kind = _CompositionPendingKind.LV_SYLLABLE
                    pending_source_start = ambiguous_source_start
                    pending_source_end = codepoint_end
                    consumed = True
                else:
                    _append_segment(
                        chr(pending_value + ambiguous_trailing - _T_BASE),
                        pending_source_start,
                        ambiguous_source_end,
                        transformed,
                        mappings,
                        output_cursor,
                    )
                    pending_kind = _CompositionPendingKind.NONE

            if not consumed:
                if _is_modern_leading_jamo(value):
                    pending_kind = _CompositionPendingKind.LEADING
                    pending_value = value
                    pending_original_value = value
                    pending_source_start = codepoint_cursor
                    pending_source_end = codepoint_end
                elif compatibility_leading >= 0:
                    pending_kind = _CompositionPendingKind.LEADING
                    pending_value = compatibility_leading
                    pending_original_value = value
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

        source_cursor += grapheme_length

    if pending_kind == _CompositionPendingKind.LEADING:
        _append_segment(
            chr(pending_original_value),
            pending_source_start,
            pending_source_end,
            transformed,
            mappings,
            output_cursor,
        )
    elif pending_kind == _CompositionPendingKind.LV_SYLLABLE:
        _append_segment(
            chr(pending_value),
            pending_source_start,
            pending_source_end,
            transformed,
            mappings,
            output_cursor,
        )
    elif pending_kind == _CompositionPendingKind.AMBIGUOUS_TRAILING:
        _append_segment(
            chr(pending_value + ambiguous_trailing - _T_BASE),
            pending_source_start,
            ambiguous_source_end,
            transformed,
            mappings,
            output_cursor,
        )

    return PhoneticRepresentation._from_validated(source^, transformed^, mappings^)


def _decompose_hangul(text: StringSlice, compatibility: Bool) -> PhoneticRepresentation:
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
        var leading_index = syllable_index // _N_COUNT
        var vowel_index = (syllable_index % _N_COUNT) // _T_COUNT
        var leading = chr(_L_BASE + leading_index)
        var vowel = chr(_V_BASE + vowel_index)
        if compatibility:
            leading = _compatibility_choseong(leading_index)
            vowel = chr(_COMPATIBILITY_VOWEL_BASE + vowel_index)
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
            if compatibility:
                trailing_text = chr(_compatibility_trailing_value(trailing - _T_BASE))
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

    return PhoneticRepresentation._from_validated(source^, transformed^, mappings^)


def decompose_hangul(text: StringSlice) -> PhoneticRepresentation:
    """Canonically decompose modern precomposed Hangul syllables.

    Each emitted conjoining leading U+1100--U+1112, vowel U+1161--U+1175,
    and optional trailing U+11A8--U+11C2 Jamo maps to the exact source
    syllable. Remaining combining or extender scalars in the same grapheme
    retain their own ranges. Canonically decomposed Hangul passes through with
    exact scalar mappings; other graphemes retain one mapping per grapheme.
    """
    return _decompose_hangul(text, False)


def decompose_hangul_compatibility(
    text: StringSlice,
) -> PhoneticRepresentation:
    """Decompose modern syllables into visible compatibility Jamo.

    Leading consonants, vowels, and optional trailing consonants use the
    modern compatibility forms in U+3131--U+3163. Each emitted Jamo maps to the
    exact source syllable bytes; all pass-through behavior matches
    `decompose_hangul`.
    """
    return _decompose_hangul(text, True)
