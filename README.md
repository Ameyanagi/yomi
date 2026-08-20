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

## Japanese public slices

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

Every mapping is an ordered pair of half-open UTF-8 byte ranges. Output ranges
refer to the transformed text; source ranges refer to the original input. The
representation owns copies of both texts and validates mapping bounds and UTF-8
boundaries against them at construction. Accessors trust the validated value
and are non-raising except where an operation validates new input, such as a
mapping index or output match range. Mojo 1.0 does not enforce field privacy,
so direct mutation of underscore-prefixed storage is out of contract;
`validate()` provides an explicit checkpoint for unusual low-level work.
`mapping_snapshot()` returns a detached list for efficient enumeration.
`source_ranges_for_output()` projects a match to ordered exact source ranges,
merging only overlapping or touching ranges and never bridging a source gap.
The API is experimental and may change before v0.1.

## Repository map

- `src/yomi/`: library or application source
- `tests/`: TestSuite unit, reference-value, and invariant tests
- `examples/`: small compilable usage programs
- `benchmarks/`: reproducible methodology and later benchmark programs
- `docs/`: architecture, design, compatibility, roadmap, and release policy
- `conda.recipe/`: local Rattler build recipe

See [the architecture](docs/architecture.md), [design principles](docs/design.md),
[roadmap](docs/roadmap.md), and
[executable implementation plan](docs/implementation-plan.md) before proposing
a new dependency or feature.

## License

Licensed under either Apache-2.0 or MIT, at your option.
