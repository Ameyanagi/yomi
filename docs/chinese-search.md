# Chinese search keys

Yomi exposes three explicit primary-reading transformations:

- `pinyin_full(source)` emits space-separated syllables;
- `pinyin_joined(source)` concatenates the same syllables;
- `pinyin_initials(source)` emits the first scalar of each syllable.

For example, `北京大学` becomes `bei jing da xue`, `beijingdaxue`, and `bjdx`.
Every syllable or initial maps to the exact UTF-8 byte range of its source Han
scalar. Spaces in the full representation are explicit unmapped output spans;
`source_ranges_for_output()` therefore ignores a separator-only match instead
of broadening a highlight to a neighboring character.

The transformations extract recognized Han scalars and ignore other source
text, matching Yuru's candidate-key behavior. Source gaps remain exact: in
`A北🙂京.txt`, the two output mappings point to `北` and `京` independently.
Empty or unsupported input produces an empty transformed value while retaining
the owned source text.

## Common polyphones

`pinyin_representations(source, max_count=8)` returns a capped flat list of
search representations. It first emits primary full, joined, and initials
forms. In `ChinesePolyphoneMode.COMMON`, it then substitutes one character at a
time, ordered by alternate-reading index and source position, and emits that
sequence's full, joined, and initials forms. Duplicate text is removed and no
combinations of multiple substitutions are generated.

This is the same bounded mechanism as Yuru: `还没` begins with `hai mei`,
`haimei`, and `hm`, then adds common forms including `huan mei`, `huanmei`,
`hai mo`, and `haimo`. With the default cap, the eighth key is `fu mei`.
`ChinesePolyphoneMode.NONE` returns only the three primary forms. A cap of zero
returns no values; a negative cap is invalid.

The common city name `重庆` has the same small phrase exception as Yuru and uses
`chong qing`, `chongqing`, and `cq` instead of the isolated primary reading of
`重`.

## Table and performance

The generated table covers U+3007 and assigned U+4E00..U+9FFF entries from
`pinyin-data` 0.13.0. Each row stores the deterministic primary plus at most two
distinct common readings. Lookup is a zero-allocation binary search over a
fixed-width static string table; allocations begin only when the selected
syllables and owned output representations are constructed.

Table lookup and variable-length UTF-8 emission are short, branch-heavy scalar
operations. SIMD is intentionally not used: it would add setup and lane-control
overhead without a fixed-width batch kernel to amortize it. The explicit cap
prevents polyphone output growth, while each attempted substitution remains
linear in the number of recognized source scalars.

See [`data-provenance.md`](data-provenance.md) for the exact upstream version,
Unicode version, license, checksums, coverage decision, and generator/check
commands.
