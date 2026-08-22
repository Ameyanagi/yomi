"""Deterministic modern-Hangul search representations."""

from std.collections import List, Optional

from ..representation import PhoneticRepresentation, SourceMapping
from .hangul import (
    _L_BASE,
    _N_COUNT,
    _S_BASE,
    _T_BASE,
    _T_COUNT,
    _V_BASE,
    _first_codepoint,
    _is_modern_leading_jamo,
    _is_modern_syllable,
    _is_modern_trailing_jamo,
    _is_modern_vowel_jamo,
)


struct _SearchRepresentationKind(Copyable, Equatable, ImplicitlyCopyable):
    var _value: Int

    comptime ROMANIZED = _SearchRepresentationKind(_value=0)
    comptime ROMANIZED_SPACED = _SearchRepresentationKind(_value=1)
    comptime KEYBOARD = _SearchRepresentationKind(_value=2)

    def __init__(out self, *, _value: Int):
        self._value = _value

    def __eq__(self, other: Self) -> Bool:
        return self._value == other._value


struct _ModernHangulSyllable(Copyable):
    var initial: Int
    var vowel: Int
    var final_consonant: Int

    def __init__(out self, initial: Int, vowel: Int, final_consonant: Int):
        self.initial = initial
        self.vowel = vowel
        self.final_consonant = final_consonant


def _modern_hangul_syllable(grapheme: StringSlice) -> Optional[_ModernHangulSyllable]:
    var first = _first_codepoint(grapheme)
    if _is_modern_syllable(first):
        var index = first - _S_BASE
        return _ModernHangulSyllable(
            index // _N_COUNT,
            (index % _N_COUNT) // _T_COUNT,
            index % _T_COUNT,
        )
    if not _is_modern_leading_jamo(first):
        return None

    var second = -1
    var third = -1
    var position = 0
    for codepoint in grapheme.codepoint_slices():
        if position == 1:
            second = _first_codepoint(codepoint)
        elif position == 2:
            third = _first_codepoint(codepoint)
        position += 1
    if not _is_modern_vowel_jamo(second):
        return None

    var final_consonant = 0
    if _is_modern_trailing_jamo(third):
        final_consonant = third - _T_BASE
    return _ModernHangulSyllable(
        first - _L_BASE,
        second - _V_BASE,
        final_consonant,
    )


def _append_romanized_initial(index: Int, mut output: String):
    if index == 0:
        output += "g"
    elif index == 1:
        output += "kk"
    elif index == 2:
        output += "n"
    elif index == 3:
        output += "d"
    elif index == 4:
        output += "tt"
    elif index == 5:
        output += "r"
    elif index == 6:
        output += "m"
    elif index == 7:
        output += "b"
    elif index == 8:
        output += "pp"
    elif index == 9:
        output += "s"
    elif index == 10:
        output += "ss"
    elif index == 12:
        output += "j"
    elif index == 13:
        output += "jj"
    elif index == 14:
        output += "ch"
    elif index == 15:
        output += "k"
    elif index == 16:
        output += "t"
    elif index == 17:
        output += "p"
    elif index == 18:
        output += "h"


def _append_romanized_vowel(index: Int, mut output: String):
    if index == 0:
        output += "a"
    elif index == 1:
        output += "ae"
    elif index == 2:
        output += "ya"
    elif index == 3:
        output += "yae"
    elif index == 4:
        output += "eo"
    elif index == 5:
        output += "e"
    elif index == 6:
        output += "yeo"
    elif index == 7:
        output += "ye"
    elif index == 8:
        output += "o"
    elif index == 9:
        output += "wa"
    elif index == 10:
        output += "wae"
    elif index == 11:
        output += "oe"
    elif index == 12:
        output += "yo"
    elif index == 13:
        output += "u"
    elif index == 14:
        output += "wo"
    elif index == 15:
        output += "we"
    elif index == 16:
        output += "wi"
    elif index == 17:
        output += "yu"
    elif index == 18:
        output += "eu"
    elif index == 19:
        output += "ui"
    else:
        output += "i"


def _append_romanized_final(index: Int, mut output: String):
    if index == 1 or index == 2 or index == 3 or index == 9 or index == 24:
        output += "k"
    elif index == 4 or index == 5 or index == 6:
        output += "n"
    elif (
        index == 7
        or index == 19
        or index == 20
        or index == 22
        or index == 23
        or index == 25
        or index == 27
    ):
        output += "t"
    elif index == 8 or index == 12 or index == 13 or index == 15:
        output += "l"
    elif index == 10 or index == 16:
        output += "m"
    elif index == 11 or index == 14 or index == 17 or index == 18 or index == 26:
        output += "p"
    elif index == 21:
        output += "ng"


def _append_initial_key(index: Int, mut output: String):
    if index == 0 or index == 1:
        output += "r"
    elif index == 2:
        output += "s"
    elif index == 3 or index == 4:
        output += "e"
    elif index == 5:
        output += "f"
    elif index == 6:
        output += "a"
    elif index == 7 or index == 8:
        output += "q"
    elif index == 9 or index == 10:
        output += "t"
    elif index == 11:
        output += "d"
    elif index == 12 or index == 13:
        output += "w"
    elif index == 14:
        output += "c"
    elif index == 15:
        output += "z"
    elif index == 16:
        output += "x"
    elif index == 17:
        output += "v"
    else:
        output += "g"


def _append_vowel_key(index: Int, mut output: String):
    if index == 0:
        output += "k"
    elif index == 1 or index == 3:
        output += "o"
    elif index == 2:
        output += "i"
    elif index == 4:
        output += "j"
    elif index == 5 or index == 7:
        output += "p"
    elif index == 6:
        output += "u"
    elif index == 8:
        output += "h"
    elif index == 9:
        output += "hk"
    elif index == 10:
        output += "ho"
    elif index == 11:
        output += "hl"
    elif index == 12:
        output += "y"
    elif index == 13:
        output += "n"
    elif index == 14:
        output += "nj"
    elif index == 15:
        output += "np"
    elif index == 16:
        output += "nl"
    elif index == 17:
        output += "b"
    elif index == 18:
        output += "m"
    elif index == 19:
        output += "ml"
    else:
        output += "l"


def _append_final_key(index: Int, mut output: String):
    if index == 1 or index == 2:
        output += "r"
    elif index == 3:
        output += "rt"
    elif index == 4:
        output += "s"
    elif index == 5:
        output += "sw"
    elif index == 6:
        output += "sg"
    elif index == 7:
        output += "e"
    elif index == 8:
        output += "f"
    elif index == 9:
        output += "fr"
    elif index == 10:
        output += "fa"
    elif index == 11:
        output += "fq"
    elif index == 12:
        output += "ft"
    elif index == 13:
        output += "fx"
    elif index == 14:
        output += "fv"
    elif index == 15:
        output += "fg"
    elif index == 16:
        output += "a"
    elif index == 17:
        output += "q"
    elif index == 18:
        output += "qt"
    elif index == 19 or index == 20:
        output += "t"
    elif index == 21:
        output += "d"
    elif index == 22:
        output += "w"
    elif index == 23:
        output += "c"
    elif index == 24:
        output += "z"
    elif index == 25:
        output += "x"
    elif index == 26:
        output += "v"
    elif index == 27:
        output += "g"


def _append_syllable(
    syllable: _ModernHangulSyllable,
    kind: _SearchRepresentationKind,
    mut output: String,
):
    if kind == _SearchRepresentationKind.KEYBOARD:
        _append_initial_key(syllable.initial, output)
        _append_vowel_key(syllable.vowel, output)
        _append_final_key(syllable.final_consonant, output)
    else:
        _append_romanized_initial(syllable.initial, output)
        _append_romanized_vowel(syllable.vowel, output)
        _append_romanized_final(syllable.final_consonant, output)


def _hangul_search_representation(
    text: StringSlice, kind: _SearchRepresentationKind
) raises -> PhoneticRepresentation:
    var source = String(text)
    var transformed = String()
    var mappings = List[SourceMapping]()
    var source_cursor = 0
    var output_cursor = 0
    var previous_was_hangul = False

    for grapheme in source.graphemes():
        var source_end = source_cursor + grapheme.byte_length()
        var syllable = _modern_hangul_syllable(grapheme)
        if syllable:
            if (
                kind == _SearchRepresentationKind.ROMANIZED_SPACED
                and previous_was_hangul
            ):
                transformed += " "
                mappings.append(
                    SourceMapping.unmapped(output_cursor, output_cursor + 1)
                )
                output_cursor += 1

            var output_start = output_cursor
            _append_syllable(syllable.value(), kind, transformed)
            output_cursor = transformed.byte_length()
            mappings.append(
                SourceMapping(output_start, output_cursor, source_cursor, source_end)
            )
            previous_was_hangul = True
        else:
            transformed += grapheme
            var output_end = transformed.byte_length()
            mappings.append(
                SourceMapping(output_cursor, output_end, source_cursor, source_end)
            )
            output_cursor = output_end
            previous_was_hangul = False
        source_cursor = source_end

    return PhoneticRepresentation(source^, transformed^, mappings^)


def romanize_hangul(text: StringSlice) raises -> PhoneticRepresentation:
    """Build a joined deterministic Revised-Romanization-style finder key.

    Modern precomposed and canonical decomposed Hangul syllables share the same
    ASCII output. The spelling is mechanical and does not apply
    pronunciation-dependent assimilation. Other grapheme clusters pass through
    unchanged.
    """
    return _hangul_search_representation(text, _SearchRepresentationKind.ROMANIZED)


def romanize_hangul_spaced(text: StringSlice) raises -> PhoneticRepresentation:
    """Build deterministic romanization separated within each Hangul run.

    Generated ASCII spaces have explicit unmapped output spans, so matching a
    separator alone projects to no source range. Other output maps exactly to
    the source grapheme that produced it.
    """
    return _hangul_search_representation(
        text, _SearchRepresentationKind.ROMANIZED_SPACED
    )


def hangul_keyboard(text: StringSlice) raises -> PhoneticRepresentation:
    """Build the Korean Dubeolsik (2-set) QWERTY input sequence.

    Each modern syllable expands to the key sequence for its initial, vowel,
    and optional final consonant. Canonical decomposed input is equivalent to
    precomposed input, and other grapheme clusters pass through unchanged.
    """
    return _hangul_search_representation(text, _SearchRepresentationKind.KEYBOARD)
