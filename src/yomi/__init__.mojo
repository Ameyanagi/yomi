"""CJK phonetic representations with exact source-byte mappings."""

from .japanese import romanize_kana
from .korean import compose_hangul, decompose_hangul, hangul_choseong
from .representation import PhoneticRepresentation, SourceMapping, SourceRange
from .script import is_hangul_syllable, is_hiragana, is_kana, is_kanji, is_katakana
