"""Wapuro-flavored modified Hepburn kana romanization."""

from std.collections import List, Optional

from ..representation import PhoneticRepresentation, SourceMapping
from .voicing import _compose_kana_voicing


comptime _SOKUON = 0x3063
comptime _CHOUON = 0x30FC
comptime _SYLLABIC_N = 0x3093


struct _KanaUnit(Copyable):
    var _value: Optional[Int]
    var _source_text: String
    var _source_start: Int
    var _source_end: Int

    def __init__(
        out self,
        value: Optional[Int],
        source_text: StringSlice,
        source_start: Int,
        source_end: Int,
    ):
        self._value = value.copy()
        self._source_text = String(source_text)
        self._source_start = source_start
        self._source_end = source_end


def _first_codepoint(text: StringSlice) -> Int:
    for scalar in text.codepoints():
        return Int(scalar.to_u32())
    return -1


def _fold_katakana(value: Int) -> Int:
    if value >= 0x30A1 and value <= 0x30F6:
        return value - 0x60
    if value >= 0x30FD and value <= 0x30FE:
        return value - 0x60
    return value


def _scan_kana_units(source: StringSlice) -> List[_KanaUnit]:
    var units = List[_KanaUnit]()
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

        var value: Optional[Int] = None
        if count == 1:
            value = _fold_katakana(first)
        elif count == 2:
            var composed = _compose_kana_voicing(first, second)
            if composed:
                value = _fold_katakana(composed.value())

        var source_end = source_cursor + grapheme.byte_length()
        units.append(_KanaUnit(value, grapheme, source_cursor, source_end))
        source_cursor = source_end
    return units^


def _monograph_romaji(value: Int) -> String:
    if value == 0x3041 or value == 0x3042:
        return "a"
    if value == 0x3043 or value == 0x3044:
        return "i"
    if value == 0x3045 or value == 0x3046:
        return "u"
    if value == 0x3047 or value == 0x3048:
        return "e"
    if value == 0x3049 or value == 0x304A:
        return "o"
    if value == 0x304B or value == 0x3095:
        return "ka"
    if value == 0x304D:
        return "ki"
    if value == 0x304F:
        return "ku"
    if value == 0x3051 or value == 0x3096:
        return "ke"
    if value == 0x3053:
        return "ko"
    if value == 0x3055:
        return "sa"
    if value == 0x3057:
        return "shi"
    if value == 0x3059:
        return "su"
    if value == 0x305B:
        return "se"
    if value == 0x305D:
        return "so"
    if value == 0x305F:
        return "ta"
    if value == 0x3061:
        return "chi"
    if value == 0x3064:
        return "tsu"
    if value == 0x3066:
        return "te"
    if value == 0x3068:
        return "to"
    if value == 0x306A:
        return "na"
    if value == 0x306B:
        return "ni"
    if value == 0x306C:
        return "nu"
    if value == 0x306D:
        return "ne"
    if value == 0x306E:
        return "no"
    if value == 0x306F:
        return "ha"
    if value == 0x3072:
        return "hi"
    if value == 0x3075:
        return "fu"
    if value == 0x3078:
        return "he"
    if value == 0x307B:
        return "ho"
    if value == 0x307E:
        return "ma"
    if value == 0x307F:
        return "mi"
    if value == 0x3080:
        return "mu"
    if value == 0x3081:
        return "me"
    if value == 0x3082:
        return "mo"
    if value == 0x3083 or value == 0x3084:
        return "ya"
    if value == 0x3085 or value == 0x3086:
        return "yu"
    if value == 0x3087 or value == 0x3088:
        return "yo"
    if value == 0x3089:
        return "ra"
    if value == 0x308A:
        return "ri"
    if value == 0x308B:
        return "ru"
    if value == 0x308C:
        return "re"
    if value == 0x308D:
        return "ro"
    if value == 0x308E or value == 0x308F:
        return "wa"
    if value == 0x3090:
        return "wi"
    if value == 0x3091:
        return "we"
    if value == 0x3092:
        return "o"
    if value == 0x304C:
        return "ga"
    if value == 0x304E:
        return "gi"
    if value == 0x3050:
        return "gu"
    if value == 0x3052:
        return "ge"
    if value == 0x3054:
        return "go"
    if value == 0x3056:
        return "za"
    if value == 0x3058:
        return "ji"
    if value == 0x305A:
        return "zu"
    if value == 0x305C:
        return "ze"
    if value == 0x305E:
        return "zo"
    if value == 0x3060:
        return "da"
    if value == 0x3062:
        return "ji"
    if value == 0x3065:
        return "zu"
    if value == 0x3067:
        return "de"
    if value == 0x3069:
        return "do"
    if value == 0x3070:
        return "ba"
    if value == 0x3073:
        return "bi"
    if value == 0x3076:
        return "bu"
    if value == 0x3079:
        return "be"
    if value == 0x307C:
        return "bo"
    if value == 0x3071:
        return "pa"
    if value == 0x3074:
        return "pi"
    if value == 0x3077:
        return "pu"
    if value == 0x307A:
        return "pe"
    if value == 0x307D:
        return "po"
    if value == 0x3094:
        return "vu"
    if value == _SYLLABIC_N:
        return "n"
    return String()


def _yoon_romaji(base: Int, small: Int) -> String:
    if small != 0x3083 and small != 0x3085 and small != 0x3087:
        return String()

    var stem: String
    if base == 0x304D:
        stem = "ky"
    elif base == 0x3057:
        stem = "sh"
    elif base == 0x3061:
        stem = "ch"
    elif base == 0x306B:
        stem = "ny"
    elif base == 0x3072:
        stem = "hy"
    elif base == 0x307F:
        stem = "my"
    elif base == 0x308A:
        stem = "ry"
    elif base == 0x304E:
        stem = "gy"
    elif base == 0x3058 or base == 0x3062:
        stem = "j"
    elif base == 0x3073:
        stem = "by"
    elif base == 0x3074:
        stem = "py"
    else:
        return String()

    if small == 0x3083:
        stem += "a"
    elif small == 0x3085:
        stem += "u"
    else:
        stem += "o"
    return stem^


def _extended_romaji(base: Int, small: Int) -> String:
    if base == 0x3075:
        if small == 0x3041:
            return "fa"
        if small == 0x3043:
            return "fi"
        if small == 0x3047:
            return "fe"
        if small == 0x3049:
            return "fo"
        if small == 0x3085:
            return "fyu"
    elif base == 0x3094:
        if small == 0x3041:
            return "va"
        if small == 0x3043:
            return "vi"
        if small == 0x3047:
            return "ve"
        if small == 0x3049:
            return "vo"
        if small == 0x3085:
            return "vyu"
    elif base == 0x3066:
        if small == 0x3043:
            return "ti"
        if small == 0x3085:
            return "tyu"
    elif base == 0x3067:
        if small == 0x3043:
            return "di"
        if small == 0x3085:
            return "dyu"
    elif base == 0x3068 and small == 0x3045:
        return "tu"
    elif base == 0x3069 and small == 0x3045:
        return "du"
    elif base == 0x3046:
        if small == 0x3043:
            return "wi"
        if small == 0x3047:
            return "we"
        if small == 0x3049:
            return "wo"
    elif base == 0x3057 and small == 0x3047:
        return "she"
    elif base == 0x3058 and small == 0x3047:
        return "je"
    elif base == 0x3061 and small == 0x3047:
        return "che"
    elif base == 0x3064:
        if small == 0x3041:
            return "tsa"
        if small == 0x3043:
            return "tsi"
        if small == 0x3047:
            return "tse"
        if small == 0x3049:
            return "tso"
    elif base == 0x3044 and small == 0x3047:
        return "ye"
    return String()


def _digraph_romaji(base: Int, small: Int) -> String:
    var yoon = _yoon_romaji(base, small)
    if yoon.byte_length() > 0:
        return yoon^
    return _extended_romaji(base, small)


def _unit_is(unit: _KanaUnit, value: Int) -> Bool:
    if not unit._value:
        return False
    return unit._value.value() == value


def _digraph_at(units: List[_KanaUnit], index: Int) -> String:
    if index + 1 >= len(units):
        return String()
    if not units[index]._value:
        return String()
    if not units[index + 1]._value:
        return String()
    return _digraph_romaji(units[index]._value.value(), units[index + 1]._value.value())


def _romanized_unit_at(units: List[_KanaUnit], index: Int) -> String:
    var pair = _digraph_at(units, index)
    if pair.byte_length() > 0:
        return pair^
    if units[index]._value:
        return _monograph_romaji(units[index]._value.value())
    return String()


def _first_ascii_letter(text: StringSlice) -> Int:
    for scalar in text.codepoints():
        return Int(scalar.to_u32())
    return -1


def _doubleable_initial(romaji: StringSlice) -> Optional[Int]:
    var initial = _first_ascii_letter(romaji)
    if initial < 0x61 or initial > 0x7A:
        return None
    if initial == 0x61 or initial == 0x65 or initial == 0x69:
        return None
    if initial == 0x6F or initial == 0x75 or initial == 0x6E:
        return None
    if initial == 0x63:
        return 0x74
    return initial


def _last_vowel(romaji: StringSlice) -> Optional[Int]:
    var vowel: Optional[Int] = None
    for scalar in romaji.codepoints():
        var value = Int(scalar.to_u32())
        if value == 0x61 or value == 0x65 or value == 0x69:
            vowel = value
        elif value == 0x6F or value == 0x75:
            vowel = value
    return vowel


def _is_vowel_kana(value: Int) -> Bool:
    return value >= 0x3041 and value <= 0x304A


def _needs_n_apostrophe(value: Int) -> Bool:
    if _is_vowel_kana(value):
        return True
    return value == 0x3084 or value == 0x3086 or value == 0x3088


def _unit_is_vowel_kana(unit: _KanaUnit) -> Bool:
    if not unit._value:
        return False
    return _is_vowel_kana(unit._value.value())


def _unit_needs_n_apostrophe(unit: _KanaUnit) -> Bool:
    if not unit._value:
        return False
    return _needs_n_apostrophe(unit._value.value())


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


def romanize_kana(text: StringSlice) raises -> PhoneticRepresentation:
    """Romanize kana with mixed mappings: contractions map a digraph pair or
    base-plus-combining mark to one romaji syllable, ordinary syllables map
    1:1, and unsupported grapheme clusters pass through unchanged.

    The single scheme is ASCII, wapuro-flavored modified Hepburn. Hiragana and
    full-width katakana share the same table; closed-list digraph detection is
    greedy. Sokuon, prolonged marks, and syllabic n use their documented
    context rules. No input is invalid; ``raises`` is solely the checked
    representation-construction path.
    """
    var source = String(text)
    var units = _scan_kana_units(source)
    var transformed = String()
    var mappings = List[SourceMapping]()
    var output_cursor = 0
    var last_vowel: Optional[Int] = None
    var index = 0

    while index < len(units):
        var unit = units[index].copy()
        if _unit_is(unit, _SOKUON):
            var following = index
            while following < len(units) and _unit_is(units[following], _SOKUON):
                following += 1

            var doubled: Optional[Int] = None
            if following < len(units) and not _unit_is_vowel_kana(units[following]):
                var following_romaji = _romanized_unit_at(units, following)
                doubled = _doubleable_initial(following_romaji)

            while index < following:
                var sokuon = units[index].copy()
                if doubled:
                    _append_segment(
                        chr(doubled.value()),
                        sokuon._source_start,
                        sokuon._source_end,
                        transformed,
                        mappings,
                        output_cursor,
                    )
                else:
                    _append_segment(
                        sokuon._source_text,
                        sokuon._source_start,
                        sokuon._source_end,
                        transformed,
                        mappings,
                        output_cursor,
                    )
                index += 1
            last_vowel = None
            continue

        if _unit_is(unit, _CHOUON):
            if last_vowel:
                _append_segment(
                    chr(last_vowel.value()),
                    unit._source_start,
                    unit._source_end,
                    transformed,
                    mappings,
                    output_cursor,
                )
            else:
                _append_segment(
                    unit._source_text,
                    unit._source_start,
                    unit._source_end,
                    transformed,
                    mappings,
                    output_cursor,
                )
                last_vowel = None
            index += 1
            continue

        if _unit_is(unit, _SYLLABIC_N):
            var emitted = String("n")
            if index + 1 < len(units) and _unit_needs_n_apostrophe(units[index + 1]):
                emitted = "n'"
            _append_segment(
                emitted,
                unit._source_start,
                unit._source_end,
                transformed,
                mappings,
                output_cursor,
            )
            last_vowel = None
            index += 1
            continue

        var digraph = _digraph_at(units, index)
        if digraph.byte_length() > 0:
            _append_segment(
                digraph,
                unit._source_start,
                units[index + 1]._source_end,
                transformed,
                mappings,
                output_cursor,
            )
            last_vowel = _last_vowel(digraph)
            index += 2
            continue

        var monograph = String()
        if unit._value:
            monograph = _monograph_romaji(unit._value.value())
        if monograph.byte_length() > 0:
            _append_segment(
                monograph,
                unit._source_start,
                unit._source_end,
                transformed,
                mappings,
                output_cursor,
            )
            last_vowel = _last_vowel(monograph)
        else:
            _append_segment(
                unit._source_text,
                unit._source_start,
                unit._source_end,
                transformed,
                mappings,
                output_cursor,
            )
            last_vowel = None
        index += 1

    return PhoneticRepresentation(source^, transformed^, mappings^)
