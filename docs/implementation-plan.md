# Implementation plan

This plan turns the language order and source-mapping contract into reviewable
vertical slices. Work proceeds strictly in this order:

```text
representation contract
    -> Korean
    -> Japanese kana
    -> Chinese pinyin
    -> Japanese dictionary readings (later)
```

A later phase may be designed while an earlier phase is underway. The
ecosystem-wave adjudication explicitly starts J0 kana work while K1's
Dubeolsik representation remains open; other runtime phases still wait for the
preceding exit gate.

## Definition of done for every slice

A slice is complete only when it has:

- a narrow root export and API documentation;
- reference cases and UTF-8 edge-case tests;
- mapping-invariant tests for every transformation and pass-through path;
- a compilable public example;
- no Python, Rust, C, or C++ runtime dependency;
- `pixi run check` passing on the pinned Mojo compiler;
- an installed-package smoke test when the root API changes;
- updated compatibility, provenance, and changelog notes when applicable.

## Mapping contract

`PhoneticRepresentation` owns source text, transformed UTF-8 text, and ordered
`SourceMapping` values. Each mapping uses half-open byte ranges:

```text
[output_start, output_end) -> [source_start, source_end)
```

The invariants are:

1. output and source ranges are non-empty UTF-8 boundary ranges;
2. mappings are ordered by output start;
3. mappings cover transformed output from byte zero without gaps or overlaps;
4. a transformed expansion may create multiple mappings to one source range;
5. a transformed contraction may map one output range to a larger source range;
6. pass-through grapheme clusters retain their exact source range;
7. empty input produces empty output and no mappings.

Construction rejects negative or empty spans, transformed-text gaps or
overlaps, incomplete coverage, and source or output ranges that are out of
bounds or end inside a UTF-8 scalar. Reads trust construction-validated values.
Because Mojo 1.0 does not enforce field privacy, direct underscore-field
mutation is out of contract and `validate()` is the explicit checkpoint after
unusual low-level work.

`mapping_snapshot()` returns a detached list for linear-time enumeration.
`source_ranges_for_output()` converts a valid non-empty output match to
source-ordered exact ranges. It binary-searches the first overlapping mapping,
sorts selected source ranges with the standard library, and merges ranges that
overlap or touch. It never bridges a gap or replaces discontiguous highlights
with one bounding range. Yuragi must exercise that behavior at its mapping gate.

## K0 — Representation and choseong (implemented)

Deliverables:

- `SourceMapping` and `PhoneticRepresentation`;
- checked construction that enforces transformed-output mapping invariants;
- owned source context, construction validation, trusted reads, and an explicit
  validation checkpoint;
- detached mapping snapshots and exact discontiguous source projection;
- `hangul_choseong(text)` for precomposed Hangul syllables;
- compatible choseong views for canonical decomposed modern Hangul;
- compatibility choseong for all 19 leading consonants;
- grapheme-preserving pass-through for mixed non-Hangul text and explicit
  contraction of a precomposed Hangul base plus extenders to one choseong;
- empty, mixed ASCII/CJK/emoji/combining-mark, decomposed-Jamo, and invalid
  mapping-index tests.

Exit gate: the public example demonstrates `ㅎㄱ notes` from `한국 notes` and
prints the exact byte mappings; the full locked check passes.

## K1 — Complete Korean v0.1

Status: in progress. Algorithmic decomposition, canonical composition, and the
exhaustive round-trip oracle are implemented; the Dubeolsik representation
remains open.

Deliverables:

- algorithmic Hangul syllable decomposition into canonical leading, vowel,
  and optional trailing Jamo (implemented);
- canonical `compose_hangul` contraction for modern conjoining Jamo and
  precomposed LV syllables followed by trailing Jamo (implemented);
- choseong recognition for both precomposed syllables and canonical Jamo input;
- Dubeolsik keyboard representation with an explicitly documented layout;
- APIs that distinguish representation kind rather than accepting ambiguous
  boolean option combinations;
- mappings for one-to-many decomposition and keyboard output;
- exhaustive generated tests over all 11,172 modern precomposed syllables,
  plus isolated Jamo, compatibility Jamo, mixed scripts, and boundaries.

Exit gate: the compose/round-trip portion is satisfied via `compose_hangul`:
decomposition followed by composition recovers all 11,172 modern Hangul
syllables, and every contracted output maps to the full decomposed source
slice. K1 remains open until the Dubeolsik representation and its mapping gate
are complete.

## J0 — Japanese kana v0.1

Status: romanization, script converters, per-language examples, and review
artifacts are complete and pass the full locked check on the pinned toolchain.

Deliverables:

- deterministic hiragana and katakana romanization (implemented);
- equivalent treatment of script variants where the documented scheme says
  they are equivalent (implemented);
- explicit behavior for small kana, yoon pairs, sokuon, prolonged sound marks,
  syllabic `ん`, punctuation, and unmapped graphemes (implemented);
- mapping coverage for expansions and contractions such as a kana pair mapping
  to one romanized syllable (implemented);
- `to_hiragana` and `to_katakana` with one-scalar mappings, NFC/NFD voicing
  agreement, and exact grapheme pass-through (implemented);
- reference fixtures that state the chosen romanization convention
  (implemented in `docs/romanization.md` and the exhaustive checked-in fixture);
- Korean and Japanese finder-oriented examples ending in exact source-range
  projection (implemented).

Exit-gate evidence includes the 399-row fixed-output fixture table, the 52-row
NFC/NFD voicing table, full script-conversion sweeps, and the `ラーメン屋`
`raamen` projection from output bytes `[0, 6)` to source bytes `[0, 12)`.
Unmapped text passes through losslessly and mapping tests recover exact
original ranges. This gate opens the pinyin phase; it does not complete v0.1.

## C0 — Chinese pinyin v0.1

Begins only after J0 exits. Pinyin requires licensed versioned reading data and
therefore follows the generated-data policy.

Deliverables:

- a documented policy for simplified/traditional forms, tones, neutral tone,
  `ü`, polyphonic characters, and unknown characters;
- deterministic generated Mojo lookup tables with upstream version, retrieval
  date, license, checksums, generator command, and reproducibility check;
- full pinyin and initials representations with exact source mappings;
- an API that can return alternative readings without choosing silently;
- compact table-size and lookup benchmarks using checked-in methodology.

Exit gate: a clean checkout can reproduce byte-identical tables, consumers need
only the Mojo package, ambiguity/reference fixtures pass, and Yuragi can prove
`北京大学` maps from `beijingdaxue`/`bjdx` matches to the four exact original
source-character ranges. This gate completes the v0.1 language surface.

## D0 — Japanese dictionary readings (post-v0.1)

This phase requires a separate design review covering dictionary licensing,
tokenization boundaries, unknown-word policy, table size, and update cadence.
Full morphological analysis remains outside Yomi unless explicitly approved.

## Immediate next tasks

1. Specify and implement the Dubeolsik keyboard representation.
2. Run the J0 host compiler and test gate on the pinned Mojo toolchain.
3. Complete the Korean and kana exit gates before adding generated pinyin data.
4. Complete pinyin/initials provenance, ambiguity, mapping, and Yuragi `bjdx`
   integration evidence before declaring v0.1.
