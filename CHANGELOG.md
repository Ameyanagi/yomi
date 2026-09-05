# Changelog

This project follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/)
and uses semantic versioning for public releases.

## [Unreleased]

### Fixed

- Keep Japanese query whitespace trimming on valid UTF-8 boundaries, including
  native kana, other multibyte text, and trailing ASCII spaces or tabs. Existing
  normalization, key ordering, and exact source mappings are preserved.

## [0.1.1] - 2026-08-22

### Added

- Add typed, root-exported `chinese_candidate_keys` and `chinese_query_keys`
  front doors with exact source mappings, deterministic common polyphones,
  `(kind, text)` candidate deduplication, coverage-aware query deduplication,
  and generation-time count/byte budgets.
- Add spaced Hangul romanization to `korean_candidate_keys` while retaining a
  five-key hard cap and the shared generated-byte budget.
- Add consuming `SearchKey.take_representation()` and
  `SearchKeyBundle.take_keys()` accessors for allocation-sensitive pipelines.

### Changed

- Move Japanese compatibility wrappers onto the consuming key accessors so
  owned representations are transferred instead of detached and copied.
- Benchmark the unified Chinese candidate-key path and expand package smoke
  coverage to the new typed APIs.

## [0.1.0] - 2026-08-22

### Changed

- **Breaking:** Rename `romanize_kana` to `to_romaji`, completing the
  `to_romaji` / `to_hiragana` / `to_katakana` conversion family.
- **Breaking:** Make kana conversion, Hangul composition and decomposition,
  and choseong transforms non-raising; validating public representation and
  mapping constructors remain raising.

### Added

- Initial experimental repository scaffold.
- Add source-preserving phonetic representation values.
- Add precomposed Hangul choseong conversion with exact UTF-8 byte mappings.
- Reject invalid mapping spans and incomplete transformed-output coverage.
- Own source text and validate both sides of every mapping at construction,
  with trusted non-raising reads and an explicit `validate()` checkpoint.
- Define precomposed Hangul plus combining-extender choseong behavior.
- Add canonical decomposed leading-Jamo choseong equivalence.
- Add detached mapping snapshots and exact output-to-source range projection
  without bridging discontiguous highlights.
- Add algorithmic canonical decomposition for all 11,172 modern Hangul
  syllables with exact expansion mappings and NFC/NFD-equivalent output.
- Add canonical Hangul composition with exact many-source-to-one-syllable
  mappings and an exhaustive 11,172-syllable round-trip oracle.
- Accept compatibility Jamo U+3131--U+3163 in `compose_hangul`, including
  vowel lookahead when a consonant could trail one syllable or lead the next.
- Add `decompose_hangul_compatibility` for visible, keyboard-typable Jamo with
  exact expansion mappings.
- Add joined and spaced deterministic Hangul romanization plus Dubeolsik
  keyboard representations with NFC/NFD equivalence and exhaustive modern
  syllable mapping coverage.
- Add explicit unmapped output spans for generated separators and ignore them
  during output-to-source projection.
- Add allocation-free Hiragana, Katakana, Kana, base-block Kanji, and modern
  precomposed Hangul routing predicates.
- Add `is_hangul_jamo` for modern conjoining and compatibility Jamo routing.
- Add source-preserving `to_romaji` with one documented ASCII
  wapuro-flavored modified Hepburn scheme, NFC/NFD voicing equivalence,
  exhaustive fixed-unit fixtures, and exact contextual kana mappings.
- Add source-preserving `to_hiragana` and `to_katakana` conversion with
  NFC-canonicalized kana voicing contractions and exact pass-through mappings.
- Add Yuru-compatible Japanese kana/romaji finder keys, common IME query
  aliases, and fixed algorithmic Arabic-numeral year/month representations.
- Add typed search-key bundles and Yuru-compatible query/candidate gates, plus
  strictly capped Japanese ambiguity and long-vowel query fanout with exact
  source-byte mappings.
- Add one budgeted `korean_candidate_keys` front door for original,
  romanized, choseong, and Dubeolsik finder keys.
- Add a compiled, profiler-oriented CJK key benchmark and remove measured
  Japanese deduplication and scan-buffer allocation overhead.
- Add learned-alias kind coverage, checked-in Yuru weight metadata, a unified
  budgeted Japanese candidate bundle, parser-edge trimming, and numeric query
  readings before ordinary romaji expansion.
- Document the licensed optional-provider gate for Kanji dictionary readings
  instead of embedding an unlicensed or incomplete dictionary.
- Split the public examples into Korean and Japanese finder tasks with exact
  output-match-to-source-range projection.
- Gate source releases on full installed-package verification across the
  supported platform matrix.

[Unreleased]: https://github.com/Ameyanagi/yomi/compare/v0.1.1...HEAD
[0.1.1]: https://github.com/Ameyanagi/yomi/compare/v0.1.0...v0.1.1
[0.1.0]: https://github.com/Ameyanagi/yomi/releases/tag/v0.1.0
