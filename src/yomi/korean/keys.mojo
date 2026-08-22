"""Typed Korean candidate keys with exact source-byte mappings."""

from std.collections import List

from ..representation import PhoneticRepresentation, SourceMapping
from ..search_key import SearchKey, SearchKeyBundle, SearchKeyKind
from .choseong import hangul_choseong
from .search import hangul_keyboard, romanize_hangul


def _identity_key(source: StringSlice) raises -> PhoneticRepresentation:
    var owned = String(source)
    var mappings = List[SourceMapping](capacity=source.byte_length())
    var cursor = 0
    for scalar in StringSlice(owned).codepoint_slices():
        var end = cursor + scalar.byte_length()
        mappings.append(SourceMapping(cursor, end, cursor, end))
        cursor = end
    return PhoneticRepresentation(owned.copy(), owned^, mappings^)


def _append_generated(
    mut output: List[SearchKey],
    kind: SearchKeyKind,
    var representation: PhoneticRepresentation,
    max_count: Int,
    max_total_key_bytes: Int,
    mut generated_bytes: Int,
):
    if len(output) >= max_count:
        return
    var byte_count = representation.text_byte_length()
    if generated_bytes + byte_count > max_total_key_bytes:
        return
    generated_bytes += byte_count
    output.append(SearchKey(kind, representation^))


def korean_candidate_keys(
    source: StringSlice,
    max_count: Int = 4,
    max_total_key_bytes: Int = 1024,
) raises -> SearchKeyBundle:
    """Build original, romanized, choseong, and keyboard Korean keys.

    The original key is required and does not consume the generated-byte
    budget. Generated keys retain this deterministic order: romanized,
    choseong initials, then Dubeolsik keyboard input. ``max_count`` is within
    ``[0, 4]`` and the default generated-byte budget is 1,024 bytes.
    """
    if max_count < 0 or max_count > 4:
        raise Error(
            "max_count must be within [0, 4] for Korean candidate keys; got "
            + String(max_count)
        )
    if max_total_key_bytes < 0:
        raise Error(
            "max_total_key_bytes must be nonnegative; got "
            + String(max_total_key_bytes)
        )
    var output = List[SearchKey](capacity=max_count)
    if max_count == 0:
        return SearchKeyBundle(output^, max_count)

    output.append(SearchKey(SearchKeyKind.ORIGINAL, _identity_key(source)))
    var generated_bytes = 0
    if len(output) >= max_count or max_total_key_bytes == 0:
        return SearchKeyBundle(output^, max_count)

    var romanized = romanize_hangul(source)
    _append_generated(
        output,
        SearchKeyKind.KOREAN_ROMANIZED,
        romanized^,
        max_count,
        max_total_key_bytes,
        generated_bytes,
    )
    if len(output) >= max_count:
        return SearchKeyBundle(output^, max_count)

    var initials = hangul_choseong(source)
    _append_generated(
        output,
        SearchKeyKind.KOREAN_INITIALS,
        initials^,
        max_count,
        max_total_key_bytes,
        generated_bytes,
    )
    if len(output) >= max_count:
        return SearchKeyBundle(output^, max_count)

    var keyboard = hangul_keyboard(source)
    _append_generated(
        output,
        SearchKeyKind.KOREAN_KEYBOARD,
        keyboard^,
        max_count,
        max_total_key_bytes,
        generated_bytes,
    )
    return SearchKeyBundle(output^, max_count)
