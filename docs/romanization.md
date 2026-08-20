# Kana romanization convention

Yomi implements one scheme: **ASCII wapuro-flavored modified Hepburn**. It is
deterministic and intended for source-preserving fuzzy matching, not for
linguistic analysis or reversible transliteration. There are no options.

The scheme has two deliberate deviations from strict modified Hepburn:

- long vowels use repeated ASCII vowel letters instead of macrons; and
- `を` / `ヲ` is `o`.

Every fixed-output supported unit is listed below. A slash joins equivalent
hiragana and katakana spellings; it does not denote an alternative output.

## Monographs

Small vowels and small y-kana have their standalone results in this table.
Contextual `っ` / `ッ`, `ー`, and `ん` / `ン` are specified separately.

| Hiragana | Katakana | Romaji |
| --- | --- | --- |
| ぁ | ァ | a |
| あ | ア | a |
| ぃ | ィ | i |
| い | イ | i |
| ぅ | ゥ | u |
| う | ウ | u |
| ぇ | ェ | e |
| え | エ | e |
| ぉ | ォ | o |
| お | オ | o |
| か | カ | ka |
| ゕ | ヵ | ka |
| き | キ | ki |
| く | ク | ku |
| け | ケ | ke |
| ゖ | ヶ | ke |
| こ | コ | ko |
| さ | サ | sa |
| し | シ | shi |
| す | ス | su |
| せ | セ | se |
| そ | ソ | so |
| た | タ | ta |
| ち | チ | chi |
| つ | ツ | tsu |
| て | テ | te |
| と | ト | to |
| な | ナ | na |
| に | ニ | ni |
| ぬ | ヌ | nu |
| ね | ネ | ne |
| の | ノ | no |
| は | ハ | ha |
| ひ | ヒ | hi |
| ふ | フ | fu |
| へ | ヘ | he |
| ほ | ホ | ho |
| ま | マ | ma |
| み | ミ | mi |
| む | ム | mu |
| め | メ | me |
| も | モ | mo |
| ゃ | ャ | ya |
| や | ヤ | ya |
| ゅ | ュ | yu |
| ゆ | ユ | yu |
| ょ | ョ | yo |
| よ | ヨ | yo |
| ら | ラ | ra |
| り | リ | ri |
| る | ル | ru |
| れ | レ | re |
| ろ | ロ | ro |
| ゎ | ヮ | wa |
| わ | ワ | wa |
| ゐ | ヰ | wi |
| ゑ | ヱ | we |
| を | ヲ | o |
| ん | ン | n, subject to the apostrophe rule below |
| が | ガ | ga |
| ぎ | ギ | gi |
| ぐ | グ | gu |
| げ | ゲ | ge |
| ご | ゴ | go |
| ざ | ザ | za |
| じ | ジ | ji |
| ず | ズ | zu |
| ぜ | ゼ | ze |
| ぞ | ゾ | zo |
| だ | ダ | da |
| ぢ | ヂ | ji |
| づ | ヅ | zu |
| で | デ | de |
| ど | ド | do |
| ば | バ | ba |
| び | ビ | bi |
| ぶ | ブ | bu |
| べ | ベ | be |
| ぼ | ボ | bo |
| ぱ | パ | pa |
| ぴ | ピ | pi |
| ぷ | プ | pu |
| ぺ | ペ | pe |
| ぽ | ポ | po |
| ゔ | ヴ | vu |

### Small vowels

Standalone `ぁぃぅぇぉ` and `ァィゥェォ` are `a i u e o`. A small kana only
contracts with the preceding kana when the exact pair occurs in the yoon or
extended table. Thus `きぁ` is `kia`, while `つぁ` is the listed `tsa`.

### Historical wi/we and object-marker o

`ゐ` / `ヰ` is `wi`, and `ゑ` / `ヱ` is `we`, providing deterministic
coverage for historical kana. `を` / `ヲ` is always `o`; Yomi does not offer a
`wo` option. The extended digraph `うぉ` / `ウォ` remains `wo`.

## Yoon

Yoon detection is greedy over this closed table. Each pair emits one syllable
and has one mapping covering both source kana.

| Hiragana | Katakana | Romaji |
| --- | --- | --- |
| きゃ | キャ | kya |
| きゅ | キュ | kyu |
| きょ | キョ | kyo |
| しゃ | シャ | sha |
| しゅ | シュ | shu |
| しょ | ショ | sho |
| ちゃ | チャ | cha |
| ちゅ | チュ | chu |
| ちょ | チョ | cho |
| にゃ | ニャ | nya |
| にゅ | ニュ | nyu |
| にょ | ニョ | nyo |
| ひゃ | ヒャ | hya |
| ひゅ | ヒュ | hyu |
| ひょ | ヒョ | hyo |
| みゃ | ミャ | mya |
| みゅ | ミュ | myu |
| みょ | ミョ | myo |
| りゃ | リャ | rya |
| りゅ | リュ | ryu |
| りょ | リョ | ryo |
| ぎゃ | ギャ | gya |
| ぎゅ | ギュ | gyu |
| ぎょ | ギョ | gyo |
| じゃ | ジャ | ja |
| じゅ | ジュ | ju |
| じょ | ジョ | jo |
| ぢゃ | ヂャ | ja |
| ぢゅ | ヂュ | ju |
| ぢょ | ヂョ | jo |
| びゃ | ビャ | bya |
| びゅ | ビュ | byu |
| びょ | ビョ | byo |
| ぴゃ | ピャ | pya |
| ぴゅ | ピュ | pyu |
| ぴょ | ピョ | pyo |

## Extended digraphs

These are the complete supported loanword pairs. The folded hiragana forms
have exactly the same result as their common katakana spellings.

| Hiragana | Katakana | Romaji |
| --- | --- | --- |
| ふぁ | ファ | fa |
| ふぃ | フィ | fi |
| ふぇ | フェ | fe |
| ふぉ | フォ | fo |
| ふゅ | フュ | fyu |
| ゔぁ | ヴァ | va |
| ゔぃ | ヴィ | vi |
| ゔぇ | ヴェ | ve |
| ゔぉ | ヴォ | vo |
| ゔゅ | ヴュ | vyu |
| てぃ | ティ | ti |
| でぃ | ディ | di |
| とぅ | トゥ | tu |
| どぅ | ドゥ | du |
| てゅ | テュ | tyu |
| でゅ | デュ | dyu |
| うぃ | ウィ | wi |
| うぇ | ウェ | we |
| うぉ | ウォ | wo |
| しぇ | シェ | she |
| じぇ | ジェ | je |
| ちぇ | チェ | che |
| つぁ | ツァ | tsa |
| つぃ | ツィ | tsi |
| つぇ | ツェ | tse |
| つぉ | ツォ | tso |
| いぇ | イェ | ye |

## Sokuon

`っ` / `ッ` emits the first consonant letter of the next romanized unit as
its own mapping. Before `ち`, `ちゃ`, `ちゅ`, or `ちょ` and their katakana
forms, it emits `t`: `っち` is `tchi`, and `まっちゃ` is `matcha`.

For a run of sokuon, every sokuon looks through the run to the same next unit;
`っっか` is `kkka`. At end of input, or before a vowel kana, syllabic n, or
an unmapped grapheme, each sokuon passes through unchanged. For example,
`あっ` is `aっ` and `っあ` is `っa`.

## Prolonged sound mark

`ー` repeats the last `a`, `i`, `u`, `e`, or `o` in the immediately preceding
romanized unit. It owns a separate source mapping: `ラーメン` is `raamen` and
`スーパー` is `suupaa`. Consecutive marks repeat the same vowel. At the start
or after a unit with no vowel, `ー` passes through unchanged.

This repeated-letter policy is the scheme's wapuro-style ASCII deviation from
strict modified Hepburn; Yomi never emits macrons. Ordinary long-vowel
spellings remain letter-by-letter, so `おう` is `ou`.

## Syllabic n

`ん` / `ン` is normally `n`, including before b, m, or p: `かんぱい` is
`kanpai`, not `kampai`. Before an a-row vowel (including a small vowel) or
full-size `や` / `ゆ` / `よ`, it is `n'`: `んあ` is `n'a` and `んや` is
`n'ya`. The apostrophe belongs to the `ん` source mapping.

## NFC/NFD combining marks

A base followed by combining dakuten U+3099 or handakuten U+309A composes
before digraph, sokuon, prolonged-mark, and syllabic-n logic. The single
resulting mapping covers the full base-plus-mark byte range. The complete
composition table is:

| Base + mark | Composed kana | Romaji |
| --- | --- | --- |
| か / カ + U+3099 | が / ガ | ga |
| き / キ + U+3099 | ぎ / ギ | gi |
| く / ク + U+3099 | ぐ / グ | gu |
| け / ケ + U+3099 | げ / ゲ | ge |
| こ / コ + U+3099 | ご / ゴ | go |
| さ / サ + U+3099 | ざ / ザ | za |
| し / シ + U+3099 | じ / ジ | ji |
| す / ス + U+3099 | ず / ズ | zu |
| せ / セ + U+3099 | ぜ / ゼ | ze |
| そ / ソ + U+3099 | ぞ / ゾ | zo |
| た / タ + U+3099 | だ / ダ | da |
| ち / チ + U+3099 | ぢ / ヂ | ji |
| つ / ツ + U+3099 | づ / ヅ | zu |
| て / テ + U+3099 | で / デ | de |
| と / ト + U+3099 | ど / ド | do |
| は / ハ + U+3099 | ば / バ | ba |
| ひ / ヒ + U+3099 | び / ビ | bi |
| ふ / フ + U+3099 | ぶ / ブ | bu |
| へ / ヘ + U+3099 | べ / ベ | be |
| ほ / ホ + U+3099 | ぼ / ボ | bo |
| は / ハ + U+309A | ぱ / パ | pa |
| ひ / ヒ + U+309A | ぴ / ピ | pi |
| ふ / フ + U+309A | ぷ / プ | pu |
| へ / ヘ + U+309A | ぺ / ペ | pe |
| ほ / ホ + U+309A | ぽ / ポ | po |
| う / ウ + U+3099 | ゔ / ヴ | vu |

Composition also applies when a documented small kana follows. For example,
`き` + U+3099 + `ゃ` is `gya`, and `ウ` + U+3099 + `ァ` is `va`; each is one
digraph mapping over all three source scalars. These results are exactly the
corresponding composed yoon and extended-table rows above.

The wa-row combinations that Unicode can precompose as `ヷヸヹヺ` are
deliberately excluded. A combining mark without a composable base passes
through unchanged.

## Katakana folding

Katakana U+30A1..U+30F6 folds internally to the hiragana scalar 0x60 lower;
U+30FD and U+30FE fold the same way. Thus all monographs and documented pairs
are script-equivalent, including `ヴ` / `ゔ`. U+30F7..U+30FA (`ヷヸヹヺ`) do
not fold. `ー` has its contextual rule instead of folding.

This is an internal comparison step only. Source text and mapping byte ranges
always refer to the caller's original spelling.

## Unmapped pass-through

Kanji, ASCII, emoji, punctuation such as `。、「」・`, half-width katakana,
iteration marks `ゝゞヽヾ`, spacing marks `゛゜`, `ヷヸヹヺ`, and every other
unmapped grapheme cluster pass through byte-for-byte with one exact source
mapping. No punctuation is transliterated. Empty input produces empty output
and no mappings.

## Fixture provenance and review

The normative fixture is the hand-reviewed, checked-in Mojo table in
`tests/kana_fixture_data.mojo`. It lists both scripts, every precomposed and
base-plus-combining voiced spelling, and every yoon and extended spelling.
Its 399 fixed-output rows and 52 explicit composition-equivalence rows are
locked by tests. There is no generated runtime data and no external
romanization database.

Unicode scalar names and canonical kana composition relationships are checked
against **The Unicode Standard, Version 17.0.0**, Hiragana and Katakana block
charts, retrieved 2026-08-20:

- <https://www.unicode.org/charts/PDF/U3040.pdf>
- <https://www.unicode.org/charts/PDF/U30A0.pdf>

The romanization choices themselves are Yomi's documented convention above.
