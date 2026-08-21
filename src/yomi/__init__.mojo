"""CJK phonetic representations with exact source-byte mappings."""

from .japanese import to_hiragana, to_katakana, to_romaji
from .korean import (
    compose_hangul,
    decompose_hangul,
    decompose_hangul_compatibility,
    hangul_choseong,
)
from .representation import PhoneticRepresentation, SourceMapping, SourceRange
from .script import (
    is_hangul_jamo,
    is_hangul_syllable,
    is_hiragana,
    is_kana,
    is_kanji,
    is_katakana,
)
