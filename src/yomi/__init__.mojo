"""CJK phonetic representations with exact source-byte mappings."""

from .chinese import (
    ChinesePolyphoneMode,
    pinyin_full,
    pinyin_initials,
    pinyin_joined,
    pinyin_representations,
)
from .japanese import (
    japanese_candidate_keys,
    japanese_kana_key,
    japanese_query_kana,
    japanese_query_keys,
    japanese_romaji_key,
    japanese_search_keys,
    japanese_search_representations,
    romanize_kana,
    to_hiragana,
    to_katakana,
)
from .korean import (
    compose_hangul,
    decompose_hangul,
    hangul_choseong,
    hangul_keyboard,
    korean_candidate_keys,
    romanize_hangul,
    romanize_hangul_spaced,
)
from .representation import PhoneticRepresentation, SourceMapping, SourceRange
from .search_key import (
    SearchKey,
    SearchKeyBundle,
    SearchKeyKind,
    search_key_kinds_compatible,
)
from .script import is_hangul_syllable, is_hiragana, is_kana, is_kanji, is_katakana
