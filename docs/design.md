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

Korean search keys follow the same explicit-transform rule. Joined and spaced
romanization are separate `romanize_hangul` and `romanize_hangul_spaced`
functions, while `hangul_keyboard` names the Dubeolsik representation.
`hangul_choseong` remains the initials view. There is no public mode enum or
boolean combination to misconfigure.

The Hangul scanner performs one grapheme walk per requested representation and
appends directly into its final output and mapping buffers. The table dispatch
is branch-heavy Unicode control flow over variable-length outputs, not a
credible SIMD target. SIMD is reserved for measured fixed-width batch kernels;
it is not part of these scalar text APIs.

Chinese primary forms follow the same explicit-transform rule through
`pinyin_full`, `pinyin_joined`, and `pinyin_initials`. The one configurable
operation, `pinyin_representations`, uses a nominal `ChinesePolyphoneMode` and
an explicit output cap. Its generated table is fixed-width and scalar-sorted,
so lookup is binary search without table materialization. UTF-8 extraction and
polyphone substitution are branch-heavy and variable-length; they are not a
credible SIMD target. The cap prevents combinatorial alternatives, and the
common mode substitutes only one source scalar at a time.

Japanese finder forms use `japanese_kana_key`, `japanese_romaji_key`, and
`japanese_query_kana`; typed `japanese_search_keys` and `japanese_query_keys`
bundles add explicit compatibility kinds, capped ambiguity, reviewed
long-vowel and numeric query guesses, and algorithmic year/month readings.
`japanese_candidate_keys` combines required original/normalized keys and
generated keys behind one eight-key/1,024-byte default budget. Generated-only
candidate bundles are capped at six and query keys at eight.
`search_key_kinds_compatible` owns the
Yuru-aligned query/candidate gate. The bundles normalize compatibility width
once; the base normalizer documents a narrow supported subset rather than
claiming NFKC. Kind metadata carries the checked-in Yuru default score weights
without complicating constructors. Their UTF-8, IME-token, and variable-length emission paths are
branch-heavy and deliberately scalar.
Kanji dictionary keys compose at the returned-list seam only after a licensed,
versioned provider establishes tokenizer, ambiguity, unknown-word, cap, and
exact source-mapping contracts.

## Out of scope

Fuzzy scoring, terminal UI, filesystem traversal, and built-in full Japanese
morphology are outside the initial package.
