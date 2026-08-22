"""Profile-oriented CJK search-key generation benchmark."""

from std.benchmark import keep
from std.collections import List
from std.time import perf_counter_ns
from yomi import (
    japanese_candidate_keys,
    korean_candidate_keys,
    pinyin_representations,
)


comptime _SAMPLES = 31
comptime _CANDIDATES = 10_000


def _sort(mut values: List[Int]):
    for index in range(1, len(values)):
        var value = values[index]
        var destination = index
        while destination > 0 and values[destination - 1] > value:
            values[destination] = values[destination - 1]
            destination -= 1
        values[destination] = value


def _report(name: StringSlice, var timings: List[Int], checksum: Int):
    _sort(timings)
    print(
        "BENCH yomi operation=",
        name,
        " candidates=",
        _CANDIDATES,
        " samples=31 statistic=nearest-rank p50_ns=",
        timings[15],
        " p95_ns=",
        timings[29],
        " checksum=",
        checksum,
        sep="",
    )


def _japanese() raises:
    var timings = List[Int](capacity=_SAMPLES)
    var final_checksum = 0
    for _ in range(3):
        for index in range(_CANDIDATES):
            keep(japanese_candidate_keys(String("東京2025年", index % 97)).count())
    for _ in range(_SAMPLES):
        var checksum = 0
        var started = perf_counter_ns()
        for index in range(_CANDIDATES):
            checksum += japanese_candidate_keys(
                String("東京2025年", index % 97)
            ).count()
        timings.append(perf_counter_ns() - started)
        final_checksum = checksum
        keep(checksum)
    _report("japanese_candidate_keys", timings^, final_checksum)


def _chinese() raises:
    var timings = List[Int](capacity=_SAMPLES)
    var final_checksum = 0
    for _ in range(3):
        for _ in range(_CANDIDATES):
            keep(len(pinyin_representations("重庆银行大学")))
    for _ in range(_SAMPLES):
        var checksum = 0
        var started = perf_counter_ns()
        for _ in range(_CANDIDATES):
            checksum += len(pinyin_representations("重庆银行大学"))
        timings.append(perf_counter_ns() - started)
        final_checksum = checksum
        keep(checksum)
    _report("chinese_pinyin_representations", timings^, final_checksum)


def _korean() raises:
    var timings = List[Int](capacity=_SAMPLES)
    var final_checksum = 0
    for _ in range(3):
        for _ in range(_CANDIDATES):
            keep(korean_candidate_keys("서울특별시").count())
    for _ in range(_SAMPLES):
        var checksum = 0
        var started = perf_counter_ns()
        for _ in range(_CANDIDATES):
            checksum += korean_candidate_keys("서울특별시").count()
        timings.append(perf_counter_ns() - started)
        final_checksum = checksum
        keep(checksum)
    _report("korean_candidate_keys", timings^, final_checksum)


def _limited_bundles() raises:
    var timings = List[Int](capacity=_SAMPLES)
    var final_checksum = 0
    for _ in range(3):
        for _ in range(_CANDIDATES):
            keep(japanese_candidate_keys("東2025年", 2, 0).count())
            keep(korean_candidate_keys("서울특별시", 1, 0).count())
    for _ in range(_SAMPLES):
        var checksum = 0
        var started = perf_counter_ns()
        for _ in range(_CANDIDATES):
            checksum += japanese_candidate_keys("東2025年", 2, 0).count()
            checksum += korean_candidate_keys("서울특별시", 1, 0).count()
        timings.append(perf_counter_ns() - started)
        final_checksum = checksum
        keep(checksum)
    _report("base_only_candidate_bundles", timings^, final_checksum)


def main() raises:
    print(
        "BENCH_HEADER yomi search_keys mojo=1.0.0 samples=31 warmup=3 ",
        "workload=deterministic",
        sep="",
    )
    _japanese()
    _chinese()
    _korean()
    _limited_bundles()
