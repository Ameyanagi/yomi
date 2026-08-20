# Changelog

This project follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/)
and uses semantic versioning after the first public release.

## [Unreleased]

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
- Add allocation-free Hiragana, Katakana, Kana, base-block Kanji, and modern
  precomposed Hangul routing predicates.
- Gate source releases on full installed-package verification across the
  supported platform matrix.
