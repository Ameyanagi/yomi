# Architecture

Yomi owns CJK readings, romanization, keyboard forms, and the language-specific
phonetic facade. Moji owns generic text coordinates, transformed-to-source
mappings, and source projection.

The research basis, pinned upstreams, data licenses, target layers, and ordered
implementation gates are recorded in
[the reference architecture](reference-architecture.md).

## Dependency boundary

Allowed ecosystem dependencies: the Mojo standard library and, before Yomi
v0.1 release, a tagged packaged Moji with its stable mapping contract.
Expected downstream consumers: Yuragi and other CJK-aware search or indexing applications.

Dependencies point from applications and higher-level packages toward smaller
foundations. This repository must never import a downstream consumer. New
dependencies require a documented need and must not force unrelated users to
install an application, renderer, language layer, or scientific stack.

## Layers

Planned implementation areas: representation types; Korean Hangul, choseong, and keyboard logic; Japanese kana and romaji; Chinese pinyin and initials; deterministic generated tables.

The package root exports only the small documented public surface. Algorithms,
generated tables, platform details, and backend implementations remain in
their owning modules. Generic Mojo-native buffers, spans, strings, and
collections are preferred over an ecosystem-specific universal container.

## Data flow

Input validation occurs at the public boundary. Internal layers operate on
explicit typed values, produce deterministic outputs for deterministic inputs,
and report invalid state rather than silently replacing it with a default.
I/O, clocks, randomness, terminal queries, filesystem access, and accelerator
selection stay at explicit effect or backend boundaries.

## Representation contract

Public transformations return `PhoneticRepresentation`, not an untracked
`String`. The value owns both original source and transformed text. The current
Yomi-local `SourceMapping` and `SourceRange` values are temporary compatibility
types, not a stable second text foundation. Before v0.1 release,
`PhoneticRepresentation` composes Moji's mapped-text value and consumers import
nominal range/mapping types directly from `moji`.

Moji mapping spans cover the entire transformed output without gaps or
overlaps. Source and output spans must be in bounds and end on UTF-8 code-point
boundaries. Expansions and contractions are allowed; equal output and source
byte lengths are not assumed. Yomi owns only the language-specific decision
about which emitted span maps to which exact source span.

Mojo 1.0 does not enforce struct-field privacy, so underscore-prefixed storage
is a convention rather than an invariant boundary. Current compatibility reads
revalidate mapping storage; after integration, Moji owns that invariant while
Yomi revalidates its language policies and facade composition. Boundary
classification delegates to `StringSlice.is_codepoint_boundary()`. Yomi accepts
Mojo `String`/`StringSlice` values under their valid-UTF-8 contract; corrupting a
string through unsafe raw byte operations is outside the safe API contract.

The current `mapping_snapshot()` and `source_ranges_for_output()` methods remain
compatibility behavior only until the Moji integration gate. Moji owns
validate-once enumeration and match projection, including source-position
sorting, overlap/adjacency merging, and preservation of separate spans across a
gap. Any batch projection required by Yuragi lands in Moji first; Yomi does not
add a competing generic query.

Algorithms operate on extended grapheme clusters at the public text boundary.
An algorithm may inspect scalar values within a cluster, but pass-through text
is emitted and mapped as the original cluster so combining sequences and emoji
are not split accidentally. Choseong conversion treats a cluster beginning with
a modern precomposed Hangul syllable as one contraction: the base determines the
choseong, extenders are consumed, and the output maps to the complete cluster.
Canonical decomposed modern Hangul clusters beginning with U+1100..U+1112 use
the same compatibility-choseong view as their NFC syllable equivalents.

Hangul decomposition uses the Unicode algorithm for modern precomposed
syllables. It emits separate leading, vowel, and optional trailing Jamo
mappings, each pointing to the exact source syllable scalar. Any following
combining or extender scalars in that source grapheme pass through with their
own ranges; this prevents a match on an extender from broadening to the base
syllable. Already decomposed Jamo input passes through unchanged with one exact
mapping per scalar, giving NFC and NFD input the same transformed text without
requiring a normalization table.
