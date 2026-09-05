"""Load the optional full dictionary and inspect bounded Japanese key alternatives."""

from std.sys import argv
from std.time import perf_counter_ns
from yomi.japanese.ipadic import IpadicReadingProvider


def main() raises:
    var args = argv()
    if len(args) != 2:
        raise Error(
            "usage: ipadic <path/to/readings.tsv>; run scripts/install_ipadic.py first"
        )
    var started = perf_counter_ns()
    var provider = IpadicReadingProvider(String(args[1]))
    print(
        "surfaces:",
        provider.entry_count(),
        "load_ms:",
        Float64(perf_counter_ns() - started) / 1e6,
    )
    for source in [String("佐藤"), String("日本"), String("生田"), String("🙂東京大学𠮷")]:
        var bundle = provider.candidate_keys(source)
        print(source)
        for index in range(bundle.count()):
            var key = bundle.key(index)
            key.representation().validate()
            print(" ", key.text())
