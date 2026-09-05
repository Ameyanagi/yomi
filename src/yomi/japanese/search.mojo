"""Yuru-compatible Japanese finder and query representations."""

from std.collections import List, Optional

from ..representation import PhoneticRepresentation, SourceMapping
from ..search_key import SearchKey, SearchKeyBundle, SearchKeyKind
from .kana import to_romaji
from .voicing import _compose_kana_voicing


struct _InputUnit(Copyable):
    var _first: Int
    var _second: Int
    var _count: Int
    var _source_start: Int
    var _source_end: Int

    def __init__(
        out self,
        first: Int,
        second: Int,
        count: Int,
        source_start: Int,
        source_end: Int,
    ):
        self._first = first
        self._second = second
        self._count = count
        self._source_start = source_start
        self._source_end = source_end


def _first_codepoint(text: StringSlice) -> Int:
    for scalar in text.codepoints():
        return Int(scalar.to_u32())
    return -1


def _scan_input_units(source: StringSlice) -> List[_InputUnit]:
    # UTF-8 bytes are a safe upper bound on grapheme count and avoid repeated
    # growth in the profiled candidate-index construction path.
    var units = List[_InputUnit](capacity=source.byte_length())
    var source_cursor = 0
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
        var source_end = source_cursor + grapheme.byte_length()
        units.append(
            _InputUnit(
                first,
                second,
                count,
                source_cursor,
                source_end,
            )
        )
        source_cursor = source_end
    return units^


def _halfwidth_katakana(value: Int) -> Int:
    if value == 0xFF61:
        return 0x3002
    if value == 0xFF62:
        return 0x300C
    if value == 0xFF63:
        return 0x300D
    if value == 0xFF64:
        return 0x3001
    if value == 0xFF65:
        return 0x30FB
    if value == 0xFF66:
        return 0x30F2
    if value >= 0xFF67 and value <= 0xFF6B:
        return 0x30A1 + (value - 0xFF67) * 2
    if value >= 0xFF6C and value <= 0xFF6E:
        return 0x30E3 + (value - 0xFF6C) * 2
    if value == 0xFF6F:
        return 0x30C3
    if value == 0xFF70:
        return 0x30FC
    if value >= 0xFF71 and value <= 0xFF75:
        return 0x30A2 + (value - 0xFF71) * 2
    if value == 0xFF76:
        return 0x30AB
    if value == 0xFF77:
        return 0x30AD
    if value == 0xFF78:
        return 0x30AF
    if value == 0xFF79:
        return 0x30B1
    if value == 0xFF7A:
        return 0x30B3
    if value == 0xFF7B:
        return 0x30B5
    if value == 0xFF7C:
        return 0x30B7
    if value == 0xFF7D:
        return 0x30B9
    if value == 0xFF7E:
        return 0x30BB
    if value == 0xFF7F:
        return 0x30BD
    if value == 0xFF80:
        return 0x30BF
    if value == 0xFF81:
        return 0x30C1
    if value == 0xFF82:
        return 0x30C4
    if value == 0xFF83:
        return 0x30C6
    if value == 0xFF84:
        return 0x30C8
    if value == 0xFF85:
        return 0x30CA
    if value == 0xFF86:
        return 0x30CB
    if value == 0xFF87:
        return 0x30CC
    if value == 0xFF88:
        return 0x30CD
    if value == 0xFF89:
        return 0x30CE
    if value == 0xFF8A:
        return 0x30CF
    if value == 0xFF8B:
        return 0x30D2
    if value == 0xFF8C:
        return 0x30D5
    if value == 0xFF8D:
        return 0x30D8
    if value == 0xFF8E:
        return 0x30DB
    if value == 0xFF8F:
        return 0x30DE
    if value == 0xFF90:
        return 0x30DF
    if value == 0xFF91:
        return 0x30E0
    if value == 0xFF92:
        return 0x30E1
    if value == 0xFF93:
        return 0x30E2
    if value == 0xFF94:
        return 0x30E4
    if value == 0xFF95:
        return 0x30E6
    if value == 0xFF96:
        return 0x30E8
    if value == 0xFF97:
        return 0x30E9
    if value == 0xFF98:
        return 0x30EA
    if value == 0xFF99:
        return 0x30EB
    if value == 0xFF9A:
        return 0x30EC
    if value == 0xFF9B:
        return 0x30ED
    if value == 0xFF9C:
        return 0x30EF
    if value == 0xFF9D:
        return 0x30F3
    return value


def _is_dash(value: Int) -> Bool:
    return (
        value == 0x002D
        or (value >= 0x2010 and value <= 0x2015)
        or value == 0x2212
        or value == 0x30A0
        or value == 0x30FC
        or value == 0xFE58
        or value == 0xFE63
        or value == 0xFF0D
        or value == 0xFF70
    )


def _normalized_scalar(input_value: Int) -> String:
    var value = input_value
    if value >= 0xFF01 and value <= 0xFF5E:
        value -= 0xFEE0
    if value >= 0x41 and value <= 0x5A:
        value += 0x20
    if value == 0x3000:
        return " "
    if _is_dash(value):
        return "-"
    if value == 0xFF9E:
        return chr(0x3099)
    if value == 0xFF9F:
        return chr(0x309A)
    value = _halfwidth_katakana(value)
    if value >= 0x30A1 and value <= 0x30F6:
        value -= 0x60
    elif value >= 0x30FD and value <= 0x30FE:
        value -= 0x60
    return chr(value)


def _compatibility_composition(base: Int, mark: Int) -> Optional[Int]:
    var normalized_base = base
    if base >= 0xFF66 and base <= 0xFF9D:
        normalized_base = _halfwidth_katakana(base)
    elif not (
        (base >= 0x3041 and base <= 0x3096) or (base >= 0x30A1 and base <= 0x30F6)
    ):
        return None
    var normalized_mark: Int
    if mark == 0xFF9E or mark == 0x3099:
        normalized_mark = 0x3099
    elif mark == 0xFF9F or mark == 0x309A:
        normalized_mark = 0x309A
    else:
        return None
    var composed = _compose_kana_voicing(normalized_base, normalized_mark)
    if not composed:
        return None
    var value = composed.value()
    if value >= 0x30A1 and value <= 0x30F6:
        value -= 0x60
    return value


def _normalized_grapheme(
    source: StringSlice, first: Int, second: Int, count: Int
) -> String:
    var output = String()
    var skip = 0
    if count >= 2:
        var composed = _compatibility_composition(first, second)
        if composed:
            output += chr(composed.value())
            skip = 2
    var index = 0
    for codepoint in source.codepoint_slices():
        if index >= skip:
            output += _normalized_scalar(_first_codepoint(codepoint))
        index += 1
    return output^


def _append_mapped(
    value: StringSlice,
    source_start: Int,
    source_end: Int,
    mut output: String,
    mut mappings: List[SourceMapping],
    mut output_cursor: Int,
) raises:
    var output_end = output_cursor + value.byte_length()
    output += value
    mappings.append(SourceMapping(output_cursor, output_end, source_start, source_end))
    output_cursor = output_end


def japanese_kana_key(source: StringSlice) raises -> PhoneticRepresentation:
    """Build a hiragana finder key with Yuru-compatible width folding.

    ASCII is lowercased; full-width ASCII and space, half-width katakana, dash
    variants, and the prolonged sound mark are folded. Every emitted span maps
    to the complete source grapheme or compatible half-width voiced pair.
    """
    var owned_source = String(source)
    var units = _scan_input_units(owned_source)
    var output = String()
    var mappings = List[SourceMapping](capacity=len(units))
    var output_cursor = 0
    var index = 0
    while index < len(units):
        var unit = units[index].copy()
        var composed: Optional[Int] = None
        var source_end = unit._source_end
        if unit._count == 2:
            composed = _compatibility_composition(unit._first, unit._second)
        elif (
            unit._count == 1 and index + 1 < len(units) and units[index + 1]._count == 1
        ):
            composed = _compatibility_composition(unit._first, units[index + 1]._first)
            if composed:
                source_end = units[index + 1]._source_end
                index += 1

        if composed:
            _append_mapped(
                chr(composed.value()),
                unit._source_start,
                source_end,
                output,
                mappings,
                output_cursor,
            )
        elif unit._count == 1:
            var normalized = _normalized_scalar(unit._first)
            _append_mapped(
                normalized,
                unit._source_start,
                unit._source_end,
                output,
                mappings,
                output_cursor,
            )
        else:
            var source_grapheme = StringSlice(owned_source)[
                byte = unit._source_start : unit._source_end
            ]
            var normalized = _normalized_grapheme(
                source_grapheme,
                unit._first,
                unit._second,
                unit._count,
            )
            _append_mapped(
                normalized,
                unit._source_start,
                unit._source_end,
                output,
                mappings,
                output_cursor,
            )
        index += 1
    return PhoneticRepresentation(owned_source^, output^, mappings^)


def _base_normalized_scalar(input_value: Int) -> String:
    var value = input_value
    if value >= 0xFF01 and value <= 0xFF5E:
        value -= 0xFEE0
    if value >= 0x41 and value <= 0x5A:
        value += 0x20
    if value == 0x3000:
        return " "
    if _is_dash(value):
        return "-"
    if value == 0xFF9E:
        return chr(0x3099)
    if value == 0xFF9F:
        return chr(0x309A)
    return chr(_halfwidth_katakana(value))


def _base_compatibility_composition(base: Int, mark: Int) -> Optional[Int]:
    var normalized_base = base
    if base >= 0xFF66 and base <= 0xFF9D:
        normalized_base = _halfwidth_katakana(base)
    elif not (
        (base >= 0x3041 and base <= 0x3096) or (base >= 0x30A1 and base <= 0x30F6)
    ):
        return None
    var normalized_mark: Int
    if mark == 0xFF9E or mark == 0x3099:
        normalized_mark = 0x3099
    elif mark == 0xFF9F or mark == 0x309A:
        normalized_mark = 0x309A
    else:
        return None
    return _compose_kana_voicing(normalized_base, normalized_mark)


def _base_normalized_grapheme(
    source: StringSlice,
    first: Int,
    second: Int,
    count: Int,
) -> String:
    var output = String()
    var skip = 0
    if count >= 2:
        var composed = _base_compatibility_composition(first, second)
        if composed:
            output += chr(composed.value())
            skip = 2
    var index = 0
    for codepoint in source.codepoint_slices():
        if index >= skip:
            output += _base_normalized_scalar(_first_codepoint(codepoint))
        index += 1
    return output^


def _japanese_normalized_key(
    source: StringSlice,
) raises -> PhoneticRepresentation:
    """Build Yomi's documented subset of Yuru base normalization.

    This folds ASCII case/width, ideographic space, supported dash forms, and
    half-width kana with voicing. It deliberately does not claim general NFKC.
    """
    var owned_source = String(source)
    var units = _scan_input_units(owned_source)
    var output = String()
    var mappings = List[SourceMapping](capacity=len(units))
    var output_cursor = 0
    var index = 0
    while index < len(units):
        var unit = units[index].copy()
        var composed: Optional[Int] = None
        var source_end = unit._source_end
        if unit._count == 2:
            composed = _base_compatibility_composition(unit._first, unit._second)
        elif (
            unit._count == 1 and index + 1 < len(units) and units[index + 1]._count == 1
        ):
            composed = _base_compatibility_composition(
                unit._first, units[index + 1]._first
            )
            if composed:
                source_end = units[index + 1]._source_end
                index += 1

        if composed:
            _append_mapped(
                chr(composed.value()),
                unit._source_start,
                source_end,
                output,
                mappings,
                output_cursor,
            )
        else:
            var source_grapheme = StringSlice(owned_source)[
                byte = unit._source_start : unit._source_end
            ]
            _append_mapped(
                _base_normalized_grapheme(
                    source_grapheme,
                    unit._first,
                    unit._second,
                    unit._count,
                ),
                unit._source_start,
                unit._source_end,
                output,
                mappings,
                output_cursor,
            )
        index += 1
    return PhoneticRepresentation(owned_source^, output^, mappings^)


def _remap_to_original(
    source: StringSlice,
    normalized: PhoneticRepresentation,
    transformed: PhoneticRepresentation,
) raises -> PhoneticRepresentation:
    var normalized_mappings = normalized.mapping_snapshot()
    var transformed_mappings = transformed.mapping_snapshot()
    var output_mappings = List[SourceMapping](capacity=len(transformed_mappings))
    var normalized_index = 0
    for index in range(len(transformed_mappings)):
        var mapping = transformed_mappings[index].copy()
        if not mapping.has_source():
            output_mappings.append(
                SourceMapping.unmapped(mapping.output_start(), mapping.output_end())
            )
            continue
        while (
            normalized_index < len(normalized_mappings)
            and normalized_mappings[normalized_index].output_end()
            <= mapping.source_start()
        ):
            normalized_index += 1
        debug_assert(normalized_index < len(normalized_mappings))
        var source_start = normalized_mappings[normalized_index].source_start()
        var source_end = normalized_mappings[normalized_index].source_end()
        var scan = normalized_index + 1
        while (
            scan < len(normalized_mappings)
            and normalized_mappings[scan].output_start() < mapping.source_end()
        ):
            source_end = normalized_mappings[scan].source_end()
            scan += 1
        if len(output_mappings) > 0:
            var previous = output_mappings[len(output_mappings) - 1].copy()
            if (
                previous.has_source()
                and previous.output_end() == mapping.output_start()
                and previous.source_start() == source_start
                and previous.source_end() == source_end
            ):
                output_mappings[len(output_mappings) - 1] = SourceMapping(
                    previous.output_start(),
                    mapping.output_end(),
                    source_start,
                    source_end,
                )
                continue
        output_mappings.append(
            SourceMapping(
                mapping.output_start(),
                mapping.output_end(),
                source_start,
                source_end,
            )
        )
    return PhoneticRepresentation(String(source), transformed.text(), output_mappings^)


def _romanize_key(
    source: StringSlice, key: PhoneticRepresentation
) raises -> PhoneticRepresentation:
    var romanized = to_romaji(key._text)
    return _remap_to_original(source, key, romanized)


def japanese_romaji_key(source: StringSlice) raises -> PhoneticRepresentation:
    """Build the romaji companion of `japanese_kana_key` with exact mapping."""
    var key = japanese_kana_key(source)
    return _romanize_key(source, key)


def _all_ascii(text: StringSlice) -> Bool:
    for scalar in text.codepoints():
        if scalar.to_u32() >= 128:
            return False
    return True


def _starts_with_at(text: StringSlice, index: Int, token: StringSlice) -> Bool:
    var end = index + token.byte_length()
    if end > text.byte_length():
        return False
    return text[byte=index:end] == token


def _kana_for_token(token: StringSlice) -> String:
    if token == "a":
        return "あ"
    if token == "i":
        return "い"
    if token == "u":
        return "う"
    if token == "e":
        return "え"
    if token == "o":
        return "お"
    if token == "la" or token == "xa":
        return "ぁ"
    if token == "li" or token == "xi":
        return "ぃ"
    if token == "lu" or token == "xu":
        return "ぅ"
    if token == "le" or token == "xe" or token == "lye" or token == "xye":
        return "ぇ"
    if token == "lo" or token == "xo":
        return "ぉ"
    if token == "lka" or token == "xka":
        return "ゕ"
    if token == "lke" or token == "xke":
        return "ゖ"
    if token == "ka" or token == "ca":
        return "か"
    if token == "ki":
        return "き"
    if token == "ku" or token == "cu":
        return "く"
    if token == "ke":
        return "け"
    if token == "ko" or token == "co":
        return "こ"
    if token == "kya":
        return "きゃ"
    if token == "kyu":
        return "きゅ"
    if token == "kyo":
        return "きょ"
    if token == "sa":
        return "さ"
    if token == "shi" or token == "si" or token == "ci":
        return "し"
    if token == "su":
        return "す"
    if token == "se" or token == "ce":
        return "せ"
    if token == "so":
        return "そ"
    if token == "sha" or token == "sya":
        return "しゃ"
    if token == "shu" or token == "syu":
        return "しゅ"
    if token == "sho" or token == "syo":
        return "しょ"
    if token == "ta":
        return "た"
    if token == "chi" or token == "ti":
        return "ち"
    if token == "tsu" or token == "tu":
        return "つ"
    if token == "ltsu" or token == "xtsu" or token == "ltu" or token == "xtu":
        return "っ"
    if token == "te":
        return "て"
    if token == "to":
        return "と"
    if token == "cha" or token == "cya" or token == "tya":
        return "ちゃ"
    if token == "chu" or token == "cyu" or token == "tyu":
        return "ちゅ"
    if token == "cho" or token == "cyo" or token == "tyo":
        return "ちょ"
    if token == "na":
        return "な"
    if token == "ni":
        return "に"
    if token == "nu":
        return "ぬ"
    if token == "ne":
        return "ね"
    if token == "no":
        return "の"
    if token == "nya":
        return "にゃ"
    if token == "nyu":
        return "にゅ"
    if token == "nyo":
        return "にょ"
    if token == "ha":
        return "は"
    if token == "hi":
        return "ひ"
    if token == "fu" or token == "hu":
        return "ふ"
    if token == "he":
        return "へ"
    if token == "ho":
        return "ほ"
    if token == "hya":
        return "ひゃ"
    if token == "hyu":
        return "ひゅ"
    if token == "hyo":
        return "ひょ"
    if token == "ma":
        return "ま"
    if token == "mi":
        return "み"
    if token == "mu":
        return "む"
    if token == "me":
        return "め"
    if token == "mo":
        return "も"
    if token == "mya":
        return "みゃ"
    if token == "myu":
        return "みゅ"
    if token == "myo":
        return "みょ"
    if token == "ya":
        return "や"
    if token == "yu":
        return "ゆ"
    if token == "yo":
        return "よ"
    if token == "lya" or token == "xya":
        return "ゃ"
    if token == "lyu" or token == "xyu":
        return "ゅ"
    if token == "lyo" or token == "xyo":
        return "ょ"
    if token == "ra":
        return "ら"
    if token == "ri":
        return "り"
    if token == "ru":
        return "る"
    if token == "re":
        return "れ"
    if token == "ro":
        return "ろ"
    if token == "rya":
        return "りゃ"
    if token == "ryu":
        return "りゅ"
    if token == "ryo":
        return "りょ"
    if token == "wa":
        return "わ"
    if token == "wo":
        return "を"
    if token == "lwa" or token == "xwa":
        return "ゎ"
    if token == "xn":
        return "ん"
    if token == "ga":
        return "が"
    if token == "gi":
        return "ぎ"
    if token == "gu":
        return "ぐ"
    if token == "ge":
        return "げ"
    if token == "go":
        return "ご"
    if token == "gya":
        return "ぎゃ"
    if token == "gyu":
        return "ぎゅ"
    if token == "gyo":
        return "ぎょ"
    if token == "za":
        return "ざ"
    if token == "ji" or token == "zi":
        return "じ"
    if token == "zu":
        return "ず"
    if token == "ze":
        return "ぜ"
    if token == "zo":
        return "ぞ"
    if token == "ja" or token == "jya" or token == "zya":
        return "じゃ"
    if token == "ju" or token == "jyu" or token == "zyu":
        return "じゅ"
    if token == "jo" or token == "jyo" or token == "zyo":
        return "じょ"
    if token == "da":
        return "だ"
    if token == "di":
        return "ぢ"
    if token == "du":
        return "づ"
    if token == "de":
        return "で"
    if token == "do":
        return "ど"
    if token == "dya":
        return "ぢゃ"
    if token == "dyu":
        return "ぢゅ"
    if token == "dyo":
        return "ぢょ"
    if token == "ba":
        return "ば"
    if token == "bi":
        return "び"
    if token == "bu":
        return "ぶ"
    if token == "be":
        return "べ"
    if token == "bo":
        return "ぼ"
    if token == "bya":
        return "びゃ"
    if token == "byu":
        return "びゅ"
    if token == "byo":
        return "びょ"
    if token == "pa":
        return "ぱ"
    if token == "pi":
        return "ぴ"
    if token == "pu":
        return "ぷ"
    if token == "pe":
        return "ぺ"
    if token == "po":
        return "ぽ"
    if token == "pya":
        return "ぴゃ"
    if token == "pyu":
        return "ぴゅ"
    if token == "pyo":
        return "ぴょ"
    return String()


def _has_kana_token_at(text: StringSlice, index: Int) -> Bool:
    for length in [4, 3, 2, 1]:
        if index + length <= text.byte_length():
            var value = _kana_for_token(text[byte = index : index + length])
            if value.byte_length() > 0:
                return True
    return False


def _is_ascii_consonant(value: Int) -> Bool:
    return (
        value >= 0x61
        and value <= 0x7A
        and value != 0x61
        and value != 0x65
        and value != 0x69
        and value != 0x6F
        and value != 0x75
    )


def _append_query_piece(
    value: StringSlice,
    input_start: Int,
    input_end: Int,
    mut output: String,
    mut mappings: List[SourceMapping],
    mut output_cursor: Int,
) raises:
    _append_mapped(
        value,
        input_start,
        input_end,
        output,
        mappings,
        output_cursor,
    )


def japanese_query_kana(source: StringSlice) raises -> PhoneticRepresentation:
    """Canonicalize one native-kana or common IME-style query to hiragana.

    The parser accepts the canonical table plus common aliases such as `zyu`,
    `nn`/`xn`, small-kana `l`/`x` forms, and doubled consonants. Unsupported
    ASCII passes through, making this a total deterministic transformation.
    """
    var normalized = japanese_kana_key(source)
    var normalized_text = normalized.text()
    if not _all_ascii(normalized_text):
        return normalized^

    var output = String()
    var mappings = List[SourceMapping](capacity=normalized.mapping_count())
    var output_cursor = 0
    var index = 0
    var text = StringSlice(normalized_text)
    while index < text.byte_length():
        var current = ord(text[byte=index])
        if current == 0x6E:
            if _starts_with_at(text, index, "n'"):
                _append_query_piece(
                    "ん", index, index + 2, output, mappings, output_cursor
                )
                index += 2
                continue
            if _starts_with_at(text, index, "nn"):
                _append_query_piece(
                    "ん", index, index + 2, output, mappings, output_cursor
                )
                index += 2
                continue
            if index + 1 == text.byte_length():
                _append_query_piece(
                    "ん", index, index + 1, output, mappings, output_cursor
                )
                index += 1
                continue
            var following = ord(text[byte=index + 1])
            if (
                following != 0x61
                and following != 0x65
                and following != 0x69
                and following != 0x6F
                and following != 0x75
                and following != 0x79
            ):
                _append_query_piece(
                    "ん", index, index + 1, output, mappings, output_cursor
                )
                index += 1
                continue

        if (
            index + 1 < text.byte_length()
            and current == ord(text[byte=index + 1])
            and current != 0x6E
            and _is_ascii_consonant(current)
            and _has_kana_token_at(text, index + 1)
        ):
            _append_query_piece("っ", index, index + 1, output, mappings, output_cursor)
            index += 1
            continue

        var matched = False
        for length in [4, 3, 2, 1]:
            if index + length > text.byte_length():
                continue
            var kana = _kana_for_token(text[byte = index : index + length])
            if kana.byte_length() == 0:
                continue
            _append_query_piece(
                kana,
                index,
                index + length,
                output,
                mappings,
                output_cursor,
            )
            index += length
            matched = True
            break
        if matched:
            continue
        _append_query_piece(
            text[byte = index : index + 1],
            index,
            index + 1,
            output,
            mappings,
            output_cursor,
        )
        index += 1

    var parsed = PhoneticRepresentation(normalized_text^, output^, mappings^)
    return _remap_to_original(source, normalized, parsed)


struct _QueryState(Copyable):
    var _index: Int
    var _output: String
    var _mappings: List[SourceMapping]

    def __init__(
        out self,
        index: Int,
        var output: String,
        var mappings: List[SourceMapping],
    ):
        self._index = index
        self._output = output^
        self._mappings = mappings^


def _identity_representation(source: StringSlice) raises -> PhoneticRepresentation:
    var owned = String(source)
    var mappings = List[SourceMapping](capacity=source.byte_length())
    var cursor = 0
    for scalar in StringSlice(owned).codepoint_slices():
        var end = cursor + scalar.byte_length()
        mappings.append(SourceMapping(cursor, end, cursor, end))
        cursor = end
    return PhoneticRepresentation(owned.copy(), owned^, mappings^)


def _contains_hiragana(text: StringSlice) -> Bool:
    for scalar in text.codepoints():
        var value = Int(scalar.to_u32())
        if value >= 0x3041 and value <= 0x3096:
            return True
    return False


def _push_unique_query_key(
    mut output: List[SearchKey],
    kind: SearchKeyKind,
    var value: PhoneticRepresentation,
    max_count: Int,
):
    if len(output) >= max_count:
        return
    for index in range(len(output)):
        if output[index].kind() == kind and output[index].has_representation_text(
            value
        ):
            return
    output.append(SearchKey(kind, value^))


def _is_ascii_query_space(value: Int) -> Bool:
    return (
        value == 0x20
        or value == 0x09
        or value == 0x0A
        or value == 0x0B
        or value == 0x0C
        or value == 0x0D
    )


def _trim_ascii_query(
    normalized: PhoneticRepresentation,
) raises -> PhoneticRepresentation:
    var text = normalized.text()
    var bytes = text.as_bytes()
    var start = 0
    var end = text.byte_length()
    # Only ASCII bytes can be whitespace here. Inspect bytes without decoding
    # a scalar at end - 1, which can be a UTF-8 continuation byte.
    while start < end and _is_ascii_query_space(Int(bytes[start])):
        start += 1
    while end > start and _is_ascii_query_space(Int(bytes[end - 1])):
        end -= 1
    if start == 0 and end == text.byte_length():
        return normalized.copy()

    var mappings = normalized.mapping_snapshot()
    var trimmed_mappings = List[SourceMapping]()
    for index in range(len(mappings)):
        var mapping = mappings[index].copy()
        if mapping.output_end() <= start:
            continue
        if mapping.output_start() >= end:
            break
        var output_start = max(mapping.output_start(), start) - start
        var output_end = min(mapping.output_end(), end) - start
        if mapping.has_source():
            trimmed_mappings.append(
                SourceMapping(
                    output_start,
                    output_end,
                    mapping.source_start(),
                    mapping.source_end(),
                )
            )
        else:
            trimmed_mappings.append(SourceMapping.unmapped(output_start, output_end))
    return PhoneticRepresentation(
        normalized.source_text(),
        String(StringSlice(text)[byte=start:end]),
        trimmed_mappings^,
    )


def _ascii_alphabetic(value: Int) -> Bool:
    return (value >= 0x41 and value <= 0x5A) or (value >= 0x61 and value <= 0x7A)


def _number_romaji(value: Int) -> String:
    debug_assert(value >= 1 and value <= 9999)
    var output = String()
    var thousands = value // 1000
    var hundreds = (value // 100) % 10
    var tens = (value // 10) % 10
    var ones = value % 10
    if thousands > 0:
        if thousands > 1:
            _append_digit_romaji(thousands, output)
        output += "sen"
    if hundreds > 0:
        if hundreds > 1:
            _append_digit_romaji(hundreds, output)
        output += "hyaku"
    if tens > 0:
        if tens > 1:
            _append_digit_romaji(tens, output)
        output += "juu"
    _append_digit_romaji(ones, output)
    return output^


def _append_digit_romaji(value: Int, mut output: String):
    if value == 1:
        output += "ichi"
    elif value == 2:
        output += "ni"
    elif value == 3:
        output += "san"
    elif value == 4:
        output += "yon"
    elif value == 5:
        output += "go"
    elif value == 6:
        output += "roku"
    elif value == 7:
        output += "nana"
    elif value == 8:
        output += "hachi"
    elif value == 9:
        output += "kyuu"


def _numeric_romaji_query(
    text: StringSlice,
) raises -> Optional[PhoneticRepresentation]:
    var has_ascii_alphabetic = False
    for scalar in text.codepoints():
        if _ascii_alphabetic(Int(scalar.to_u32())):
            has_ascii_alphabetic = True
            break
    if not has_ascii_alphabetic:
        return None

    var output = String()
    var mappings = List[SourceMapping]()
    var output_cursor = 0
    var changed = False
    var index = 0
    while index < text.byte_length():
        var first_digit = _digit_value(ord(text[byte=index]))
        if first_digit >= 0:
            var value = first_digit
            var digit_count = 1
            var scan = index + 1
            while scan < text.byte_length():
                var current = ord(text[byte=scan])
                var digit = _digit_value(current)
                if digit >= 0:
                    digit_count += 1
                    if value <= 9999:
                        value = value * 10 + digit
                    scan += 1
                    continue
                if current == 0x2C or current == 0x5F:
                    scan += 1
                    continue
                break
            var valid = (
                value >= 1
                and value <= 9999
                and not (digit_count > 1 and first_digit == 0)
            )
            if valid:
                _append_mapped(
                    _number_romaji(value),
                    index,
                    scan,
                    output,
                    mappings,
                    output_cursor,
                )
                changed = True
                index = scan
                continue

        var next = index + 1
        for scalar in text[byte=index:].codepoint_slices():
            next = index + scalar.byte_length()
            break
        _append_mapped(
            text[byte=index:next],
            index,
            next,
            output,
            mappings,
            output_cursor,
        )
        index = next
    if not changed:
        return None
    return PhoneticRepresentation(String(text), output^, mappings^)


def _advanced_query_state(
    state: _QueryState,
    next_index: Int,
    value: StringSlice,
    source_start: Int,
    source_end: Int,
) raises -> _QueryState:
    var output = state._output.copy()
    var mappings = state._mappings.copy()
    var output_cursor = output.byte_length()
    _append_mapped(
        value,
        source_start,
        source_end,
        output,
        mappings,
        output_cursor,
    )
    return _QueryState(next_index, output^, mappings^)


def _enqueue_query_piece(
    state: _QueryState,
    next_index: Int,
    value: StringSlice,
    source_start: Int,
    source_end: Int,
    mut queue: List[_QueryState],
) raises:
    queue.append(
        _advanced_query_state(
            state,
            next_index,
            value,
            source_start,
            source_end,
        )
    )


def _expand_ambiguous_romaji_queries(
    source: StringSlice,
    normalized: PhoneticRepresentation,
    max_count: Int,
    mut output: List[SearchKey],
) raises:
    if len(output) >= max_count:
        return
    var normalized_text = normalized.text()
    if normalized_text.byte_length() == 0 or not _all_ascii(normalized_text):
        return

    var queue = List[_QueryState]()
    queue.append(_QueryState(0, String(), List[SourceMapping]()))
    var queue_index = 0
    var steps = 0
    var search_budget = max(16, max_count * 16)
    var text = StringSlice(normalized_text)
    while queue_index < len(queue) and steps < search_budget:
        var state = queue[queue_index].copy()
        queue_index += 1
        steps += 1
        if state._index >= text.byte_length():
            if not _contains_hiragana(state._output):
                continue
            var parsed = PhoneticRepresentation(
                normalized_text.copy(),
                state._output.copy(),
                state._mappings.copy(),
            )
            _push_unique_query_key(
                output,
                SearchKeyKind.QUERY_JAPANESE_ROMAJI_TO_KANA,
                _remap_to_original(source, normalized, parsed),
                max_count,
            )
            if len(output) >= max_count:
                return
            continue

        var index = state._index
        var current = ord(text[byte=index])
        if current == 0x6E:
            if _starts_with_at(text, index, "n'"):
                _enqueue_query_piece(state, index + 2, "ん", index, index + 2, queue)
                continue
            if index + 1 == text.byte_length():
                _enqueue_query_piece(state, index + 1, "ん", index, index + 1, queue)
                continue
            var following = ord(text[byte=index + 1])
            if following == 0x6E:
                _enqueue_query_piece(state, index + 1, "ん", index, index + 1, queue)
                _enqueue_query_piece(state, index + 2, "ん", index, index + 2, queue)
                continue
            if (
                following != 0x61
                and following != 0x65
                and following != 0x69
                and following != 0x6F
                and following != 0x75
            ):
                _enqueue_query_piece(state, index + 1, "ん", index, index + 1, queue)
                if following != 0x79:
                    continue

        if (
            index + 1 < text.byte_length()
            and current == ord(text[byte=index + 1])
            and current != 0x6E
            and _is_ascii_consonant(current)
            and _has_kana_token_at(text, index + 1)
        ):
            _enqueue_query_piece(state, index + 1, "っ", index, index + 1, queue)
            continue

        var matched = False
        for length in [4, 3, 2, 1]:
            if index + length > text.byte_length():
                continue
            var kana = _kana_for_token(text[byte = index : index + length])
            if kana.byte_length() == 0:
                continue
            _enqueue_query_piece(
                state,
                index + length,
                kana,
                index,
                index + length,
                queue,
            )
            matched = True
            break
        if matched:
            continue
        _enqueue_query_piece(
            state,
            index + 1,
            text[byte = index : index + 1],
            index,
            index + 1,
            queue,
        )


def _long_vowel_representation(
    normalized_text: StringSlice,
    variant: Int,
) raises -> PhoneticRepresentation:
    var output = String()
    var mappings = List[SourceMapping]()
    var cursor = 0
    if variant == 0:
        _append_mapped("とう", 0, 2, output, mappings, cursor)
        _append_mapped("きょう", 2, 5, output, mappings, cursor)
    elif variant == 1:
        _append_mapped("きょう", 0, 3, output, mappings, cursor)
        _append_mapped("と", 3, 5, output, mappings, cursor)
    elif variant == 2:
        _append_mapped("おお", 0, 1, output, mappings, cursor)
        _append_mapped("さ", 1, 3, output, mappings, cursor)
        _append_mapped("か", 3, 5, output, mappings, cursor)
    else:
        debug_assert(variant == 3)
        _append_mapped("こう", 0, 2, output, mappings, cursor)
        _append_mapped("べ", 2, 4, output, mappings, cursor)
    return PhoneticRepresentation(String(normalized_text), output^, mappings^)


def _repeated_o_representation(
    normalized_text: StringSlice,
    piece: StringSlice,
) raises -> PhoneticRepresentation:
    var output = String()
    var mappings = List[SourceMapping]()
    var cursor = 0
    for index in range(normalized_text.byte_length()):
        _append_mapped(piece, index, index + 1, output, mappings, cursor)
    return PhoneticRepresentation(String(normalized_text), output^, mappings^)


def _append_long_vowel_queries(
    source: StringSlice,
    normalized: PhoneticRepresentation,
    max_count: Int,
    mut output: List[SearchKey],
) raises:
    if len(output) >= max_count:
        return
    var text = normalized.text()
    var variant = -1
    if text == "tokyo":
        variant = 0
    elif text == "kyoto":
        variant = 1
    elif text == "osaka":
        variant = 2
    elif text == "kobe":
        variant = 3
    if variant >= 0:
        _push_unique_query_key(
            output,
            SearchKeyKind.QUERY_JAPANESE_ROMAJI_TO_KANA,
            _remap_to_original(
                source,
                normalized,
                _long_vowel_representation(text, variant),
            ),
            max_count,
        )
        return

    if text.byte_length() <= 1:
        return
    for index in range(text.byte_length()):
        if ord(text[byte=index]) != 0x6F:
            return
    for piece in ["おう", "おー", "おおう"]:
        if len(output) >= max_count:
            return
        _push_unique_query_key(
            output,
            SearchKeyKind.QUERY_JAPANESE_ROMAJI_TO_KANA,
            _remap_to_original(
                source,
                normalized,
                _repeated_o_representation(text, piece),
            ),
            max_count,
        )


def japanese_query_keys(
    source: StringSlice,
    max_count: Int = 8,
) raises -> SearchKeyBundle:
    """Expand one Japanese query into typed variants, capped at eight.

    The result starts with the literal query, adds compatibility-normalized
    coverage when needed, and then emits native-kana or bounded IME-romaji
    alternatives. Ambiguous `n` before `y` and reviewed long-vowel guesses
    follow Yuru's ordering. Duplicate kind/text pairs are removed.
    """
    if max_count < 0 or max_count > 8:
        raise Error(
            "max_count must be within [0, 8] for Japanese query keys; got "
            + String(max_count)
        )
    var output = List[SearchKey](capacity=max_count)
    if max_count == 0:
        return SearchKeyBundle(output^, max_count)

    _push_unique_query_key(
        output,
        SearchKeyKind.QUERY_ORIGINAL,
        _identity_representation(source),
        max_count,
    )
    var normalized = japanese_kana_key(source)
    if normalized.text() != source:
        _push_unique_query_key(
            output,
            SearchKeyKind.QUERY_NORMALIZED,
            normalized.copy(),
            max_count,
        )
    if _contains_hiragana(normalized._text):
        _push_unique_query_key(
            output,
            SearchKeyKind.QUERY_JAPANESE_KANA,
            normalized.copy(),
            max_count,
        )
    var parser_input = _trim_ascii_query(normalized)
    var parser_text = parser_input.text()
    var numeric = _numeric_romaji_query(StringSlice(parser_text))
    if numeric:
        var remapped_numeric = _remap_to_original(source, parser_input, numeric.value())
        _expand_ambiguous_romaji_queries(source, remapped_numeric, max_count, output)
    _expand_ambiguous_romaji_queries(source, parser_input, max_count, output)
    _append_long_vowel_queries(source, parser_input, max_count, output)
    return SearchKeyBundle(output^, max_count)


def _mapping_scalar(text: StringSlice, mapping: SourceMapping) -> Int:
    var value = -1
    var count = 0
    for scalar in text[
        byte = mapping.output_start() : mapping.output_end()
    ].codepoints():
        value = Int(scalar.to_u32())
        count += 1
    if count != 1:
        return -1
    return value


def _digit_value(value: Int) -> Int:
    if value >= 0x30 and value <= 0x39:
        return value - 0x30
    return -1


def _is_number_separator(value: Int) -> Bool:
    return value == 0x2C or value == 0x5F


def _append_thousands(value: Int, mut output: String):
    if value == 1:
        output += "せん"
    elif value == 2:
        output += "にせん"
    elif value == 3:
        output += "さんぜん"
    elif value == 4:
        output += "よんせん"
    elif value == 5:
        output += "ごせん"
    elif value == 6:
        output += "ろくせん"
    elif value == 7:
        output += "ななせん"
    elif value == 8:
        output += "はっせん"
    elif value == 9:
        output += "きゅうせん"


def _append_hundreds(value: Int, mut output: String):
    if value == 1:
        output += "ひゃく"
    elif value == 2:
        output += "にひゃく"
    elif value == 3:
        output += "さんびゃく"
    elif value == 4:
        output += "よんひゃく"
    elif value == 5:
        output += "ごひゃく"
    elif value == 6:
        output += "ろっぴゃく"
    elif value == 7:
        output += "ななひゃく"
    elif value == 8:
        output += "はっぴゃく"
    elif value == 9:
        output += "きゅうひゃく"


def _append_digit(value: Int, mut output: String):
    if value == 1:
        output += "いち"
    elif value == 2:
        output += "に"
    elif value == 3:
        output += "さん"
    elif value == 4:
        output += "よん"
    elif value == 5:
        output += "ご"
    elif value == 6:
        output += "ろく"
    elif value == 7:
        output += "なな"
    elif value == 8:
        output += "はち"
    elif value == 9:
        output += "きゅう"


def _number_kana(value: Int) -> String:
    debug_assert(value >= 1 and value <= 9999)
    var output = String()
    _append_thousands(value // 1000, output)
    _append_hundreds((value // 100) % 10, output)
    var tens = (value // 10) % 10
    if tens == 1:
        output += "じゅう"
    elif tens > 1:
        _append_digit(tens, output)
        output += "じゅう"
    _append_digit(value % 10, output)
    return output^


def _date_suffix_kana(value: Int) -> String:
    if value == 0x5E74:
        return "ねん"
    if value == 0x6708:
        return "がつ"
    return String()


def _has_numeric_date_context(base: PhoneticRepresentation) -> Bool:
    var text = StringSlice(base._text)
    var index = 0
    while index < len(base._mappings):
        var first_digit = _digit_value(_mapping_scalar(text, base._mappings[index]))
        if first_digit < 0:
            index += 1
            continue
        var value = 0
        var digit_count = 0
        var scan = index
        while scan < len(base._mappings):
            var scalar = _mapping_scalar(text, base._mappings[scan])
            var digit = _digit_value(scalar)
            if digit >= 0:
                digit_count += 1
                if value <= 9999:
                    value = value * 10 + digit
                scan += 1
                continue
            if (
                _is_number_separator(scalar)
                and scan + 1 < len(base._mappings)
                and _digit_value(_mapping_scalar(text, base._mappings[scan + 1])) >= 0
            ):
                scan += 1
                continue
            break
        if (
            scan < len(base._mappings)
            and _date_suffix_kana(
                _mapping_scalar(text, base._mappings[scan])
            ).byte_length()
            > 0
            and value >= 1
            and value <= 9999
            and not (digit_count > 1 and first_digit == 0)
        ):
            return True
        index += 1
    return False


def _append_base_mapping(
    text: StringSlice,
    mapping: SourceMapping,
    mut output: String,
    mut output_mappings: List[SourceMapping],
    mut output_cursor: Int,
) raises:
    _append_mapped(
        text[byte = mapping.output_start() : mapping.output_end()],
        mapping.source_start(),
        mapping.source_end(),
        output,
        output_mappings,
        output_cursor,
    )


def _numeric_date_key(
    source: StringSlice,
    base: PhoneticRepresentation,
    read_digits: Bool,
) raises -> PhoneticRepresentation:
    var text_slice = StringSlice(base._text)
    var mappings = base.mapping_snapshot()
    var output = String()
    var output_mappings = List[SourceMapping](capacity=len(mappings))
    var output_cursor = 0
    var index = 0
    while index < len(mappings):
        var first_digit = _digit_value(_mapping_scalar(text_slice, mappings[index]))
        if first_digit < 0:
            _append_base_mapping(
                text_slice,
                mappings[index],
                output,
                output_mappings,
                output_cursor,
            )
            index += 1
            continue

        var digit_indices = List[Int]()
        var value = 0
        var scan = index
        while scan < len(mappings):
            var scalar = _mapping_scalar(text_slice, mappings[scan])
            var digit = _digit_value(scalar)
            if digit >= 0:
                digit_indices.append(scan)
                if value <= 9999:
                    value = value * 10 + digit
                scan += 1
                continue
            if (
                _is_number_separator(scalar)
                and scan + 1 < len(mappings)
                and _digit_value(_mapping_scalar(text_slice, mappings[scan + 1])) >= 0
            ):
                scan += 1
                continue
            break

        var suffix = String()
        if scan < len(mappings):
            suffix = _date_suffix_kana(_mapping_scalar(text_slice, mappings[scan]))
        var valid_number = (
            suffix.byte_length() > 0
            and value >= 1
            and value <= 9999
            and not (len(digit_indices) > 1 and first_digit == 0)
        )
        if not valid_number:
            _append_base_mapping(
                text_slice,
                mappings[index],
                output,
                output_mappings,
                output_cursor,
            )
            index += 1
            continue

        if read_digits:
            var number = _number_kana(value)
            _append_mapped(
                number,
                mappings[digit_indices[0]].source_start(),
                mappings[digit_indices[len(digit_indices) - 1]].source_end(),
                output,
                output_mappings,
                output_cursor,
            )
        else:
            for digit_index in range(len(digit_indices)):
                _append_base_mapping(
                    text_slice,
                    mappings[digit_indices[digit_index]],
                    output,
                    output_mappings,
                    output_cursor,
                )
        _append_mapped(
            suffix,
            mappings[scan].source_start(),
            mappings[scan].source_end(),
            output,
            output_mappings,
            output_cursor,
        )
        index = scan + 1

    return PhoneticRepresentation(String(source), output^, output_mappings^)


def _push_unique_candidate_key(
    mut output: List[SearchKey],
    kind: SearchKeyKind,
    var value: PhoneticRepresentation,
    max_count: Int,
):
    if len(output) >= max_count:
        return
    for index in range(len(output)):
        if output[index].has_representation_text(value):
            return
    output.append(SearchKey(kind, value^))


def japanese_search_keys(
    source: StringSlice,
    max_count: Int = 6,
) raises -> SearchKeyBundle:
    """Build typed Japanese candidate keys under a strict six-key cap.

    Kinds are explicit so downstream search can apply compatibility gates
    without inferring semantics from list position. Text is deduplicated in
    first-produced order. The built-in bundle remains dictionary-free; a
    licensed Kanji-reading provider may append its own capped typed keys.
    """
    if max_count < 0 or max_count > 6:
        raise Error(
            "max_count must be within [0, 6] for Japanese candidate keys; got "
            + String(max_count)
        )
    var output = List[SearchKey](capacity=max_count)
    if max_count == 0:
        return SearchKeyBundle(output^, max_count)

    var base = japanese_kana_key(source)
    _push_unique_candidate_key(
        output, SearchKeyKind.JAPANESE_KANA, base.copy(), max_count
    )
    _push_unique_candidate_key(
        output,
        SearchKeyKind.JAPANESE_ROMAJI,
        _romanize_key(source, base),
        max_count,
    )
    if not _has_numeric_date_context(base):
        return SearchKeyBundle(output^, max_count)

    var full_numeric = _numeric_date_key(source, base, True)
    _push_unique_candidate_key(
        output,
        SearchKeyKind.JAPANESE_KANA,
        full_numeric.copy(),
        max_count,
    )
    _push_unique_candidate_key(
        output,
        SearchKeyKind.JAPANESE_ROMAJI,
        _romanize_key(source, full_numeric),
        max_count,
    )

    var compact_numeric = _numeric_date_key(source, base, False)
    _push_unique_candidate_key(
        output,
        SearchKeyKind.JAPANESE_KANA,
        compact_numeric.copy(),
        max_count,
    )
    _push_unique_candidate_key(
        output,
        SearchKeyKind.JAPANESE_ROMAJI,
        _romanize_key(source, compact_numeric),
        max_count,
    )
    return SearchKeyBundle(output^, max_count)


def japanese_candidate_keys(
    source: StringSlice,
    max_count: Int = 8,
    max_total_key_bytes: Int = 1024,
) raises -> SearchKeyBundle:
    """Build one complete base-plus-Japanese candidate bundle.

    The literal and documented-subset normalized base keys are first and are
    retained like Yuru's required base keys. Generated kana/romaji keys then
    share the total count and byte budgets. `max_count` is zero or within
    `[2, 8]`; a nonempty bundle always contains both base kinds.
    """
    if max_count < 0 or max_count == 1 or max_count > 8:
        raise Error(
            "max_count must be zero or within [2, 8] for unified Japanese "
            "candidate keys; got "
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

    output.append(SearchKey(SearchKeyKind.ORIGINAL, _identity_representation(source)))
    output.append(SearchKey(SearchKeyKind.NORMALIZED, _japanese_normalized_key(source)))
    if len(output) >= max_count or max_total_key_bytes == 0:
        return SearchKeyBundle(output^, max_count)
    # Required base keys do not consume the generated-key byte budget. This
    # mirrors Yuru's index policy and keeps phonetic keys available for long
    # original labels when their own generated representation still fits.
    var generated_bytes = 0
    var generated_bundle = japanese_search_keys(source, min(6, max_count - 2))
    var generated = generated_bundle^.take_keys()
    while len(generated) > 0:
        if len(output) >= max_count:
            break
        var key = generated.pop(0)
        var duplicate = False
        for existing_index in range(len(output)):
            if output[existing_index].kind() == key.kind() and output[
                existing_index
            ].has_same_text(key):
                duplicate = True
                break
        if duplicate:
            continue
        var key_bytes = key.text_byte_length()
        if generated_bytes + key_bytes > max_total_key_bytes:
            continue
        generated_bytes += key_bytes
        output.append(key^)
    return SearchKeyBundle(output^, max_count)


def japanese_search_representations(
    source: StringSlice,
) raises -> List[PhoneticRepresentation]:
    """Build the fixed Japanese candidate-key bundle in matching order.

    The result contains unique normalized kana and romaji keys, followed by
    algorithmic full-reading and compact-mixed year/month keys when Arabic
    numerals immediately precede `年` or `月`. At most six values are emitted.
    Kanji dictionary readings are intentionally provider-gated; see the
    Japanese search documentation for the provider contract.
    """
    var bundle = japanese_search_keys(source)
    var keys = bundle^.take_keys()
    var output = List[PhoneticRepresentation](capacity=len(keys))
    while len(keys) > 0:
        var key = keys.pop(0)
        output.append(key^.take_representation())
    return output^
