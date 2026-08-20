# Design

## Principles

- Mojo is the runtime implementation language.
- Prefer pure Mojo and safe standard-library APIs.
- Keep the root API small, typed, documented, and testable.
- Separate semantic contracts from optimized CPU, SIMD, GPU, terminal, or
  rendering backends.
- Establish correctness and reference fixtures before optimization.
- Make invalid public configuration unrepresentable when practical; otherwise
  reject it explicitly.
- Validate semantic invariants at construction and trust values on subsequent
  reads. Direct underscore-field mutation is out of contract; public
  `validate()` methods provide explicit checkpoints for unusual low-level work.
- Preserve source mappings, numerical tolerances, ownership, and provenance as
  first-class data when the domain requires them.
- Do not add a framework-wide array, executor, renderer, or application model.

## Tradeoffs

The project accepts a narrower initial feature set in exchange for reviewable
contracts and sparse dependencies. Generated tables are acceptable when their
sources, Unicode or data version, licenses, checksums, and deterministic update
procedure are committed. Consumers must not need the generator toolchain.

Kana romanization exposes one documented, ASCII, wapuro-flavored modified
Hepburn scheme. It deliberately has no options value: accepting knobs would
make a representation's meaning depend on hidden configuration and would
multiply the mapping fixtures before a second reviewed convention exists.
The scanner first builds source-aware kana units, keeping table selection
separate from the per-string walk so a future `Span` batch overload can reuse
the semantics.

Transformation names describe their direction. `romanize_kana` uses the
verb-object form because it changes script into a representation.
`to_hiragana` and `to_katakana` are explicit script converters; they are not
romanization aliases and accept no width or romaji options.

## Out of scope

Fuzzy scoring, terminal UI, filesystem traversal, and full Japanese morphology are outside the initial package.
