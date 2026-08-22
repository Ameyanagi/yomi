# Roadmap

## v0.1 — Foundation

- Stabilize the source-mapping builder and matched-range query.
- Maintain completed Hangul decomposition, romanization, choseong search, and
  Dubeolsik keyboard forms against downstream Yuragi fixtures.
- Add kana romanization only after the Korean exit gate passes.
- Add deterministic licensed pinyin and initials tables after the kana gate.
- Represent alternative readings explicitly rather than choosing silently.
- Prove Yuragi's `bjdx` target preserves exact `北京大学` source ranges.
- Add unit, reference-value, exhaustive, and mapping-invariant coverage.
- Build and test the precompiled package on supported targets.

## v0.2 — Usability

- Add ergonomic multilingual APIs only after v0.1 downstream usage evidence.
- Maintain the fixed Japanese finder-key bundle and provider seam against
  Yuru/Yuragi integration fixtures.
- Maintain typed compatibility gates and the strict six-generated/eight-query
  caps against Yuru/Yuragi integration fixtures.
- Maintain unified candidate count/byte budgets and score-weight metadata
  against the checked-in Yuru source.
- Expand supported reading data without changing ambiguity semantics silently.
- Expand examples and Yuragi integration fixtures.
- Publish the first modular-community recipe when the package is useful alone.

## v0.3 — Performance

- Maintain the profiler-oriented CJK benchmark and add representative,
  licensed datasets as their provenance can be checked in.
- Optimize measured bottlenecks without weakening correctness or API clarity.
- Add SIMD or specialized backends only behind the same semantic contract.

## v1.0 — Stability

- Document every public symbol and error contract.
- Provide a compatibility and deprecation policy.
- Support the declared OS and architecture matrix in CI.
- Require downstream proof from at least one independent consumer.

## Not planned

Fuzzy scoring, terminal UI, filesystem traversal, and full Japanese morphology are outside the initial package.

The ordered deliverables, acceptance criteria, and immediate task queue live in
[the implementation plan](implementation-plan.md).
