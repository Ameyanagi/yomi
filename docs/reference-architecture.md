# Reference architecture

This document records the research basis and target architecture for Yomi. It
is a design input, not permission to copy reference code or data. The reference
repositories live outside this repository, are not runtime dependencies, and
are pinned so later reviews can reproduce the observations below.

Research was performed on 2026-08-20. Runtime implementation remains pure Mojo;
generators may use development-only tooling when their inputs and outputs are
deterministic and fully attributed.

## Decisions

- Yomi exposes language-specific transformations. It does not detect an `auto`
  language, rank fuzzy matches, or choose a user's locale.
- Every concrete transformation returns source-preserving data rather than a
  bare string.
- Korean algorithmic transforms remain table-free. The Dubeolsik representation
  is a static reverse keyboard spelling, not a mutable input method.
- Kana romanization uses one versioned Yomi search profile. It does not inherit
  case-driven or boolean-option behavior from another library.
- Mandarin v0.1 exposes Unicode `kMandarin` customary readings through an
  explicitly named Hans or Hant selection policy. Its one or two regional
  values are not presented as general lexical polyphony.
- Unicode 17.0.0 is the only planned generated-data source for the first pinyin
  slice. Aggregated third-party reading databases remain excluded until every
  constituent source and transformation is licensed and checksum-pinned.
- The current Yomi-local mapping values are temporary compatibility types.
  Before v0.1 release, the language facade composes a tagged, packaged Moji
  mapping implementation and Yomi stops growing generic range or projection
  APIs.
- No reference code, lookup table, XML keyboard map, or test corpus is copied.

## Pinned reference inventory

The shallow clones are under
`/Users/ryuichi/dev/reference-libraries/yomi/`. Commit hashes, not moving
branches, identify the reviewed state.

| Reference | Pinned revision | Declared license | Reviewed surface |
| --- | --- | --- | --- |
| [`unicode-rs/unicode-normalization`](https://github.com/unicode-rs/unicode-normalization) | `576ae0b1407dd14854876c93f1a348df0c19dffe`, crate `0.1.25` | `(MIT OR Apache-2.0) AND Unicode-3.0` | UAX #15 iterator API, algorithmic Hangul decomposition in `src/normalize.rs`, Unicode 17.0.0 generator and conformance inputs in `scripts/unicode.py` |
| [`libhangul/libhangul`](https://github.com/libhangul/libhangul) | `a34aef73378c0992316861bbf13fc914ee7577d9`, configured version `0.2.0` | LGPL-2.1-or-later | `HangulInputContext`, key processing/preedit/commit separation, keyboard-map and combination layers, production Dubeolsik behavior |
| [`PSeitz/wana_kana_rust`](https://github.com/PSeitz/wana_kana_rust) | `d7b10aa3ec905827ff1241012721034f2da1f0ae`, crate `5.0.0` | MIT | `ConvertJapanese`, explicit options, longest-match node trees, mixed-text pass-through, kana edge-case tests |
| [`mozillazg/rust-pinyin`](https://github.com/mozillazg/rust-pinyin) | `0b471e19c6cd8756a861a27031bbfe984fc077b7`, crate `0.11.0` | MIT | per-scalar `ToPinyin`, feature-gated `ToPinyinMulti`, style projections, build-time compact generated arrays |

The Rust pinyin checkout pins its data submodule separately:

| Data reference | Pinned revision | Declared license | Provenance note |
| --- | --- | --- | --- |
| [`mozillazg/pinyin-data`](https://github.com/mozillazg/pinyin-data) | `fa9761fff402f8560196b1ba085c437c52b56d7c`, release `0.15.0` | MIT repository license | Aggregates Unicode 16.0.0 Unihan properties, CC-CEDICT-derived values, zdic material, standards-derived files, and manual overwrites. The repository-level license is not a substitute for a source-by-source data audit. It is a behavioral reference only. |

Relevant public reference APIs are:

- `UnicodeNormalization::{nfd,nfc,nfkd,nfkc}` and character composition;
- `hangul_ic_process`, `hangul_ic_backspace`, preedit/commit reads, and separate
  keyboard selection in libhangul;
- `ConvertJapanese::{to_romaji,to_kana,to_hiragana,to_katakana}` with an
  `Options` value in WanaKana Rust; and
- per-character `ToPinyin`, per-character `ToPinyinMulti`, and explicit output
  styles in rust-pinyin.

These APIs inform boundaries, not Yomi names or ownership rules.

## Normative inputs

Yomi's normative language facts come from versioned Unicode material rather
than a reference library's generated output.

| Input | Version and revision | SHA-256 | License/use |
| --- | --- | --- | --- |
| [The Unicode Standard, Chapter 3, §3.12](https://www.unicode.org/versions/Unicode17.0.0/core-spec/chapter-3/) | Unicode 17.0.0 | Published specification | Normative modern Hangul constants and arithmetic decomposition |
| [UAX #15](https://www.unicode.org/reports/tr15/tr15-57.html) | Unicode 17.0.0, revision 57, 2025-07-30 | Published specification | Normalization behavior and conformance model |
| [`NormalizationTest.txt`](https://www.unicode.org/Public/17.0.0/ucd/NormalizationTest.txt) | Unicode 17.0.0 | `5019ffd530751a741900c849c0e010332f142a3612234639bd200b82138a87db` | Development-only conformance corpus |
| [UAX #38](https://www.unicode.org/reports/tr38/tr38-39.html) | Unicode 17.0.0, revision 39, 2025-08-21 | Published specification | Unihan reading property syntax, ordering, and semantics |
| [`Unihan.zip`](https://www.unicode.org/Public/17.0.0/ucd/Unihan.zip) | Unicode 17.0.0 | `f7a48b2b545acfaa77b2d607ae28747404ce02baefee16396c5d2d7a8ef34b5e` | Generator input; only approved properties are extracted |
| `Unihan_Readings.txt` inside that archive | Unicode 17.0.0 | `575e69c9ad85a4737a889a4f94cbd987042a90a1a6cc16dd3f4ed995c715b17c` | `kMandarin` only for v0.1; any other property requires a later gate |
| [Unicode License v3](https://www.unicode.org/license.txt) | retrieved 2026-08-20 | `e7a93b009565cfce55919a381437ac4db883e9da2126fa28b91d12732bc53d96` | Notice must accompany redistributed derived data/documentation |

The Hangul algorithm uses the normative `SBase`, `LBase`, `VBase`, `TBase`,
`LCount`, `VCount`, and `TCount` constants already recorded in
[`data-provenance.md`](data-provenance.md). It does not need generated Unicode
tables. Pinyin generation initially accepts only reviewed fields from
`Unihan_Readings.txt`; it must not ingest the pinyin-data aggregate.

The Dubeolsik authority is
[`KS X 5002:2007`, *Keyboard layout for information processing*](https://www.kssn.net/search/stddetail.do?itemNo=K001010123285),
reaffirmed as `KS X 5002(2023 확인)` by the Korean Standards Association on
2023-12-08. The standard text is not redistributed. Before implementation,
`data/policies/dubeolsik-v1.md` must record every independently expressed
unshifted and shifted key mapping, the reviewed standard edition and clauses,
reviewer/date, independently authored expected fixtures, and the manifest
SHA-256. Libhangul and CLDR may identify disagreements for review but are not
table sources.

`KanaRomanization.search_v1()` is a Yomi-authored interoperability policy, not
a transcription of WanaKana or another romanizer. Before implementation,
`data/policies/kana-search-v1.md` must record every token and output decision,
the rationale for edge cases, independently authored expected fixtures, the
pinned WanaKana differential result and every accepted divergence, and the
manifest SHA-256. The manifest and resulting table are licensed with Yomi.

## Transformations versus language policy

The transformation engine answers a mechanical question:

```text
owned source span + explicit policy
    -> one or more output spans
    -> exact mappings back to the owned source
```

It must not answer application questions such as which language to try, which
reading is most likely in context, whether case-insensitive matching is enabled,
or how alternatives are ranked. Yuragi owns `auto` language routing. Hibana
owns scoring. Moji owns generic text coordinates, mapping construction, and
source projection once its tagged mapping contract is available. Until that
integration gate, Yomi's current mapping implementation is frozen compatibility
code rather than a second permanent foundation.

Policy values are nominal and required at boundaries where multiple reasonable
answers exist:

- Dubeolsik has one named v0.1 layout. Unshifted keys are lowercase and shifted
  tense consonants use uppercase; Yomi does not case-fold them.
- `KanaRomanization.search_v1()` names Yomi's stable search spelling. It is
  kana-to-romaji only, treats hiragana and katakana equivalently, uses lowercase
  ASCII, expands yoon and sokuon, expands a prolonged sound mark from its
  preceding vowel, emits syllabic `n` without an apostrophe, and passes unmapped
  graphemes through exactly. A complete reviewed table must land before this
  policy is implemented.
- Pinyin style is applied only after customary reading selection. Planned
  styles are canonical tone marks, plain Unicode with `ü`, keyboard ASCII with
  `ü -> v`, and initials. There is no default style.
- `ReadingSelection.unihan_mandarin_hans()` explicitly chooses the first
  `kMandarin` value, the preferred customary pronunciation for zh-Hans/CN.
  `ReadingSelection.unihan_mandarin_hant()` chooses the second value when UAX
  #38 supplies one for zh-Hant/TW, otherwise the sole value. Yomi has no default
  locale. `mandarin_readings()` preserves the one or two regional values in
  stable Unicode source order. It does not claim to enumerate every lexical
  pronunciation. Lexical polyphony and phrase-level disambiguation are
  post-v0.1 and require a separate property/provenance/semantics gate.
- Simplified and traditional characters are looked up independently. Yomi does
  not silently convert one to the other.

Unknown or unsupported graphemes pass through with exact mappings. They are
never dropped, replaced with an empty string, or guessed from another language.

## Target layers

```text
public language facade
    -> nominal policy and reading-selection values
        -> Korean / kana / Mandarin transformation engines
            ├── private algorithm constants or generated lookup views
            └── thin language-emission adapter
                    -> packaged Moji mapped-text builder and projection

development-only generators
    -> pinned licensed inputs
        -> deterministic private Mojo tables + provenance manifest
```

### Public language facade

Exports stable semantic values and language-specific entry points. It does not
export generated table shapes, scanners, keyboard maps, or builder internals.

### Policy values

Hold versioned choices without boolean combinations. Invalid or externally
mutated policy discriminants raise before transformation.

### Language engines

Operate on valid UTF-8 source spans. Korean uses arithmetic decomposition and a
reviewed keyboard spelling. Kana uses a longest-supported-sequence scanner.
Mandarin uses private scalar-indexed reading records.

### Mapping integration

Moji owns generic output assembly, range validation, cursor invariants, and
source projection. Yomi's thin adapter appends language-specific emitted spans
and their exact source spans. The current local builder exists only until the
mandatory Moji integration gate and must not gain batch projection or new
public range types.

### Private tables

Expose typed internal lookup functions, not raw arrays. Table layout may change
without affecting the root API.

### Generators

Live outside runtime modules. They validate input syntax, sort deterministically,
reject duplicate or conflicting records, and emit byte-identical output.

## Exact source mappings

The existing `PhoneticRepresentation` contract remains the temporary facade:

- source and output are owned UTF-8 strings;
- mappings use non-empty half-open byte ranges;
- mappings cover the full output without gaps or overlaps;
- every boundary is a UTF-8 code-point boundary;
- expansions may emit several output spans for one source span;
- contractions may emit one output span for several source scalars; and
- pass-through text retains its exact source span.

At the mandatory Moji integration gate, `PhoneticRepresentation` composes
Moji's owned mapped-text value. Moji range and mapping values replace the
current Yomi-local `SourceMapping` and `SourceRange` compatibility types; they
are imported from `moji`, not re-exported from the Yomi package root. Yomi
retains only language-specific construction and result semantics.

Language-specific mapping rules are:

- each Jamo or Dubeolsik key emitted from a precomposed Hangul syllable maps to
  that syllable scalar, while already decomposed Jamo map to their own scalars;
- a kana sequence consumed as one romanization token maps the complete output
  token to the complete source sequence;
- a pinyin syllable or initial maps to exactly one source ideograph in v0.1;
  phrase readings may map a longer source range only in a later reviewed layer;
- combining extenders that pass through retain separate exact ranges unless a
  documented contraction intentionally consumes the full grapheme; and
- a reading selection builds a normal `PhoneticRepresentation`, so downstream
  matching never needs to interpret generated-table offsets.

The one-range `source_ranges_for_output()` behavior remains useful, but generic
projection belongs to Moji. If Yuragi needs ordered or unordered batch
projection, that API lands and is tested in Moji before Yomi consumes it. Yomi
does not add a competing batch query. Projection must sort source ranges and
merge only overlap or adjacency; it never replaces discontiguous matcher
positions with one bounding highlight.

## Regional customary Mandarin readings

A bare `String` cannot preserve the regional choice encoded by `kMandarin`.
The v0.1 target is a source-owned customary-reading sequence:

```text
MandarinReadings
├── owned source text
└── ordered MandarinReadingUnit values
    ├── exact source byte range
    └── one or two ordered RegionalReading values
        ├── canonical syllable
        └── Hans/Hant applicability from kMandarin order
```

`MandarinReadings` provides inspected counts and checked copies. Selection
requires a named Hans or Hant `ReadingSelection` plus a `PinyinStyle`, and
returns a `PhoneticRepresentation`. It does not accept per-unit alternative
indices, because `kMandarin` does not enumerate lexical alternatives. No method
named `default`, `best`, or `first` is exported.

The order recorded by `kMandarin` is preserved as regional data and is not
reinterpreted as frequency or context probability. Style projections are
derived only during selection, so a canonical reading unit does not store
duplicated derived spellings. Richer lexical alternatives require a post-v0.1
proposal that approves specific properties or data sources, their semantics,
licensing, merge rules, and bounded public representation.

## Minimal Mojo API target

This is the intended small surface, not an implemented API promise:

```mojo
from yomi import (
    KanaRomanization,
    PinyinStyle,
    ReadingSelection,
    decompose_hangul,
    hangul_choseong,
    hangul_dubeolsik,
    mandarin_readings,
    romanize_kana,
)

var keys = hangul_dubeolsik("한국")
var kana = romanize_kana("カメラ", KanaRomanization.search_v1())

var readings = mandarin_readings("北京大学")
var selected = readings.select(
    ReadingSelection.unihan_mandarin_hans(),
    PinyinStyle.keyboard_ascii(),
)
```

`PhoneticRepresentation` remains Yomi's public language-specific facade. The
current `SourceMapping` and `SourceRange` exports are explicitly temporary and
leave the root API at the mandatory Moji integration gate. Consumers import
Moji's nominal ranges and mapping values from `moji` rather than through Yomi.
`MandarinReadings` and its detached unit/regional-reading snapshots become
public only when the customary-reading slice is implemented. Generated records,
trie nodes, mapping builders, and language classifiers remain internal.

No root API accepts `lang="auto"`, a bag of boolean conversion options, an
untyped integer style, or a callback into application scoring.

## Ownership, mutation, and errors

- Results own source, output, mappings, reading units, and selected regional
  reading text. They do not borrow generated storage through a public lifetime.
- Static generated tables are immutable implementation data. Lookup copies the
  small semantic record needed by the public result.
- Mojo 1.0 underscore-prefixed fields are externally reachable. Every public
  semantic read revalidates current text, ranges, ordering, policy discriminants,
  regional-reading counts, and selection applicability.
- Snapshot APIs validate once and return detached copies for linear iteration.
- User-controlled invalid ranges, unsupported policy values, corrupted reachable
  storage, and inapplicable regional selections raise `Error`; they do not panic,
  clamp, or fall back to a different language.
- Valid but unknown text passes through. Invalid UTF-8 created through unsafe
  raw-byte mutation remains outside the safe `String`/`StringSlice` contract.
- Pure transformations perform no file I/O, locale queries, global mutation,
  network access, or table generation.

## Generated-table and license boundary

Generated artifacts must be reviewable without installing their generator.
Each generated file and manifest records:

- canonical input URL, Unicode/data version, retrieval date, byte size, and
  SHA-256;
- the exact properties accepted and rejected;
- the upstream license identifier and a committed notice copy;
- generator source revision, pinned environment, and one documented command;
- deterministic sort/deduplication rules and output SHA-256; and
- a semantic diff summary when the input version changes.

The generator writes private Mojo under `src/yomi/_generated/` and a manifest
under `data/`. Generated output is committed; consumers do not need Python,
Rust, C, a network connection, or the source archive.

For the first Mandarin slice, only Unicode 17.0.0 `Unihan_Readings.txt` is
approved. `kMandarin` provides one customary reading, or two values ordered for
zh-Hans/CN then zh-Hant/TW. Selection is therefore explicitly locale-scoped;
it is not a universal primary-reading claim. Additional Unihan reading
properties require a separate post-v0.1 provenance and semantics proposal
before Yomi claims lexical alternatives. The Unicode License v3 notice ships
with derived data.

The following are prohibited without a new provenance review:

- copying libhangul's LGPL keyboard XML or C tables;
- copying WanaKana Rust node trees or conversion fixtures;
- copying rust-pinyin generated arrays or build script; and
- importing the pinyin-data aggregate merely because its repository declares
  MIT. Its named inputs have independent provenance and licensing conditions.

The Dubeolsik and kana policy tables must be independently authored and reviewed
entry by entry through their required manifests. The Dubeolsik manifest pins
`KS X 5002:2007`, reaffirmed in 2023; the kana manifest identifies search-v1 as
Yomi-authored and records every differential disagreement. A reference library
may serve as a differential oracle during development but is never linked,
invoked by consumers, or used to generate distributable tables.

## Adopted and rejected ideas

### unicode-normalization

Adopt:

- arithmetic Hangul decomposition before general table lookup;
- a small public iterator/value surface over private generated data;
- an explicit Unicode version constant and official conformance corpus; and
- generator outputs checked into source control.

Reject:

- whole-string NFD as Yomi's implementation shortcut, because Yomi must retain
  exact pre-transformation source ranges and must not reorder unrelated marks;
- importing the Rust crate or reproducing its unsafe/internal layout; and
- claiming full Unicode normalization conformance for language-specific views.

### libhangul

Adopt:

- separate keyboard mapping, Jamo combination, and state-machine concepts;
- explicit processing state and commit/preedit terminology as a test oracle;
- exhaustive key and syllable transition fixtures; and
- the production evidence that Dubeolsik case/shift distinctions matter.

Reject:

- C/FFI or a runtime libhangul dependency;
- a mutable IME context for Yomi's static reverse keyboard representation;
- runtime XML keyboard loading and user-global keyboard registries; and
- copying LGPL source or keyboard data.

### WanaKana Rust

Adopt:

- longest-match scanning for multiscalar kana sequences;
- explicit handling of yoon, sokuon, prolonged marks, syllabic `n`, half-width
  forms, punctuation, and mixed pass-through text; and
- property tests that arbitrary Unicode input does not panic.

Reject:

- returning only `String` without source mappings;
- case-driven selection of hiragana versus katakana output;
- a broad boolean `Options` bag and custom callback maps in the stable core;
- bundling script detection, tokenization, and okurigana trimming with the
  romanizer; and
- copying its node trees, which originated in WanaKana 4.0.2 and later diverged.

### rust-pinyin and pinyin-data

Adopt:

- a distinct per-scalar regional-customary-reading view for v0.1;
- style projections over one canonical reading record;
- compact deterministic scalar-indexed tables; and
- evidence for a later, separately reviewed lexical-alternative representation.

Reject:

- flattening away unknown characters;
- silently selecting a Hans or Hant customary reading;
- building tables during consumer installation;
- exposing generated array/index layout; and
- using a mixed aggregate data file before every constituent license and merge
  rule passes Yomi's provenance gate.

## Tests and corpora

### Shared mapping invariants

- empty, ASCII, emoji, combining, mixed-script, and invalid-index cases;
- complete output coverage and UTF-8 boundaries;
- expansion, contraction, pass-through, reordered source spans, and exact
  discontiguous projection through the packaged Moji contract;
- direct mutation of every reachable text, range, policy, and regional-reading
  field;
- detached snapshots that cannot mutate their owner; and
- installed-package tests importing only the documented root surface.

Until the Moji integration gate, compatibility tests retain the existing Yomi
mapping invariants. After the gate, Moji owns generic invalid-range, coverage,
mutation, and projection tests; Yomi tests only its language-emission adapter,
exact language-specific spans, facade ownership, and installed-package
composition.

### Korean

- retain the independent mixed-radix oracle over all 11,172 modern syllables;
- check all 399 LV and 10,773 LVT decompositions and exact source mappings;
- select relevant Unicode 17.0.0 normalization cases without claiming a full
  normalizer;
- cover all Dubeolsik key entries, shifted tense consonants, compound vowels and
  trailing consonants, NFC/NFD equivalence, isolated Jamo, and mixed text; and
- differentially compare a development-only corpus with pinned libhangul, while
  keeping the committed expected fixtures independently authored.

### Kana

- enumerate every supported single kana and multiscalar token in the reviewed
  search-v1 table;
- cover hiragana/katakana equivalence, dakuten/handakuten, yoon, sokuon before
  every supported onset, prolonged marks after every vowel, syllabic `n`, small
  kana, half-width input policy, punctuation, and unknown pass-through;
- assert exact source ranges for every contraction and expansion; and
- use independently written expected values, with WanaKana Rust only as a
  differential signal for disagreements requiring review.

### Mandarin

- verify the input and generated output checksums in a clean checkout;
- test UAX #38 parsing, stable property order, duplicate normalization, tone
  marks, neutral tone, `ü`, each output style, unknown characters, and
  simplified/traditional independence;
- cover both one-value and two-value `kMandarin` records, prove exact Hans/Hant
  selection ordering, and reject any call that omits the locale policy;
- verify that `重`, `行`, and `还` expose only their Unicode 17 `kMandarin`
  customary reading and are not mislabeled as exhaustive lexical alternatives;
- prove `北京大学 -> beijingdaxue` and initials `bjdx`, with each emitted syllable
  and initial mapping to its exact source ideograph; and
- test a clean regeneration for byte-identical Mojo and manifest output.

Reference corpora are inputs to tests only when their license permits
redistribution. Otherwise, the repository stores independently authored minimal
fixtures and records the oracle command/mismatch review outside runtime code.

## Issue order and gates

Each item is one reviewable issue with code, focused tests, documentation, and
an installed-package smoke whenever the root API changes.

1. **K1.1 Dubeolsik contract:** commit the `KS X 5002:2007`-pinned decision and
   differential manifest, then approve the independently authored layout,
   canonical key spelling, compound rules, and complete fixtures; no runtime API.
2. **K1.2 Dubeolsik representation:** add `hangul_dubeolsik` through the shared
   mapping builder and the full Korean mapping suite.
3. **K1.3 Korean exit gate:** run exhaustive decomposition, keyboard, mutation,
   package, and downstream contract checks before any kana runtime code.
4. **J0.1 Kana search-v1 policy:** commit the Yomi-authored decision and
   differential manifest, then approve the complete table and edge-case corpus,
   including exact mapping expectations.
5. **J0.2 Kana scanner:** implement `KanaRomanization` and `romanize_kana` with
   longest-match scanning and no generated or external runtime dependency.
6. **J0.3 Kana exit gate:** exhaust the supported table, mixed text, mutation,
   packaging, and mapping invariants before pinyin runtime code.
7. **C0.1 Unihan provenance lock:** commit the Unicode license notice, manifest,
   checksum verifier, property allowlist, and generator specification.
8. **C0.2 Customary-reading contract:** implement owned regional reading units,
   nominal selection/style values, snapshots, mutation checks, and selection
   into `PhoneticRepresentation` without tables or explicit alternative indices.
9. **C0.3 Generated Mandarin tables:** generate private deterministic Mojo from
   approved Unicode 17.0.0 fields and prove clean byte-identical regeneration.
10. **C0.4 Pinyin selection/projections:** connect canonical regional readings
    to explicit Hans/Hant selection and canonical, plain Unicode, keyboard ASCII,
    and initials styles with exact source mappings.
11. **M0.1 mandatory Moji integration:** depend on a tagged `mojo-moji`
    distribution through the `moji` import,
    compose its mapped-text/range/projection values behind Yomi's language
    facade, remove Yomi's temporary mapping exports, and prove clean-prefix
    installation without a sibling checkout. Any required batch projection lands
    in Moji first. This gate blocks Yomi v0.1 release.
12. **C0.5 v0.1/downstream gate:** prove regional customary selection, unknown
    pass-through, `北京大学`/`bjdx`, discontiguous highlights, and installed
    packaging. The pinned Yuragi integration runs in Yuragi or an external
    integration matrix and consumes packaged Yomi and Moji artifacts only.
13. **D0 separate proposal:** evaluate Japanese dictionary sources, tokenization,
    phrase boundaries, licensing, table size, and update cadence. No dictionary
    or morphology implementation starts under the v0.1 architecture.

Until M0.1, Yomi must not import sibling source or expand its generic mapping
surface. The release gate uses the normal package dependency path only. Yomi
never imports Yuragi; the downstream integration owner installs Yomi and Moji
as packages.

Lexical Mandarin alternatives are a separate post-v0.1 proposal. It must name
the exact additional property or source, pin provenance and licenses, define
merge/order semantics, bound result growth, and add independent ambiguity tests
before any public API or table changes.

## Reproducing the reference checkout

The reviewed repositories were acquired with shallow clones and then identified
by full commit hash:

```sh
git clone --depth 1 https://github.com/unicode-rs/unicode-normalization.git
git clone --depth 1 https://github.com/libhangul/libhangul.git
git clone --depth 1 https://github.com/PSeitz/wana_kana_rust.git
git clone --depth 1 https://github.com/mozillazg/rust-pinyin.git
git -C rust-pinyin submodule update --init --depth 1 pinyin-data
```

Before using the observations for a later change, verify each full SHA from the
inventory and re-review any changed license, generator input, or public API.
