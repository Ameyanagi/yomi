# Yomi

> **Experimental — API not yet released.**

CJK phonetic representations and readings for Mojo.

## Scope

Yomi produces CJK phonetic representations while preserving exact mappings to original source ranges.

The first implementation milestone is intentionally narrow: implement Hangul
decomposition, choseong search, keyboard forms, kana romanization, and the
licensed pinyin/initials data required by Yuragi's `bjdx` v0.1 proof, all with
exact source byte ranges.
The project is independently installable and does not require any application
from the wider ecosystem.

## Development

Install [Pixi](https://pixi.sh/), then run:

```sh
pixi install --locked
pixi run check
pixi run example
```

The exact stable Mojo compiler and all development dependencies are captured in
`pixi.lock`. Runtime and library code is Mojo-first and pure Mojo wherever
practical. Build-time data generation may use another language when justified,
but generated outputs must be deterministic, checksum-pinned, licensed, and
documented.

## Package

The Mojo import is `yomi`. The eventual Conda distribution is
`mojo-yomi`. Source lives under `src/yomi/`, whose
`__init__.mojo` defines the package boundary.

## Korean public slices

Use `korean_candidate_keys` when a finder wants the normal Korean indexing
bundle. It returns at most four typed keys in stable order: original text,
joined romanization, choseong initials, and Dubeolsik keyboard input. Generated
keys share one byte budget; the original key does not consume that budget:

```mojo
from yomi import korean_candidate_keys


def main() raises:
    var keys = korean_candidate_keys("서울")
    for index in range(keys.count()):
        print(keys.key(index).text())  # 서울, seoul, ㅅㅇ, tjdnf
```

The four individual transformations remain available when a caller needs one
specific representation, with no mode object or boolean combinations:

```mojo
from yomi import (
    hangul_choseong,
    hangul_keyboard,
    romanize_hangul,
    romanize_hangul_spaced,
)


def main() raises:
    print(romanize_hangul("한글").text())  # hangeul
    print(romanize_hangul_spaced("한글").text())  # han geul
    print(hangul_choseong("한글").text())  # ㅎㄱ
    print(hangul_keyboard("한글").text())  # gksrmf
```

Romanization is a deterministic Revised-Romanization-style spelling for
finder recall; it does not apply pronunciation-dependent assimilation.
`hangul_keyboard` emits the lowercased QWERTY sequence for the Korean
Dubeolsik (2-set) layout. NFC and canonical NFD inputs produce identical key
text. Other grapheme clusters pass through unchanged, including mixed path and
label text. See [the Korean search-key convention](docs/korean-search.md).

`hangul_choseong` gives NFC and canonically decomposed modern Hangul compatible
choseong views and passes other grapheme clusters through unchanged:

```mojo
from yomi import hangul_choseong


def main() raises:
    var representation = hangul_choseong("한국 notes")
    print(representation.text())  # ㅎㄱ notes

    var mappings = representation.mapping_snapshot()
    print(mappings[0].output_start(), mappings[0].output_end())
    print(mappings[0].source_start(), mappings[0].source_end())

    var source_ranges = representation.source_ranges_for_output(0, 6)
    print(source_ranges[0].start(), source_ranges[0].end())
```

`decompose_hangul` expands every modern precomposed Hangul syllable into its
canonical leading, vowel, and optional trailing Jamo. Each emitted Jamo maps
back to the exact source syllable bytes:

```mojo
from yomi import decompose_hangul


def main() raises:
    var representation = decompose_hangul("각")
    print(representation.text())  # 각

    var mappings = representation.mapping_snapshot()
    for index in range(len(mappings)):
        print(mappings[index].source_start(), mappings[index].source_end())
        # Each Jamo maps to source bytes [0, 3).
```

Canonically decomposed input passes through unchanged with one mapping per
scalar, so NFC and NFD inputs produce identical transformed text. Combining or
extender code points after a precomposed syllable retain their own exact source
ranges.

`compose_hangul` contracts modern conjoining Jamo, or a precomposed LV syllable
plus a trailing Jamo, to one modern Hangul syllable. The single mapping spans
all source scalars consumed by the contraction:

```mojo
from yomi import compose_hangul


def main() raises:
    var representation = compose_hangul("각")
    print(representation.text())  # 각

    var mapping = representation.mapping(0)
    print(mapping.output_start(), mapping.output_end())  # 0 3
    print(mapping.source_start(), mapping.source_end())  # 0 9
```

## Chinese public slices

The primary-reading front door is three explicit source-preserving functions:

```mojo
from yomi import pinyin_full, pinyin_initials, pinyin_joined


def main() raises:
    print(pinyin_full("北京大学").text())  # bei jing da xue
    print(pinyin_joined("北京大学").text())  # beijingdaxue
    print(pinyin_initials("北京大学").text())  # bjdx
```

`pinyin_representations` adds a small capped set of common single-character
alternates in deterministic Yuru-compatible order. It defaults to eight keys;
`ChinesePolyphoneMode.NONE` requests only the primary full, joined, and initials
forms. Generated spaces have explicit unmapped output spans, so highlighting a
syllable still projects to its exact original Han scalar. See
[the Chinese search-key contract](docs/chinese-search.md) and
[data provenance](docs/data-provenance.md).

## Japanese public slices

Finder-oriented Japanese indexing uses explicit kana, romaji, and query
transformations. Typed bundles let a fuzzy finder apply Yuru-compatible
query/candidate gates without inspecting text or list positions. The candidate
bundle adds algorithmic Arabic-numeral year/month readings without a dictionary
dependency:

```mojo
from yomi import japanese_candidate_keys, japanese_query_keys


def main() raises:
    var queries = japanese_query_keys("kanya")
    for index in range(queries.count()):
        print(queries.key(index).text())  # kanya, かにゃ, かんや

    var keys = japanese_candidate_keys("2025年8月")
    for index in range(keys.count()):
        print(keys.key(index).text())
```

Full-width ASCII and spaces, half-width katakana, dash variants, and prolonged
marks share Yuru-compatible finder forms with exact source-byte mappings.
The unified candidate bundle starts with literal and normalized base keys, then
adds generated Japanese keys under an eight-key/1,024-byte default budget.
Romaji-query expansion is deduplicated, hard-capped at eight variants, trims
ASCII whitespace at the parser boundary, handles
ambiguous `n` before `y`, and adds the reviewed Yuru long-vowel guesses for
Tokyo, Kyoto, Osaka, Kobe, repeated `o`, and numeric-romaji input such as
`8gatsu -> はちがつ`. The older explicit
`japanese_query_kana` and `japanese_search_representations` transformations
remain available when callers do not need typed fanout.
Kanji dictionary readings remain behind a documented optional-provider seam;
Yomi does not embed an unlicensed or misleading partial dictionary. See
[the Japanese search-key contract](docs/japanese-search.md).

`romanize_kana` supports source-preserving finder keys. A match for `raamen`
in output bytes `[0, 6)` projects back to the exact katakana source range
`[0, 12)` a fuzzy finder should highlight:

```mojo
from yomi import romanize_kana


def main() raises:
    var representation = romanize_kana("ラーメン屋")
    print(representation.text())  # raamen屋

    var source_ranges = representation.source_ranges_for_output(0, 6)
    print(source_ranges[0].start(), source_ranges[0].end())  # 0 12
```

`to_hiragana` and `to_katakana` convert full-width kana scripts while
preserving exact source ranges. Composable base-plus-voicing forms are
canonicalized to precomposed NFC kana in the target script:

```mojo
from yomi import to_hiragana, to_katakana


def main() raises:
    print(to_hiragana("ラーメン").text())  # らーめん
    print(to_katakana("らーめん").text())  # ラーメン
```

See [the full kana convention](docs/romanization.md) for romanization, script
conversion, voicing, prolonged-mark, and pass-through behavior.

The non-raising `is_hiragana`, `is_katakana`, `is_kana`, `is_kanji`, and
`is_hangul_syllable` functions are allocation-free, per-scalar routing
predicates for deciding whether to attempt a phonetic representation. They
require every scalar to belong to the documented script set and return `False`
for empty input.

Every mapping has a half-open UTF-8 output range and either a half-open source
range or an explicit unmapped state for generated separators. The
representation owns copies of both texts and validates mapping bounds and
UTF-8 boundaries at construction. Call `has_source()` before reading a
mapping's source offsets. Accessors trust the validated value and are
non-raising except where an operation validates new input, such as a mapping
index or output match range. Mojo 1.0 does not enforce field privacy, so direct
mutation of underscore-prefixed storage is out of contract; `validate()`
provides an explicit checkpoint for unusual low-level work.
`mapping_snapshot()` returns a detached list for efficient enumeration.
`source_ranges_for_output()` projects a match to ordered exact source ranges,
ignoring unmapped separators, merging only overlapping or touching ranges, and
never bridging a source gap.
The API is experimental and may change before v0.1.

## Repository map

- `src/yomi/`: library or application source
- `tests/`: TestSuite unit, reference-value, and invariant tests
- `examples/`: small compilable usage programs
- `benchmarks/`: reproducible profiler-oriented benchmark programs
- `docs/`: architecture, design, compatibility, roadmap, and release policy
- `conda.recipe/`: local Rattler build recipe

See [the architecture](docs/architecture.md), [design principles](docs/design.md),
[roadmap](docs/roadmap.md), and
[executable implementation plan](docs/implementation-plan.md) before proposing
a new dependency or feature.

## License

Licensed under either Apache-2.0 or MIT, at your option.
