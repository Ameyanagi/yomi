#!/usr/bin/env python3
"""Opt-in, checksum-verified IPADIC preparation; runtime consumption is pure Mojo."""

import argparse
import csv
import hashlib
import io
import json
import os
from pathlib import Path
import tempfile
import urllib.request

ROOT = Path(__file__).resolve().parents[1]
MANIFEST = ROOT / "data/ipadic/sources.json"
COMMIT = "61b90ba6e669dc2d7d533d4a80d206f3b31d52b1"
HEADER = f"# yomi-ipadic-v1\tIPADIC-2.7.0-20070801\t{COMMIT}\n"
MAX_DOWNLOAD = 16 * 1024 * 1024


def verified_bytes(entry, source_dir=None):
    expected_size = entry["size"]
    if not isinstance(expected_size, int) or not 0 <= expected_size <= MAX_DOWNLOAD:
        raise ValueError(f"{entry['name']}: source size must be within [0, {MAX_DOWNLOAD}]")
    if source_dir is None:
        with urllib.request.urlopen(entry["url"], timeout=60) as response:
            data = response.read(expected_size + 1)
    else:
        with (source_dir / entry["name"]).open("rb") as stream:
            data = stream.read(expected_size + 1)
    if len(data) != entry["size"] or hashlib.sha256(data).hexdigest() != entry["sha256"]:
        raise ValueError(f"{entry['name']}: source size/SHA-256 mismatch; use the pinned source")
    return data


def compile_dictionary(sources):
    entries = {}
    rows = 0
    for name in sorted(sources):
        if not name.endswith(".csv"):
            continue
        reader = csv.reader(io.StringIO(sources[name].decode("euc_jp"), newline=""))
        for line, row in enumerate(reader, 1):
            if len(row) != 13:
                raise ValueError(f"{name}:{line}: expected 13 IPADIC CSV fields")
            surface, reading = row[0], row[11]
            rows += 1
            # '*' explicitly means no reading supplied; it is never a guessed
            # pronunciation. Such source records do not contribute a reading.
            if reading == "*":
                continue
            for value in (surface, reading):
                if not value or any(ord(c) < 32 or ord(c) == 127 for c in value):
                    raise ValueError(f"{name}:{line}: invalid empty/control field")
            entries.setdefault(surface, set()).add(reading)
    text = HEADER + "".join(
        "\t".join([surface, *sorted(readings)]) + "\n"
        for surface, readings in sorted(entries.items())
    )
    return text.encode("utf-8"), entries, rows


def atomic_write(path, data):
    path.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.NamedTemporaryFile(dir=path.parent, delete=False) as stream:
        temporary = Path(stream.name)
        try:
            stream.write(data)
            stream.flush()
            os.fsync(stream.fileno())
            stream.close()
            os.replace(temporary, path)
        finally:
            temporary.unlink(missing_ok=True)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, required=True, help="explicit opt-in destination directory")
    parser.add_argument("--source-dir", type=Path, help="verify local pinned sources instead of downloading")
    parser.add_argument("--check", action="store_true", help="verify existing output without writing")
    args = parser.parse_args()
    manifest = json.loads(MANIFEST.read_text())
    sources = {entry["name"]: verified_bytes(entry, args.source_dir) for entry in manifest["files"]}
    artifact, entries, rows = compile_dictionary(sources)
    digest = hashlib.sha256(artifact).hexdigest()
    expected = manifest["artifact_sha256"]
    if digest != expected:
        raise ValueError(f"generated dictionary SHA-256 must be {expected}; got {digest}")
    metadata = json.dumps({
        "format": "yomi-ipadic-v1", "version": "2.7.0-20070801", "commit": COMMIT,
        "source_rows": rows, "surfaces": len(entries),
        "readings": sum(map(len, entries.values())), "sha256": digest,
        "license": "COPYING (NAIST/ICOT)",
    }, ensure_ascii=False, indent=2).encode() + b"\n"
    outputs = {"readings.tsv": artifact, "COPYING": sources["COPYING"], "manifest.json": metadata}
    for name, data in outputs.items():
        destination = args.output / name
        if args.check:
            if destination.read_bytes() != data:
                raise ValueError(f"{destination}: installed file differs from verified output")
        else:
            atomic_write(destination, data)
    print(f"verified {rows} rows, {len(entries)} surfaces, {sum(map(len, entries.values()))} readings; sha256={digest}")


if __name__ == "__main__":
    main()
