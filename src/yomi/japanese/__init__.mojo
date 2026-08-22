"""Japanese phonetic representations."""

from .convert import to_hiragana, to_katakana
from .kana import romanize_kana
from .search import (
    japanese_candidate_keys,
    japanese_kana_key,
    japanese_query_kana,
    japanese_query_keys,
    japanese_romaji_key,
    japanese_search_keys,
    japanese_search_representations,
)
