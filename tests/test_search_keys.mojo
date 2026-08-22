from std.collections import List
from std.testing import (
    TestSuite,
    assert_equal,
    assert_raises,
    assert_true,
)

from yomi import (
    SearchKey,
    SearchKeyBundle,
    SearchKeyKind,
    search_key_kinds_compatible,
)


def test_nominal_key_kind_compatibility_matches_yuru_gates() raises:
    assert_true(
        search_key_kinds_compatible(
            SearchKeyKind.QUERY_ORIGINAL,
            SearchKeyKind.JAPANESE_ROMAJI,
        )
    )
    assert_true(
        search_key_kinds_compatible(
            SearchKeyKind.QUERY_JAPANESE_KANA,
            SearchKeyKind.JAPANESE_KANA,
        )
    )
    assert_true(
        search_key_kinds_compatible(
            SearchKeyKind.QUERY_INITIALS,
            SearchKeyKind.CHINESE_PINYIN_INITIALS,
        )
    )
    assert_true(
        search_key_kinds_compatible(
            SearchKeyKind.QUERY_INITIALS,
            SearchKeyKind.KOREAN_INITIALS,
        )
    )
    assert_true(
        not search_key_kinds_compatible(
            SearchKeyKind.QUERY_JAPANESE_KANA,
            SearchKeyKind.CHINESE_PINYIN_JOINED,
        )
    )
    assert_true(not SearchKeyKind.JAPANESE_KANA.is_query())
    assert_true(SearchKeyKind.QUERY_JAPANESE_KANA.is_query())
    assert_true(
        search_key_kinds_compatible(
            SearchKeyKind.QUERY_ORIGINAL,
            SearchKeyKind.LEARNED_ALIAS,
        )
    )
    assert_true(
        search_key_kinds_compatible(
            SearchKeyKind.QUERY_INITIALS,
            SearchKeyKind.LEARNED_ALIAS,
        )
    )


def test_kind_weights_match_current_yuru_defaults() raises:
    assert_equal(SearchKeyKind.ORIGINAL.default_weight(), 3000)
    assert_equal(SearchKeyKind.NORMALIZED.default_weight(), 2800)
    assert_equal(SearchKeyKind.JAPANESE_KANA.default_weight(), 1700)
    assert_equal(SearchKeyKind.JAPANESE_ROMAJI.default_weight(), 1800)
    assert_equal(SearchKeyKind.CHINESE_PINYIN_INITIALS.default_weight(), 1850)
    assert_equal(SearchKeyKind.KOREAN_INITIALS.default_weight(), 1850)
    assert_equal(SearchKeyKind.LEARNED_ALIAS.default_weight(), 2500)
    assert_equal(SearchKeyKind.QUERY_ORIGINAL.default_weight(), 500)
    assert_equal(SearchKeyKind.QUERY_NORMALIZED.default_weight(), 450)
    assert_equal(SearchKeyKind.QUERY_JAPANESE_KANA.default_weight(), 350)
    assert_equal(SearchKeyKind.QUERY_JAPANESE_ROMAJI_TO_KANA.default_weight(), 200)
    assert_equal(SearchKeyKind.QUERY_CHINESE_PINYIN.default_weight(), 250)
    assert_equal(SearchKeyKind.QUERY_INITIALS.default_weight(), 250)


def test_bundle_validates_cap_and_exposes_detached_values() raises:
    var keys = List[SearchKey]()
    var empty = SearchKeyBundle(keys^, 2)
    assert_equal(empty.count(), 0)
    assert_equal(empty.max_count(), 2)
    with assert_raises():
        _ = empty.key(0)

    var too_many = List[SearchKey]()
    with assert_raises():
        _ = SearchKeyBundle(too_many^, -1)


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
