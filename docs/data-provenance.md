# Data provenance

Yomi commits generated lookup data only when the installed Mojo package can
consume it directly, without Python or another generator runtime.

The kana romanization fixture in `tests/kana_fixture_data.mojo` is a manually
maintained normative table rather than generated lookup data. It enumerates
both scripts, every standard precomposed and base-plus-combining voiced form,
and every supported yoon and extended digraph. The scheme and the same complete
tables are reviewable in `docs/romanization.md`; tests lock its 399 fixed-output
rows and 52 explicit composition-equivalence rows.

Kana scalar identities and standard dakuten/handakuten composition pairs were
reviewed against **The Unicode Standard, Version 17.0.0**, Hiragana and
Katakana block charts (retrieved 2026-08-20):

- <https://www.unicode.org/charts/PDF/U3040.pdf>;
- <https://www.unicode.org/charts/PDF/U30A0.pdf>.

No external romanization database is embedded. Romanization outputs are Yomi's
documented wapuro-flavored modified Hepburn convention, and the tests walk the
checked-in rows directly.

Japanese search compatibility uses reviewed scalar ranges and literals only:
full-width ASCII U+FF01..U+FF5E, half-width katakana U+FF61..U+FF9F,
ideographic space U+3000, the documented dash set, the existing kana voicing
table, and algorithmic integer readings from 1 through 9999. No normalization,
IME, numeric, or Kanji dictionary data file is embedded. The exact built-in
coverage and optional-provider requirements are documented in
[`japanese-search.md`](japanese-search.md).

The Hangul choseong and decomposition implementations are reviewed against
**The Unicode Standard, Version 17.0.0**, Section 3.12.5, “Sample Code for
Hangul Algorithms”:

- source: <https://www.unicode.org/versions/Unicode17.0.0/core-spec/chapter-3/>;
- retrieved: 2026-08-20;
- algorithm constants used: `SBase = U+AC00`, `LBase = U+1100`,
  `VBase = U+1161`, `TBase = U+11A7`, `LCount = 19`, `VCount = 21`,
  `TCount = 28`, `NCount = 588`, and `SCount = 11,172`;
- implemented range: `U+AC00..U+D7A3`;
- leading index formula: `(code_point - SBase) div NCount`.

For `SIndex = code_point - SBase`, `decompose_hangul` emits:

```text
L = LBase + SIndex div NCount
V = VBase + (SIndex mod NCount) div TCount
T = TBase + SIndex mod TCount  (only when T != TBase)
```

The exhaustive test covers every scalar in U+AC00..U+D7A3 with a separate
mixed-radix odometer oracle. The oracle advances trailing, vowel, and leading
Jamo counters by explicit carries instead of repeating the implementation's
division and remainder formula. It asserts the exact expected scalars, their
legal modern-Jamo ranges, the 399 LV and 10,773 LVT cases, and every emitted
Jamo's mapping to the exact three-byte source syllable.

A generated normalization corpus is unnecessary for this algorithmic slice:
the pinned Unicode constants plus legal digit ranges define a unique canonical
mixed-radix decomposition, and the counter oracle enumerates every input and
expected output without sharing production helpers. Future table-driven
language data remains subject to the generated-artifact policy below.

Canonical decomposed modern Hangul reads its first leading Jamo from the
contiguous `LBase..LBase + LCount - 1` range (`U+1100..U+1112`) and uses the same
compatibility sequence. No normalization table is embedded.

The 19 results are the reviewed Hangul Compatibility Jamo sequence U+3131,
U+3132, U+3134, U+3137, U+3138, U+3139, U+3141, U+3142, U+3143, U+3145,
U+3146, U+3147, U+3148, U+3149, U+314A, U+314B, U+314C, U+314D, and U+314E.
The authoritative block chart is
<https://www.unicode.org/charts/PDF/U3130.pdf> (retrieved 2026-08-20).

The deterministic Korean romanization and Dubeolsik tables are documented in
[`korean-search.md`](korean-search.md). The romanization is a finder-oriented,
syllable-local convention aligned with Yuru v1; it is not a claim of full
phonological Revised Romanization. The keyboard table follows the standard
Korean 2-set QWERTY positions and emits lowercased ASCII so shifted tense keys
remain compatible with case-insensitive fuzzy matching. Reference-component
tests exercise all 19 initial, 21 vowel, and 28 final entries, and an exhaustive
walk validates source mappings for all 11,172 modern syllables.

These reviewed constants and scalar literals implement an algorithm; no
external lookup database is embedded for Hangul. Unicode material is used under
the Unicode Terms of Use:
<https://www.unicode.org/license.txt>.

## Chinese pinyin data

`src/yomi/chinese/_pinyin_data.mojo` is generated from mozillazg's
`pinyin-data` **0.13.0** `pinyin.txt`:

- canonical source:
  <https://github.com/mozillazg/pinyin-data/blob/v0.13.0/pinyin.txt>;
- raw source used by the generator:
  <https://raw.githubusercontent.com/mozillazg/pinyin-data/v0.13.0/pinyin.txt>;
- retrieved: 2026-08-22;
- upstream Unihan data version: **Unicode 14.0.0**, dated 2021-08-06 in that
  release's README;
- upstream license: MIT, copyright © 2016 mozillazg; the canonical license is
  <https://github.com/mozillazg/pinyin-data/blob/v0.13.0/LICENSE>, and its text
  is retained in `LICENSES/pinyin-data-MIT.txt`;
- source byte length: 920,298;
- source SHA-256:
  `b240322a1dbe7bb4abffb1889cdbbb3f124bc3242d27ea40a10f51596c41db50`;
- generated artifact SHA-256:
  `0920da508dfd92f381ab9940b5719d715bb317930b191f2b54a2ec98e798c0a0`.

The generated table covers U+3007 IDEOGRAPHIC NUMBER ZERO and all 20,901
assigned source rows in the ordinary BMP CJK Unified Ideographs range
U+4E00..U+9FFF. It stores the source's deterministic first reading plus at most
two distinct alternates, after applying the same tone-removal rules as the
`pinyin` Rust crate used by Yuru. This intentionally targets normal searchable
text; rare Extension A and supplementary-plane ideographs remain outside the
current compact table.

Generation is deterministic, sorted by scalar value, fixed-width, and uses only
the Python standard library. Given a downloaded source file, regenerate and
verify the checked-in artifact with:

```sh
pixi run python3 scripts/generate_pinyin_data.py /tmp/pinyin.txt
pixi run python3 scripts/generate_pinyin_data.py /tmp/pinyin.txt --check
```

The generator rejects any source whose SHA-256 differs, rejects duplicate
scalars or oversized fields, and `--check` performs a byte-for-byte comparison.
Review a version update for primary-reading order, new romanization symbols,
Unicode coverage, and license changes before updating the pinned metadata.

Every future generated artifact must record:

- upstream project and canonical URL;
- upstream version and retrieval date;
- exact file checksums and licenses;
- generator source and command;
- deterministic output checks;
- review notes for semantic or licensing changes.

Generation tools are development dependencies. Consumers install the generated
Mojo data and do not require Python, Rust, C, or another runtime.


## Optional IPADIC dictionary

The optional external Japanese reading provider uses every reading-bearing row
of IPADIC 2.7.0-20070801 at exact MeCab commit
`61b90ba6e669dc2d7d533d4a80d206f3b31d52b1`. The complete per-source checksums and
generated artifact hash are in `data/ipadic/sources.json`. NAIST/ICOT notices
remain byte-for-byte in `LICENSES/ipadic-COPYING` and accompany every optional
installation. The dictionary is not part of Yomi's default package or a
generated Mojo source module. See [IPADIC provenance and semantics](ipadic-provider.md)
for exact counts, limits, opt-in installation, and licensed fixture provenance.
