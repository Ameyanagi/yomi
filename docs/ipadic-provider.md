# Optional IPADIC reading provider

`yomi.japanese.ipadic.IpadicReadingProvider` loads a full external IPADIC-derived
reading dictionary. It requires **Yomi 0.1.2 or the current source checkout**;
Yomi 0.1.1 does not include it. Until 0.1.2 packages are available, use the source
checkout commands below. The normal Yomi installation and built-in Japanese key
functions remain dictionary-free. This module uses pure Mojo at runtime;
Python's standard library is needed only for explicit dictionary preparation.

## Install explicitly

From the source checkout, select an output directory yourself:

```sh
python3 scripts/install_ipadic.py --output .pixi/ipadic
pixi run --locked mojo run -I src examples/ipadic.mojo .pixi/ipadic/readings.tsv
```

The installer downloads all 26 CSV files and `COPYING` from the pinned official
MeCab repository, verifies their exact sizes and SHA-256 hashes, decodes EUC-JP,
collects every distinct reading for every surface, and verifies the generated
UTF-8 artifact's pinned SHA-256. It writes `readings.tsv`, `COPYING`, and a
provenance `manifest.json` to the requested directory. No install hook, runtime
network access, global search path, or generated Mojo data module is involved.

For an offline installation, provide a directory containing the exact source
files with `--source-dir /path/to/sources`. Add `--check` to verify an existing
installation without writing. Source changes, missing files, altered bytes,
and a changed generated artifact fail verification; updating the data requires
an explicit reviewed manifest update. Keep the installed directory trusted:
the Mojo loader checks format and bounds, and the installer performs checksum
verification. The loader is not an authenticator for subsequently modified files.

## Key contract and example

```mojo
from yomi.japanese.ipadic import IpadicReadingProvider


def main() raises:
    var provider = IpadicReadingProvider(".pixi/ipadic/readings.tsv")
    var keys = provider.candidate_keys("日本", max_count=8, max_total_key_bytes=1024)
    for index in range(keys.count()):
        print(keys.key(index).text())
```

Load the provider once and reuse it across candidates. For `日本`, generated
alternatives include `にっぽん`/`nippon` and `にほん`/`nihon`. `生田` retains
`いくた`, `いけだ`, and `おいだ` under the default count cap. These are dictionary
alternatives, not a claim that one is the correct reading of a particular name.

The adapter returns the same `SearchKeyBundle` used by
`japanese_candidate_keys`. Existing original, normalized, and built-in Japanese
keys keep priority. Additional provider keys use `JAPANESE_KANA` and
`JAPANESE_ROMAJI`, and duplicates are removed by kind and text. Count limits are
zero or 2–8. All generated keys share the byte budget; required original and
normalized base keys remain exempt. Kana and romaji are checked independently,
so a shorter romaji form can fit when its kana companion does not.

## Segmentation, ambiguity, and unknown input

This is a deterministic reading lookup, **not a contextual MeCab tokenizer**.
At each original grapheme boundary it chooses the longest matching dictionary
surface. It does not use IPADIC's part-of-speech/context IDs or connection costs,
choose readings based on sentence context, or enumerate alternate segmentations.
All distinct readings of the selected surface are retained in lexical order.
Source rows whose reading is `*` contribute no invented pronunciation.

Multiple-token alternatives are visited in lexical mixed-radix order, with the
last token varying fastest. At most `max_count` combinations are visited, even
if the full Cartesian product would be much larger. Each visited combination
emits kana then romaji if its individual count/byte budget permits. Therefore
capped bundles intentionally omit later alternatives; increasing a byte budget
cannot override the hard eight-key/count-work cap. No ranking or fuzzy scoring
occurs in Yomi.

Unknown graphemes pass through the normal Japanese compatibility folds. A rare
unlisted `𠮷` stays literal instead of receiving a guessed reading. A neighboring
known token can still receive its dictionary readings. Kana/ASCII width and
case folds follow the existing search-key contract.

Every generated reading span maps to the **entire exact UTF-8 source token**.
A phonetic syllable cannot be reliably aligned to an individual Kanji, so
matching `sa` in `satou` highlights both characters of `佐藤`. Unknown graphemes
keep their own exact byte range. Original text is owned unchanged, including
emoji, combining sequences, and mixed-width text. Kana-to-romaji conversion
composes those mappings rather than returning offsets into dictionary strings.

## Source and reproducibility

- Upstream: `taku910/mecab`, `mecab-ipadic`, version **2.7.0-20070801**.
- Exact commit: `61b90ba6e669dc2d7d533d4a80d206f3b31d52b1`.
- Version evidence: [pinned configure.in](https://github.com/taku910/mecab/blob/61b90ba6e669dc2d7d533d4a80d206f3b31d52b1/mecab-ipadic/configure.in),
  SHA-256 `39060fba4b6913948623cd695175e9eadb7111a27d43d861a472c5c31f58c37e`.
- Every source URL, byte length, and SHA-256: [sources.json](../data/ipadic/sources.json).
- Input: **392,126 records** across all 26 CSVs.
- Output: **325,871 surfaces**, **341,842 distinct surface/readings**, 9,367,792 bytes.
- Artifact SHA-256: `66e899d9e3176e267b4e4f7e5edfb63fb45f19f1f8af3f02a1adcbb253491d47`.
- License: NAIST/ICOT notices preserved verbatim in
  [LICENSES/ipadic-COPYING](../LICENSES/ipadic-COPYING) and every installation.
  The optional dictionary data is not relicensed under Yomi's code license.
- Retrieved and verified: 2026-09-05.

Generation sorts Unicode surfaces and distinct readings deterministically; it
does not truncate readings in the installed data. The largest source reading
set contains 12 alternatives. The runtime loader enforces a 32 MiB file limit,
350,000 surfaces, 78-byte surfaces, and at most 12 readings of at most 256 bytes.
Splitting itself is capped before allocating line/field descriptors. The loader
also rejects ASCII control characters and noncanonical reading order, matching
the installer's field and lexical-order contract. These explicit limits cover
the pinned artifact and require review on updates.

The checked-in ten-surface fixture contains complete reading sets extracted
from this exact source and retains the same format and license provenance. It
is a test fixture, not a partial dictionary offered to users. Unit tests run
offline against it. Full-dictionary verification uses the explicit installer
and example command above; it is not hidden in normal dependency installation.

## Yuragi integration

[`integrations/yuragi/ipadic.mojo`](../integrations/yuragi/ipadic.mojo) appends
provider keys to Yuragi's `IndexedPhoneticKey` metadata and Hibana's
`PreparedCorpus`, then uses Yuragi's `project_key_positions` for exact source
highlighting. With source checkouts side by side, run from Yomi:

```sh
pixi run --locked mojo run -I src -I ../yuragi/src -I ../hibana/src -I ../moji/src \
  integrations/yuragi/ipadic.mojo .pixi/ipadic/readings.tsv
```

Keep the provider-produced representations alongside the corpus. A consumer
must project matches through those representations rather than reconstructing
the dictionary-free bundle from an ordinal. The example demonstrates the
existing application seams without changing Yuragi's default language mode or
adding a dictionary dependency to it.
