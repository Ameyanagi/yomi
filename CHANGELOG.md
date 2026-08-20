# Changelog

This project follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/)
and uses semantic versioning after the first public release.

## [Unreleased]

### Added

- Initial experimental repository scaffold.
- Add source-preserving phonetic representation values.
- Add precomposed Hangul choseong conversion with exact UTF-8 byte mappings.
- Reject invalid mapping spans and incomplete transformed-output coverage.
- Own source text, validate both sides of every mapping, and revalidate public
  reads against externally reachable storage mutation.
- Define precomposed Hangul plus combining-extender choseong behavior.
- Add canonical decomposed leading-Jamo choseong equivalence.
- Add validate-once mapping snapshots and exact output-to-source range
  projection without bridging discontiguous highlights.
- Gate source releases on full installed-package verification across the
  supported platform matrix.
