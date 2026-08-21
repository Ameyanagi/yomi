from yomi import to_romaji, to_hiragana


def main() raises:
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
