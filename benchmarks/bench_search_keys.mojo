"""Profile-oriented CJK search-key generation benchmark."""

from std.benchmark import keep
from std.collections import List
from std.time import perf_counter_ns
from yomi import (
    SearchKeyBundle,
    chinese_candidate_keys,
    chinese_query_keys,
    japanese_candidate_keys,
    korean_candidate_keys,
)


comptime _SAMPLES = 31
comptime _CANDIDATES = 10_000
comptime _TINY_BUDGET_CANDIDATES = 1_000


def _sort(mut values: List[Int]):
    for index in range(1, len(values)):
        var value = values[index]
        var destination = index
        while destination > 0 and values[destination - 1] > value:
            values[destination] = values[destination - 1]
            destination -= 1
        values[destination] = value


def _bundle_checksum(var bundle: SearchKeyBundle) -> Int:
    """Consume key metadata so count-only dead work cannot skew the benchmark."""
    var keys = bundle^.take_keys()
    var checksum = len(keys) * 31
    while len(keys) > 0:
        var key = keys.pop()
        checksum += key.text_byte_length() * 17 + key.weight()
    return checksum


def _report(
    name: StringSlice,
    candidates: Int,
    var timings: List[Int],
    checksum: Int,
):
    _sort(timings)
    print(
        "BENCH yomi operation=",
        name,
        " candidates=",
        candidates,
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
            keep(
                _bundle_checksum(
                    japanese_candidate_keys(String("東京2025年", index % 97))
                )
            )
    for _ in range(_SAMPLES):
        var checksum = 0
        var started = perf_counter_ns()
        for index in range(_CANDIDATES):
            checksum += _bundle_checksum(
                japanese_candidate_keys(String("東京2025年", index % 97))
            )
        timings.append(perf_counter_ns() - started)
        final_checksum = checksum
        keep(checksum)
    _report("japanese_candidate_keys", _CANDIDATES, timings^, final_checksum)


def _chinese() raises:
    var timings = List[Int](capacity=_SAMPLES)
    var final_checksum = 0
    for _ in range(3):
        for _ in range(_CANDIDATES):
            keep(_bundle_checksum(chinese_candidate_keys("重庆银行大学")))
    for _ in range(_SAMPLES):
        var checksum = 0
        var started = perf_counter_ns()
        for _ in range(_CANDIDATES):
            checksum += _bundle_checksum(chinese_candidate_keys("重庆银行大学"))
        timings.append(perf_counter_ns() - started)
        final_checksum = checksum
        keep(checksum)
    _report("chinese_candidate_keys", _CANDIDATES, timings^, final_checksum)


def _chinese_query() raises:
    var timings = List[Int](capacity=_SAMPLES)
    var final_checksum = 0
    for _ in range(3):
        for _ in range(_CANDIDATES):
            keep(_bundle_checksum(chinese_query_keys("ＢＪＤＸ")))
    for _ in range(_SAMPLES):
        var checksum = 0
        var started = perf_counter_ns()
        for _ in range(_CANDIDATES):
            checksum += _bundle_checksum(chinese_query_keys("ＢＪＤＸ"))
        timings.append(perf_counter_ns() - started)
        final_checksum = checksum
        keep(checksum)
    _report("chinese_query_keys", _CANDIDATES, timings^, final_checksum)


def _korean() raises:
    var timings = List[Int](capacity=_SAMPLES)
    var final_checksum = 0
    for _ in range(3):
        for _ in range(_CANDIDATES):
            keep(_bundle_checksum(korean_candidate_keys("서울특별시")))
    for _ in range(_SAMPLES):
        var checksum = 0
        var started = perf_counter_ns()
        for _ in range(_CANDIDATES):
            checksum += _bundle_checksum(korean_candidate_keys("서울특별시"))
        timings.append(perf_counter_ns() - started)
        final_checksum = checksum
        keep(checksum)
    _report("korean_candidate_keys", _CANDIDATES, timings^, final_checksum)


def _limited_bundles() raises:
    var timings = List[Int](capacity=_SAMPLES)
    var final_checksum = 0
    for _ in range(3):
        for _ in range(_CANDIDATES):
            keep(_bundle_checksum(japanese_candidate_keys("東2025年", 2, 0)))
            keep(_bundle_checksum(korean_candidate_keys("서울특별시", 1, 0)))
            keep(_bundle_checksum(chinese_candidate_keys("重庆银行大学", 1, 0)))
    for _ in range(_SAMPLES):
        var checksum = 0
        var started = perf_counter_ns()
        for _ in range(_CANDIDATES):
            checksum += _bundle_checksum(japanese_candidate_keys("東2025年", 2, 0))
            checksum += _bundle_checksum(korean_candidate_keys("서울특별시", 1, 0))
            checksum += _bundle_checksum(chinese_candidate_keys("重庆银行大学", 1, 0))
        timings.append(perf_counter_ns() - started)
        final_checksum = checksum
        keep(checksum)
    _report("base_only_candidate_bundles", _CANDIDATES, timings^, final_checksum)


def _korean_tiny_budget() raises:
    var source = String()
    for _ in range(128):
        source += "한"
    var timings = List[Int](capacity=_SAMPLES)
    var final_checksum = 0
    for _ in range(3):
        for _ in range(_TINY_BUDGET_CANDIDATES):
            keep(_bundle_checksum(korean_candidate_keys(source, 5, 1)))
    for _ in range(_SAMPLES):
        var checksum = 0
        var started = perf_counter_ns()
        for _ in range(_TINY_BUDGET_CANDIDATES):
            checksum += _bundle_checksum(korean_candidate_keys(source, 5, 1))
        timings.append(perf_counter_ns() - started)
        final_checksum = checksum
        keep(checksum)
    _report(
        "korean_long_label_tiny_budget",
        _TINY_BUDGET_CANDIDATES,
        timings^,
        final_checksum,
    )


def main() raises:
    print(
        "BENCH_HEADER yomi search_keys mojo=1.0.0 samples=31 warmup=3 ",
        "workload=deterministic",
        sep="",
    )
    _japanese()
    _chinese()
    _chinese_query()
    _korean()
    _limited_bundles()
    _korean_tiny_budget()
