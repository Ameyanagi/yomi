"""Allocation-free routing predicates for CJK scripts."""


def _is_hiragana_scalar(value: Int) -> Bool:
    return (
        (value >= 0x3041 and value <= 0x3096)
        or (value >= 0x309D and value <= 0x309E)
        or (value >= 0x3099 and value <= 0x309A)
        or value == 0x30FC
    )


def _is_katakana_scalar(value: Int) -> Bool:
    return (
        (value >= 0x30A1 and value <= 0x30FA)
        or (value >= 0x30FD and value <= 0x30FE)
        or value == 0x30FC
        or (value >= 0x3099 and value <= 0x309A)
    )


def is_hiragana(text: StringSlice) -> Bool:
    """Return whether Hiragana phonetic routing should be attempted.

    This per-scalar predicate accepts U+3041--U+3096 letters,
    U+309D--U+309E iteration marks, U+3099--U+309A combining voiced marks,
    and the U+30FC prolonged sound mark. Every scalar must be accepted, and
    empty input returns False.
    """
    var saw_scalar = False
    for scalar in text.codepoints():
        saw_scalar = True
        if not _is_hiragana_scalar(Int(scalar.to_u32())):
            return False
    return saw_scalar


def is_katakana(text: StringSlice) -> Bool:
    """Return whether Katakana phonetic routing should be attempted.

    This per-scalar predicate accepts U+30A1--U+30FA letters,
    U+30FD--U+30FE iteration marks, the U+30FC prolonged sound mark, and
    U+3099--U+309A combining voiced marks. Every scalar must be accepted, and
    empty input returns False.
    """
    var saw_scalar = False
    for scalar in text.codepoints():
        saw_scalar = True
        if not _is_katakana_scalar(Int(scalar.to_u32())):
            return False
    return saw_scalar


def is_kana(text: StringSlice) -> Bool:
    """Return whether Hiragana or Katakana routing should be attempted.

    This per-scalar predicate accepts U+3041--U+3096 Hiragana letters,
    U+3099--U+309E combining, spacing, and iteration marks,
    U+30A1--U+30FA Katakana letters, and U+30FC--U+30FE prolonged and iteration
    marks. Every scalar must be accepted, and empty input returns False.
    """
    var saw_scalar = False
    for scalar in text.codepoints():
        saw_scalar = True
        var value = Int(scalar.to_u32())
        if not (
            _is_hiragana_scalar(value)
            or _is_katakana_scalar(value)
            or (value >= 0x309B and value <= 0x309C)
        ):
            return False
    return saw_scalar


def is_kanji(text: StringSlice) -> Bool:
    """Return whether base-block Kanji phonetic routing should be attempted.

    This per-scalar predicate accepts only U+4E00--U+9FFF CJK Unified
    Ideographs. Extension blocks are deliberately excluded for now. Every
    scalar must be accepted, and empty input returns False.
    """
    var saw_scalar = False
    for scalar in text.codepoints():
        saw_scalar = True
        var value = Int(scalar.to_u32())
        if value < 0x4E00 or value > 0x9FFF:
            return False
    return saw_scalar


def is_hangul_syllable(text: StringSlice) -> Bool:
    """Return whether modern Hangul-syllable routing should be attempted.

    This per-scalar predicate accepts only U+AC00--U+D7A3 precomposed modern
    syllables. Conjoining and compatibility Jamo are deliberately excluded.
    Every scalar must be accepted, and empty input returns False.
    """
    var saw_scalar = False
    for scalar in text.codepoints():
        saw_scalar = True
        var value = Int(scalar.to_u32())
        if value < 0xAC00 or value > 0xD7A3:
            return False
    return saw_scalar


def is_hangul_jamo(text: StringSlice) -> Bool:
    """Return whether modern Hangul-Jamo routing should be attempted.

    This per-scalar predicate accepts conjoining leading U+1100--U+1112,
    vowel U+1161--U+1175, and trailing U+11A8--U+11C2 Jamo, plus compatibility
    Jamo U+3131--U+3163. Every scalar must be accepted, and empty input returns
    False.
    """
    var saw_scalar = False
    for scalar in text.codepoints():
        saw_scalar = True
        var value = Int(scalar.to_u32())
        if not (
            (value >= 0x1100 and value <= 0x1112)
            or (value >= 0x1161 and value <= 0x1175)
            or (value >= 0x11A8 and value <= 0x11C2)
            or (value >= 0x3131 and value <= 0x3163)
        ):
            return False
    return saw_scalar
