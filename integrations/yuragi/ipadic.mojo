"""Append optional IPADIC keys to Yuragi's existing corpus and metadata types."""

from hibana.prepared import PreparedCorpus
from std.collections import List
from std.sys import argv
from yomi import PhoneticRepresentation
from yomi.japanese.ipadic import IpadicReadingProvider
from yuragi.phonetic import IndexedPhoneticKey, project_key_positions


def main() raises:
    var args = argv()
    if len(args) != 2:
        raise Error(
            "usage: ipadic <path/to/readings.tsv>; install with"
            " scripts/install_ipadic.py"
        )
    var provider = IpadicReadingProvider(String(args[1]))
    var source = String("佐藤")
    var bundle = provider.candidate_keys(source)
    var source_keys = bundle^.take_keys()
    var corpus = PreparedCorpus()
    var metadata = List[IndexedPhoneticKey]()
    var representations = List[PhoneticRepresentation]()
    var ordinal = 0
    while len(source_keys) > 0:
        var key = source_keys.pop(0)
        var text = key.text()
        corpus.append(text)
        metadata.append(IndexedPhoneticKey(0, key.kind(), key.weight(), ordinal))
        representations.append(key^.take_representation())
        ordinal += 1
    print("indexed keys:", len(corpus))
    for index in range(len(representations)):
        if representations[index].text_equals("satou"):
            # A matcher supplies key-codepoint positions. Yuragi performs
            # projection; Yomi supplies readings/mappings and never scores.
            var matched_positions: List[Int] = [0]
            var source_positions = project_key_positions(
                representations[index], matched_positions, source
            )
            print("satou initial maps to source codepoints:", source_positions)
