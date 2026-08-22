from yomi import (
    chinese_candidate_keys,
    chinese_query_keys,
    pinyin_full,
    pinyin_initials,
    pinyin_joined,
    pinyin_representations,
)


def main() raises:
    var source = "北京大学"
    var keys = chinese_candidate_keys(source)
    for index in range(keys.count()):
        print("candidate", keys.key(index).text())

    var queries = chinese_query_keys("ＢＪＤＸ")
    for index in range(queries.count()):
        print("query", queries.key(index).text())

    print("full", pinyin_full(source).text())
    print("joined", pinyin_joined(source).text())
    print("initials", pinyin_initials(source).text())

    var alternatives = pinyin_representations("还没")
    for index in range(len(alternatives)):
        print("alternate", alternatives[index].text())

    var full = pinyin_full(source)
    var ranges = full.source_ranges_for_output(4, 8)
    print("jing match -> source", ranges[0].start(), ranges[0].end())
