"""Source-preserving kana script conversion."""

from std.collections import List, Optional

from ..representation import PhoneticRepresentation, SourceMapping
from .voicing import _compose_kana_voicing


def _first_codepoint(text: StringSlice) -> Int:
    for scalar in text.codepoints():
        return Int(scalar.to_u32())
    return -1


def _to_hiragana_scalar(value: Int) -> Int:
    if value >= 0x30A1 and value <= 0x30F6:
        return value - 0x60
    if value >= 0x30FD and value <= 0x30FE:
        return value - 0x60
    return value


def _to_katakana_scalar(value: Int) -> Int:
    if value >= 0x3041 and value <= 0x3096:
        return value + 0x60
    if value >= 0x309D and value <= 0x309E:
        return value + 0x60
    return value


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


def _convert_kana(text: StringSlice, to_hiragana: Bool) -> PhoneticRepresentation:
    var source = String(text)
    var transformed = String()
    var mappings = List[SourceMapping]()
    var source_cursor = 0
    var output_cursor = 0

    for grapheme in source.graphemes():
        var first = -1
        var second = -1
        var count = 0
        for codepoint in grapheme.codepoint_slices():
            if count == 0:
                first = _first_codepoint(codepoint)
            elif count == 1:
                second = _first_codepoint(codepoint)
            count += 1

        var converted: Optional[Int] = None
        if count == 1:
            if to_hiragana:
                converted = _to_hiragana_scalar(first)
            else:
                converted = _to_katakana_scalar(first)
        elif count == 2:
            var composed = _compose_kana_voicing(first, second)
            if composed:
                if to_hiragana:
                    converted = _to_hiragana_scalar(composed.value())
                else:
                    converted = _to_katakana_scalar(composed.value())

        var source_end = source_cursor + grapheme.byte_length()
        if converted:
            _append_segment(
                chr(converted.value()),
                source_cursor,
                source_end,
                transformed,
                mappings,
                output_cursor,
            )
        else:
            _append_segment(
                grapheme,
                source_cursor,
                source_end,
                transformed,
                mappings,
                output_cursor,
            )
        source_cursor = source_end

    return PhoneticRepresentation._from_validated(source^, transformed^, mappings^)


def to_hiragana(text: StringSlice) -> PhoneticRepresentation:
    """Convert katakana with one mapping per converted scalar, except that a
    base kana plus combining voicing mark contracts from two source scalars to
    one NFC hiragana scalar. Every other grapheme passes through with its exact
    source range.

    Katakana U+30A1..U+30F6 and U+30FD..U+30FE map to the hiragana scalar 0x60
    lower. The shared prolonged sound mark U+30FC is unchanged. U+30F7..U+30FA
    have no precomposed hiragana counterparts and pass through unchanged.
    Composable hiragana or katakana NFD voicing pairs canonicalize to NFC in
    the target script. No input is invalid.
    """
    return _convert_kana(text, True)


def to_katakana(text: StringSlice) -> PhoneticRepresentation:
    """Convert hiragana with one mapping per converted scalar, except that a
    base kana plus combining voicing mark contracts from two source scalars to
    one NFC katakana scalar. Every other grapheme passes through with its exact
    source range.

    Hiragana U+3041..U+3096 and U+309D..U+309E map to the katakana scalar 0x60
    higher. The shared prolonged sound mark U+30FC is unchanged. Composable
    hiragana or katakana NFD voicing pairs canonicalize to NFC in the target
    script. No input is invalid.
    """
    return _convert_kana(text, False)
