from std.testing import assert_equal, assert_raises

from yomi import (
    SearchKeyKind,
    chinese_candidate_keys,
    chinese_query_keys,
    compose_hangul,
    decompose_hangul,
    decompose_hangul_compatibility,
    hangul_choseong,
    hangul_keyboard,
    is_hangul_jamo,
    japanese_query_kana,
    japanese_query_keys,
    japanese_candidate_keys,
    japanese_search_keys,
    japanese_search_representations,
    korean_candidate_keys,
    pinyin_full,
    pinyin_initials,
    pinyin_joined,
    pinyin_representations,
    romanize_hangul,
    romanize_hangul_spaced,
    to_romaji,
)
from yomi.japanese.ipadic import IpadicReadingProvider


def main() raises:
    # The optional provider ships as an importable API without dictionary data.
    with assert_raises():
        _ = IpadicReadingProvider("__yomi_package_missing_ipadic_dictionary.tsv")

    var representation = hangul_choseong("한국")
    assert_equal(representation.source_text(), "한국")
    assert_equal(representation.text(), "ㅎㄱ")
    var mappings = representation.mapping_snapshot()
    assert_equal(len(mappings), 2)
    assert_equal(mappings[0].output_start(), 0)
    assert_equal(mappings[0].output_end(), 3)
    assert_equal(mappings[0].source_start(), 0)
    assert_equal(mappings[0].source_end(), 3)

    var ranges = representation.source_ranges_for_output(0, 6)
    assert_equal(len(ranges), 1)
    assert_equal(ranges[0].start(), 0)
    assert_equal(ranges[0].end(), 6)

    var decomposed = hangul_choseong("한")
    assert_equal(decomposed.text(), "ㅎ")

    assert_equal(romanize_hangul("한글").text(), "hangeul")
    var spaced = romanize_hangul_spaced("한글")
    assert_equal(spaced.text(), "han geul")
    var generated_space = spaced.source_ranges_for_output(3, 4)
    assert_equal(len(generated_space), 0)
    assert_equal(hangul_keyboard("한글").text(), "gksrmf")
    var korean_keys = korean_candidate_keys("서울")
    assert_equal(korean_keys.count(), 5)
    assert_equal(korean_keys.key(1).text(), "seoul")
    assert_equal(korean_keys.key(2).text(), "seo ul")
    assert_equal(korean_keys.key(3).text(), "ㅅㅇ")
    assert_equal(korean_keys.key(4).text(), "tjdnf")

    var hangul = decompose_hangul("각")
    assert_equal(hangul.source_text(), "각")
    assert_equal(hangul.text(), "각")
    var hangul_mappings = hangul.mapping_snapshot()
    assert_equal(len(hangul_mappings), 3)
    for index in range(len(hangul_mappings)):
        assert_equal(hangul_mappings[index].source_start(), 0)
        assert_equal(hangul_mappings[index].source_end(), 3)

    var hangul_source = hangul.source_ranges_for_output(0, 9)
    assert_equal(len(hangul_source), 1)
    assert_equal(hangul_source[0].start(), 0)
    assert_equal(hangul_source[0].end(), 3)

    var nfd_hangul = decompose_hangul("각")
    assert_equal(nfd_hangul.text(), hangul.text())
    var nfd_mappings = nfd_hangul.mapping_snapshot()
    assert_equal(len(nfd_mappings), 3)
    assert_equal(nfd_mappings[0].source_start(), 0)
    assert_equal(nfd_mappings[0].source_end(), 3)
    assert_equal(nfd_mappings[2].source_start(), 6)
    assert_equal(nfd_mappings[2].source_end(), 9)

    var compatibility = decompose_hangul_compatibility("한")
    assert_equal(compatibility.text(), "ㅎㅏㄴ")
    assert_equal(compose_hangul(compatibility.text()).text(), "한")
    assert_equal(is_hangul_jamo(compatibility.text()), True)

    var kana = to_romaji("ラーメン屋")
    assert_equal(kana.text(), "raamen屋")
    assert_equal(kana.mapping_count(), 5)
    var kana_source = kana.source_ranges_for_output(0, 6)
    assert_equal(len(kana_source), 1)
    assert_equal(kana_source[0].start(), 0)
    assert_equal(kana_source[0].end(), 12)

    assert_equal(japanese_query_kana("zyu").text(), "じゅ")
    var japanese_query_variants = japanese_query_keys("kanya")
    assert_equal(japanese_query_variants.count(), 3)
    assert_equal(japanese_query_variants.key(0).weight(), 500)
    for native_query in ["カ", "카", "é", "😀", " \tカ\t "]:
        var native_variants = japanese_query_keys(native_query)
        native_variants.validate()
        assert_equal(native_variants.key(0).text(), native_query)
    assert_equal(SearchKeyKind.LEARNED_ALIAS.default_weight(), 2500)
    var japanese_keys = japanese_search_representations("8月")
    assert_equal(japanese_keys[2].text(), "hachigatsu")
    assert_equal(japanese_search_keys("8月").count(), len(japanese_keys))
    assert_equal(japanese_candidate_keys("8月").key(0).text(), "8月")

    assert_equal(pinyin_full("北京大学").text(), "bei jing da xue")
    assert_equal(pinyin_joined("北京大学").text(), "beijingdaxue")
    var initials = pinyin_initials("北京大学")
    assert_equal(initials.text(), "bjdx")
    var initials_source = initials.source_ranges_for_output(0, 4)
    assert_equal(len(initials_source), 1)
    assert_equal(initials_source[0].start(), 0)
    assert_equal(initials_source[0].end(), 12)
    var pinyin_alternatives = pinyin_representations("还没")
    assert_equal(len(pinyin_alternatives), 8)
    assert_equal(pinyin_alternatives[4].text(), "huanmei")
    var chinese_keys = chinese_candidate_keys("北京大学")
    assert_equal(chinese_keys.key(0).text(), "北京大学")
    assert_equal(chinese_keys.key(3).text(), "bjdx")
    assert_equal(
        chinese_keys.key(3).kind() == SearchKeyKind.CHINESE_PINYIN_INITIALS, True
    )
    var common_chinese_keys = chinese_candidate_keys("还没")
    assert_equal(common_chinese_keys.count(), 8)
    assert_equal(common_chinese_keys.key(7).text(), "haimo")
    var chinese_queries = chinese_query_keys("ＢＪＤＸ")
    assert_equal(chinese_queries.count(), 3)
    assert_equal(chinese_queries.key(2).text(), "bjdx")
    assert_equal(chinese_queries.key(2).kind() == SearchKeyKind.QUERY_INITIALS, True)

    var moved_bundle = chinese_candidate_keys("中", 4)
    var moved_keys = moved_bundle^.take_keys()
    var moved_key = moved_keys.pop(0)
    assert_equal(moved_key^.take_representation().text(), "中")
