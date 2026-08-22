#!/usr/bin/env python3
"""Generate Yomi's compact Mojo pinyin lookup table.

The checked-in artifact is sufficient for consumers. This script is a
development-only reproducibility tool and deliberately uses only Python's
standard library.
"""

from __future__ import annotations

import argparse
import hashlib
from pathlib import Path
import sys


SOURCE_VERSION = "0.13.0"
UNICODE_VERSION = "14.0.0"
SOURCE_SHA256 = "b240322a1dbe7bb4abffb1889cdbbb3f124bc3242d27ea40a10f51596c41db50"
SOURCE_URL = (
    "https://raw.githubusercontent.com/mozillazg/"
    "pinyin-data/v0.13.0/pinyin.txt"
)
FIELD_BYTES = 6
RECORD_BYTES = 6 + 3 * FIELD_BYTES + 1

_PLAIN_CHARACTERS = str.maketrans(
    {
        "ā": "a",
        "á": "a",
        "ǎ": "a",
        "à": "a",
        "ē": "e",
        "é": "e",
        "ě": "e",
        "è": "e",
        "ế": "ê",
        "ề": "ê",
        "ō": "o",
        "ó": "o",
        "ǒ": "o",
        "ò": "o",
        "ī": "i",
        "í": "i",
        "ǐ": "i",
        "ì": "i",
        "ū": "u",
        "ú": "u",
        "ǔ": "u",
        "ù": "u",
        "ǘ": "ü",
        "ǚ": "ü",
        "ǜ": "ü",
        "ń": "n",
        "ň": "n",
        "ǹ": "n",
        "ḿ": "m",
        "\N{COMBINING MACRON}": None,
        "\N{COMBINING CARON}": None,
        "\N{COMBINING GRAVE ACCENT}": None,
    }
)


def _plain(reading: str) -> str:
    """Match rust-pinyin 0.10's `Pinyin::plain()` conversion."""
    return reading.translate(_PLAIN_CHARACTERS)


def _parse_rows(source: bytes) -> list[tuple[int, tuple[str, ...]]]:
    rows: list[tuple[int, tuple[str, ...]]] = []
    seen: set[int] = set()
    for line_number, raw_line in enumerate(source.decode("utf-8").splitlines(), 1):
        line = raw_line.split("#", 1)[0].strip()
        if not line:
            continue
        try:
            code_text, readings_text = line.split(":", 1)
            code_point = int(code_text.removeprefix("U+"), 16)
        except ValueError as error:
            raise ValueError(f"invalid source row {line_number}: {raw_line!r}") from error
        if code_point in seen:
            raise ValueError(f"duplicate code point U+{code_point:04X}")
        seen.add(code_point)

        # Ordinary searchable Han text is the BMP Unified Ideographs block.
        # U+3007 IDEOGRAPHIC NUMBER ZERO is the one common Han-like scalar
        # outside that block represented by this source.
        if code_point != 0x3007 and not 0x4E00 <= code_point <= 0x9FFF:
            continue

        readings: list[str] = []
        for marked in readings_text.strip().split(","):
            reading = _plain(marked)
            if reading not in readings:
                readings.append(reading)
            if len(readings) == 3:
                break
        if not readings:
            continue
        for reading in readings:
            byte_length = len(reading.encode("utf-8"))
            if byte_length > FIELD_BYTES:
                raise ValueError(
                    f"reading {reading!r} for U+{code_point:04X} is "
                    f"{byte_length} bytes; maximum is {FIELD_BYTES}"
                )
        rows.append((code_point, tuple(readings)))

    rows.sort(key=lambda row: row[0])
    return rows


def _pad(reading: str) -> str:
    return reading + " " * (FIELD_BYTES - len(reading.encode("utf-8")))


def _render(source: bytes) -> str:
    digest = hashlib.sha256(source).hexdigest()
    if digest != SOURCE_SHA256:
        raise ValueError(
            f"source SHA-256 mismatch: expected {SOURCE_SHA256}, got {digest}; "
            f"download {SOURCE_URL}"
        )
    rows = _parse_rows(source)
    records = []
    for code_point, readings in rows:
        fields = list(readings) + [""] * (3 - len(readings))
        record = f"{code_point:06X}" + "".join(_pad(value) for value in fields)
        if len(record.encode("utf-8")) + 1 != RECORD_BYTES:
            raise AssertionError(f"invalid generated record width for U+{code_point:04X}")
        records.append(record)

    return f'''\
"""Generated primary and common pinyin lookup data.

DO NOT EDIT. Regenerate with `scripts/generate_pinyin_data.py`.
Source: mozillazg/pinyin-data {SOURCE_VERSION} (`pinyin.txt`)
Source URL: {SOURCE_URL}
Unicode data version: {UNICODE_VERSION}
License: MIT
Source SHA-256: {SOURCE_SHA256}
Coverage: U+3007 and assigned U+4E00..U+9FFF rows
"""

comptime _PINYIN_DATA_VERSION = "{SOURCE_VERSION}"
comptime _PINYIN_UNICODE_VERSION = "{UNICODE_VERSION}"
comptime _PINYIN_SOURCE_SHA256 = (
    "{SOURCE_SHA256}"
)
comptime _PINYIN_RECORD_BYTES = {RECORD_BYTES}
comptime _PINYIN_RECORD_COUNT = {len(rows)}
comptime _PINYIN_TABLE = """\\
{chr(10).join(records)}
"""
'''


def _arguments() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "source",
        type=Path,
        help=f"checked-out pinyin-data {SOURCE_VERSION} pinyin.txt",
    )
    parser.add_argument(
        "--output",
        type=Path,
        default=Path("src/yomi/chinese/_pinyin_data.mojo"),
        help="generated Mojo artifact path",
    )
    parser.add_argument(
        "--check",
        action="store_true",
        help="exit unsuccessfully when the checked-in artifact differs",
    )
    return parser.parse_args()


def main() -> int:
    args = _arguments()
    try:
        rendered = _render(args.source.read_bytes())
    except (OSError, UnicodeError, ValueError) as error:
        print(f"generate_pinyin_data.py: {error}", file=sys.stderr)
        return 2

    if args.check:
        try:
            existing = args.output.read_text(encoding="utf-8")
        except OSError as error:
            print(f"generate_pinyin_data.py: {error}", file=sys.stderr)
            return 2
        if existing != rendered:
            print(
                f"generate_pinyin_data.py: {args.output} is stale; regenerate it",
                file=sys.stderr,
            )
            return 1
        return 0

    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(rendered, encoding="utf-8", newline="\n")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
