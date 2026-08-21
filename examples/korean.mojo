from yomi import compose_hangul, decompose_hangul, hangul_choseong


def main() raises:
    var representation = hangul_choseong("한국 notes")
    print(representation.text())

    var mappings = representation.mapping_snapshot()
    for index in range(len(mappings)):
        var mapping = mappings[index].copy()
        print(
            "output",
            mapping.output_start(),
            mapping.output_end(),
            "-> source",
            mapping.source_start(),
            mapping.source_end(),
        )

    var decomposition = decompose_hangul("각")
    print(decomposition.text())
    var decomposition_mappings = decomposition.mapping_snapshot()
    for index in range(len(decomposition_mappings)):
        var mapping = decomposition_mappings[index].copy()
        print(
            "output",
            mapping.output_start(),
            mapping.output_end(),
            "-> source",
            mapping.source_start(),
            mapping.source_end(),
        )

    var decomposed = decomposition.text()
    var composition = compose_hangul(decomposed)
    print(composition.text())

    var source_ranges = representation.source_ranges_for_output(0, 6)
    for index in range(len(source_ranges)):
        var source_range = source_ranges[index].copy()
        print("choseong match -> source", source_range.start(), source_range.end())
