# Architecture

Yomi owns CJK readings, romanization, keyboard forms, and source-preserving phonetic representations.

## Dependency boundary

Allowed ecosystem dependencies: Moji after its mapping contract stabilizes; the v0.1 foundation otherwise uses only the Mojo standard library.
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
