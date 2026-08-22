# Japanese search keys

Yomi exposes explicit source-preserving operations:

| Function | Purpose |
| --- | --- |
| `japanese_kana_key(source)` | normalized hiragana candidate key |
| `japanese_romaji_key(source)` | normalized romaji candidate key |
| `japanese_query_kana(query)` | deterministic IME-style query key |
| `japanese_search_representations(source)` | unique candidate bundle, capped at six keys |
| `japanese_search_keys(source, max_count=6)` | typed candidate bundle, hard-capped at six |
| `japanese_candidate_keys(source, max_count=8, max_total_key_bytes=1024)` | unified original/normalized/Japanese bundle |
| `japanese_query_keys(query, max_count=8)` | typed query fanout, hard-capped at eight |

For example, `ｶﾒﾗ　ＡＢＣ` becomes `かめら abc` and `kamera abc`.
The candidate bundle performs the compatibility scan once and returns owned
`PhoneticRepresentation` values ready for indexing.

## Compatibility normalization

The finder-key path lowercases ASCII and folds full-width ASCII U+FF01..U+FF5E,
ideographic space U+3000, half-width katakana U+FF61..U+FF9F, and common dash
forms. Dash folding covers ASCII hyphen, U+2010..U+2015, U+2212, U+30A0,
U+30FC, U+FE58, U+FE63, U+FF0D, and U+FF70. Katakana is then folded to
hiragana. Thus the prolonged mark in `ハッピー` is a finder hyphen and the
romaji key is `happi-`, matching Yuru's candidate-key convention rather than
the display-oriented `romanize_kana` result `happii`.

Half-width base-plus-voicing pairs contract to one output mapping over both
source scalars. All other pass-through text keeps its source grapheme mapping.
The functions intentionally implement this search compatibility set rather
than claiming general-purpose NFKC normalization.

## IME query forms

`japanese_query_kana` uses longest-token matching over the common wapuro and
IME spellings. It accepts canonical spellings plus aliases including:

- `zyu`/`jyu`/`ju` for `じゅ`;
- `nn`, `xn`, and `n'` for `ん`;
- `ltsu`/`xtsu`/`ltu`/`xtu` for `っ`;
- `l`/`x` small-vowel, small-y, small-wa, small-ka, and small-ke forms;
- doubled consonants such as `gakkou` for `がっこう`.

The API returns one deterministic key, keeps unsupported ASCII unchanged, and
does not expose parser modes. Native kana queries take the same compatibility
path as candidate kana keys.

`japanese_query_keys` is the bounded search-oriented companion. It retains the
literal query, emits compatibility-normalized and native-kana coverage where
applicable, trims surrounding ASCII whitespace before romaji parsing, and
breadth-first expands IME romaji. `n` before `y` deliberately
fans out: `kanya` produces both `かにゃ` and `かんや`. The bundle also carries
Yuru's reviewed long-vowel guesses: `tokyo -> とうきょう`,
`kyoto -> きょうと`, `osaka -> おおさか`, `kobe -> こうべ`, plus the bounded
repeated-`o` forms. Kind/text pairs are deduplicated and `max_count` must be in
`[0, 8]`; larger values are rejected rather than quietly widening work.

Numeric-romaji expansion runs before the ordinary romaji parse, matching
Yuru's query ordering. Convertible digit runs are positive integers through
9999 without a leading zero; comma and underscore separators are accepted.
Thus `8gatsu` adds `はちがつ` before `8がつ`, while `08gatsu` remains literal.

Every generated span maps to the exact query bytes that produced it. Inserted
long-vowel kana map to the triggering romaji syllable, so full-width input such
as `ＴＯＫＹＯ` still projects through normalization to the original UTF-8 byte
ranges.

## Typed compatibility gates

`SearchKeyKind`, `SearchKey`, and `SearchKeyBundle` carry semantics explicitly.
`search_key_kinds_compatible(query_kind, candidate_kind)` mirrors Yuru's gate:
romaji-to-kana variants score Japanese kana keys, pinyin variants score full or
joined pinyin, and initials score Chinese or Korean initials. Original queries
can score original/normalized and romanized candidate forms. This prevents an
unrelated language representation from winning by accidental textual overlap.
`SearchKey.weight()` and `SearchKeyKind.default_weight()` expose the current
checked-in Yuru scoring defaults without adding constructor parameters.
`LEARNED_ALIAS` is a candidate kind accepted by original and initials query
coverage, as in Yuru.

The current Yuru defaults are:

| Candidate kind | Weight |
| --- | ---: |
| original / normalized | 3000 / 2800 |
| Japanese kana / romaji | 1700 / 1800 |
| pinyin full / joined / initials | 1750 / 1800 / 1850 |
| Korean romanized / initials / keyboard | 1800 / 1850 / 1750 |
| learned alias | 2500 |

| Query kind | Weight |
| --- | ---: |
| original / normalized | 500 / 450 |
| Japanese kana / romaji-to-kana | 350 / 200 |
| pinyin / initials | 250 / 250 |

These values intentionally follow `yuru-core` rather than an older audit
table that listed learned aliases as 1000 and initials as 1300/350; those
values do not occur in the checked-in Yuru implementation.

## Unified candidate budget

`japanese_candidate_keys` supplies the indexing front door Yuragi needs. It
always emits literal and normalized base kinds for a nonempty-cap request, then
adds the dependency-free Japanese keys in their existing order. The default
count cap is eight and the generated-key byte budget is 1,024. Like Yuru,
required base keys remain present even when their own bytes exceed that budget;
the budget gates generated growth. A base-only count cap or zero generated-byte
budget returns before phonetic generation. Yomi's normalized base is the documented
case/width/space/dash/half-width-kana subset and does not claim general NFKC.

## Arabic numerals in years and months

The candidate bundle recognizes a positive Arabic integer from 1 through 9999
immediately before `年` or `月`. It adds full-reading and compact-mixed kana and
romaji keys. `2025年8月` therefore includes:

```text
にせんにじゅうごねんはちがつ
nisennijuugonenhachigatsu
2025ねん8がつ
2025nen8gatsu
```

Irregular hundreds and thousands such as `300 -> さんびゃく`,
`600 -> ろっぴゃく`, and `8000 -> はっせん` are explicit. Leading-zero
runs, zero, and values above 9999 remain literal. Standalone `月` remains `月`;
Yomi does not silently choose `つき` or `がつ` without numeric context.

## Optional Kanji-reading provider seam

Kanji dictionary readings are deliberately not embedded. Yuru obtains them
from Lindera with IPADIC, but Yomi currently has no reviewed Mojo-native
tokenizer/dictionary dependency or accepted generated artifact with pinned
license, version, checksums, token boundaries, unknown-word behavior, and
alternate-reading policy. A hand-written partial dictionary would create
silent, data-dependent search gaps and is not an acceptable substitute.

The provider seam is the owned list returned by
`japanese_search_representations`, or the detached snapshot from
`japanese_search_keys`: an application may append capped provider-produced
values after the built-in keys. Typed values use `JAPANESE_KANA` or
`JAPANESE_ROMAJI` as appropriate.
Every provider value must own the identical source text, map every emitted
reading span to exact UTF-8 source bytes, expose alternatives rather than
silently choosing one, and document its cap and unknown-word policy. Once one
licensed provider meets those requirements, Yomi can standardize a typed
provider adapter without changing the built-in key functions.

## Performance boundary

The candidate bundle performs one compatibility-normalization scan, then
linear mapped transformations over the small fixed output set. It emits at
most six unique keys. Query fanout performs at most `16 * max_count` parser
state expansions and emits at most eight keys. Adjacent romanized spans with the same source range are
coalesced, reducing mapping count for numeric readings.

UTF-8 decoding, compatibility dispatch, IME token selection, and
variable-length emission are branch-heavy scalar work. Forced SIMD would add
lane control and packing overhead without a measured fixed-width batch kernel.
Future SIMD work requires a benchmarked batch API and retains the same mapping
contract.
