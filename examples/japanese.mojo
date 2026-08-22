from yomi import (
    japanese_candidate_keys,
    japanese_query_kana,
    japanese_query_keys,
    japanese_search_keys,
    japanese_search_representations,
    to_hiragana,
    to_romaji,
)


def main() raises:
    print(japanese_query_kana("zyu").text())
    var query_keys = japanese_query_keys("kanya")
    for index in range(query_keys.count()):
        print("query variant", query_keys.key(index).text())

    var typed_search_keys = japanese_search_keys("2025年8月")
    print("typed candidate keys", typed_search_keys.count())
    var candidate = japanese_candidate_keys("ｶﾒﾗ　ＡＢＣ")
    for index in range(candidate.count()):
        var key = candidate.key(index)
        print("candidate", key.text(), "weight", key.weight())
    var search_keys = japanese_search_representations("2025年8月")
    for index in range(len(search_keys)):
        print(search_keys[index].text())

    var romanized = to_romaji("ラーメン屋")
    print(romanized.text())

    var romanized_mappings = romanized.mapping_snapshot()
    for index in range(len(romanized_mappings)):
        var mapping = romanized_mappings[index].copy()
        print(
            "output",
            mapping.output_start(),
            mapping.output_end(),
            "-> source",
            mapping.source_start(),
            mapping.source_end(),
        )

    var source_ranges = romanized.source_ranges_for_output(0, 6)
    for index in range(len(source_ranges)):
        var source_range = source_ranges[index].copy()
        print("raamen match -> source", source_range.start(), source_range.end())

    var hiragana = to_hiragana("ラーメン")
    print(hiragana.text())
    var hiragana_mappings = hiragana.mapping_snapshot()
    for index in range(len(hiragana_mappings)):
        var mapping = hiragana_mappings[index].copy()
        print(
            "output",
            mapping.output_start(),
            mapping.output_end(),
            "-> source",
            mapping.source_start(),
            mapping.source_end(),
        )
