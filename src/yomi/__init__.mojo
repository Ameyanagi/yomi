"""CJK phonetic representations with exact source-byte mappings."""

from .chinese import (
    ChinesePolyphoneMode,
    chinese_candidate_keys,
    chinese_query_keys,
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
    to_hiragana,
    to_katakana,
    to_romaji,
)
from .korean import (
    compose_hangul,
    decompose_hangul,
    decompose_hangul_compatibility,
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
from .script import (
    is_hangul_jamo,
    is_hangul_syllable,
    is_hiragana,
    is_kana,
    is_kanji,
    is_katakana,
)
