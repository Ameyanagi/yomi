# Yomi

> **Experimental — API not yet released.**

CJK phonetic representations and readings for Mojo.

## Scope

Yomi produces CJK phonetic representations while preserving exact mappings to original source ranges.

The first implementation milestone is intentionally narrow: implement Hangul
decomposition, choseong search, keyboard forms, kana romanization, and the
licensed pinyin/initials data required by Yuragi's `bjdx` v0.1 proof, all with
exact source byte ranges.
Mandarin v0.1 uses Unicode `kMandarin` customary readings with explicit
Hans/Hant regional selection; it does not claim exhaustive lexical polyphony.
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
    var first = mappings[0].copy()
    print(first.output_start(), first.output_end())
    print(first.source_start(), first.source_end())

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

Every mapping is an ordered pair of half-open UTF-8 byte ranges. Output ranges
refer to the transformed text; source ranges refer to the original input. The
representation owns copies of both texts and validates mapping bounds and UTF-8
boundaries against them. Accessors are fallible because Mojo 1.0 does not
enforce field privacy; every public read rejects invalid reachable mutation.
`mapping_snapshot()` validates once for efficient enumeration.
`source_ranges_for_output()` projects a match to ordered exact source ranges,
merging only overlapping or touching ranges and never bridging a source gap.
The current Yomi-local `SourceMapping`, `SourceRange`, and generic projection
implementation are temporary compatibility APIs. Before v0.1 release,
`PhoneticRepresentation` will compose tagged packaged Moji mapping values, and
the temporary mapping exports will leave the Yomi root. No sibling source path
is permitted. The API is experimental and may change before v0.1.

## Repository map

- `src/yomi/`: library or application source
- `tests/`: TestSuite unit, reference-value, and invariant tests
- `examples/`: small compilable usage programs
- `benchmarks/`: reproducible methodology and later benchmark programs
- `docs/`: architecture, design, compatibility, roadmap, and release policy
- `conda.recipe/`: local Rattler build recipe

See [the architecture](docs/architecture.md),
[reference architecture](docs/reference-architecture.md),
[design principles](docs/design.md), [roadmap](docs/roadmap.md), and
[executable implementation plan](docs/implementation-plan.md) before proposing
a new dependency or feature.

## License

Licensed under either Apache-2.0 or MIT, at your option.
