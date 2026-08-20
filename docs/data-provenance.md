# Data provenance

No generated lookup data is currently committed.

The initial Hangul choseong implementation is reviewed against **The Unicode
Standard, Version 17.0.0**, Section 3.12.5, “Sample Code for Hangul Algorithms”:

- source: <https://www.unicode.org/versions/Unicode17.0.0/core-spec/chapter-3/>;
- retrieved: 2026-08-20;
- algorithm constants used: `SBase = U+AC00`, `LBase = U+1100`,
  `NCount = 588`, `LCount = 19`, and `SCount = 11,172`;
- implemented range: `U+AC00..U+D7A3`;
- leading index formula: `(code_point - SBase) div NCount`.

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
