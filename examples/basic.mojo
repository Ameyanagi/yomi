from yomi import hangul_choseong


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
