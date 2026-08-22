# Benchmarks

`bench_search_keys.mojo` exercises the three shipped CJK candidate-key paths
and Chinese query expansion over 10,000 deterministic inputs. It also includes
a base-only capped-bundle workload and 1,000 long Korean labels under a one-byte
generated budget to catch eager work after caps are exhausted. It performs
three warmups, records 31 samples, and reports nearest-rank p50/p95. Checksums
consume aggregate key byte lengths and kind weights, rather than counts alone,
so key construction cannot disappear as dead work.

Run the source benchmark with:

```sh
pixi run bench-search-keys
```

For optimization work, profile the compiled program so interpreter/compiler
startup does not obscure library frames:

```sh
pixi run mojo build -O3 -g1 -I src benchmarks/bench_search_keys.mojo \
  -o /tmp/yomi-bench-search-keys
/tmp/yomi-bench-search-keys &
sample $! 5 -file /tmp/yomi-bench-search-keys.sample.txt
wait
```

The August 2026 profiling run used an Apple M4, arm64 macOS 26.5, Mojo 1.0.0
(`ed45d567`), three warmups, and 31 samples. The Japanese workload's dominant
avoidable costs were detached `String` copies during key deduplication and
repeated list growth. Comparing adjacent compiled runs in the same profiling
session, eliminating those copies and reserving scan-sized capacities changed
Japanese candidate generation from 159.449/212.316 ms p50/p95 to
115.826/153.044 ms: 27.4%/27.9% lower. Chinese and Korean absolute numbers were
too sensitive to concurrent machine load to publish as an optimization claim.

These results are development evidence, not permanent cross-machine marketing
claims. Record CPU, OS, Mojo version, compiler command, workload, warmup,
iterations, statistic, and machine load when adding a comparison.
