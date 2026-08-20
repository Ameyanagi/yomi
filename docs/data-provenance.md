# Data provenance

No generated lookup data is currently committed.

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

These reviewed constants and scalar literals implement an algorithm; no
external lookup database or generated artifact is embedded. Unicode material
is used under the Unicode Terms of Use:
<https://www.unicode.org/license.txt>.

Every future generated artifact must record:

- upstream project and canonical URL;
- upstream version and retrieval date;
- exact file checksums and licenses;
- generator source and command;
- deterministic output checks;
- review notes for semantic or licensing changes.

Generation tools are development dependencies. Consumers install the generated
Mojo data and do not require Python, Rust, C, or another runtime.
