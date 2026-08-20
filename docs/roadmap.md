# Roadmap

## v0.1 — Foundation

- Keep the current mapping implementation as temporary compatibility code,
  then compose tagged packaged Moji mapping/range/projection values before
  release.
- Complete Hangul decomposition, choseong search, and Dubeolsik keyboard forms.
- Add kana romanization only after the Korean exit gate passes.
- Add deterministic licensed pinyin and initials tables after the kana gate.
- Preserve Unicode `kMandarin` regional customary readings and require explicit
  Hans/Hant selection; do not claim lexical polyphony in v0.1.
- Prove in a Yuragi-owned or external package-only integration that `bjdx`
  preserves exact `北京大学` source ranges.
- Add unit, reference-value, exhaustive, and mapping-invariant coverage.
- Build and test the precompiled package on supported targets.

## v0.2 — Usability

- Add ergonomic multilingual APIs only after v0.1 downstream usage evidence.
- Expand supported reading data without changing regional-selection or future
  lexical-alternative semantics silently.
- Expand examples and Yuragi-owned/package-only integration fixtures.
- Publish the first modular-community recipe when the package is useful alone.

## v0.3 — Performance

- Add reproducible benchmarks and representative datasets.
- Optimize measured bottlenecks without weakening correctness or API clarity.
- Add SIMD or specialized backends only behind the same semantic contract.

## v1.0 — Stability

- Document every public symbol and error contract.
- Provide a compatibility and deprecation policy.
- Support the declared OS and architecture matrix in CI.
- Require downstream proof from at least one independent consumer.

## Not planned

Fuzzy scoring, terminal UI, filesystem traversal, full Japanese morphology, and
lexical Mandarin polyphony without a separate provenance/semantics proposal are
outside the initial package.

The ordered deliverables, acceptance criteria, and immediate task queue live in
[the implementation plan](implementation-plan.md).
