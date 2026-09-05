#!/usr/bin/env python3
"""Offline integrity and deterministic-output tests for the optional installer."""

import hashlib
import importlib.util
import io
import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

SPEC = importlib.util.spec_from_file_location("installer", Path(__file__).with_name("install_ipadic.py"))
installer = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(installer)


class InstallerTests(unittest.TestCase):
    def test_bad_hash_and_size_are_rejected(self):
        with tempfile.TemporaryDirectory() as directory:
            source = Path(directory)
            (source / "input.csv").write_bytes(b"bad")
            entry = {"name": "input.csv", "size": 3, "sha256": hashlib.sha256(b"good").hexdigest()}
            with self.assertRaisesRegex(ValueError, "SHA-256 mismatch"):
                installer.verified_bytes(entry, source)
            entry["sha256"] = hashlib.sha256(b"bad").hexdigest()
            entry["size"] = 4
            with self.assertRaisesRegex(ValueError, "size/SHA-256 mismatch"):
                installer.verified_bytes(entry, source)

    def test_offline_reads_are_bounded_before_checksum_validation(self):
        class ObservedStream(io.BytesIO):
            def read(self, size=-1):
                self.requested_size = size
                return super().read(size)

        stream = ObservedStream(b"oversized input")
        entry = {"name": "input.csv", "size": 3, "sha256": "unused"}
        with patch.object(Path, "open", return_value=stream):
            with self.assertRaisesRegex(ValueError, "size/SHA-256 mismatch"):
                installer.verified_bytes(entry, Path("unused"))
        self.assertEqual(stream.requested_size, 4)
        entry["size"] = installer.MAX_DOWNLOAD + 1
        with self.assertRaisesRegex(ValueError, "source size must be within"):
            installer.verified_bytes(entry, Path("unused"))

    def test_fixture_integrity_and_complete_source_inventory(self):
        manifest = json.loads(installer.MANIFEST.read_text())
        self.assertEqual(len([x for x in manifest["files"] if x["name"].endswith(".csv")]), 26)
        self.assertEqual(manifest["source_rows"], 392126)
        self.assertEqual(manifest["surfaces"], 325871)
        self.assertEqual(manifest["readings"], 341842)
        fixture = installer.ROOT / "tests/fixtures/ipadic/readings.tsv"
        notice = (fixture.parent / "README.md").read_text()
        self.assertIn(hashlib.sha256(fixture.read_bytes()).hexdigest(), notice)
        license_entry = next(x for x in manifest["files"] if x["name"] == "COPYING")
        license_bytes = (installer.ROOT / "LICENSES/ipadic-COPYING").read_bytes()
        self.assertEqual(hashlib.sha256(license_bytes).hexdigest(), license_entry["sha256"])

    def test_csv_schema_and_control_fields_are_rejected(self):
        with self.assertRaisesRegex(ValueError, "expected 13"):
            installer.compile_dictionary({"tiny.csv": b"invalid,row\n"})
        fields = ["bad\tfield", "0", "0", "0", "*", "*", "*", "*", "*", "*", "*", "a", "a"]
        with self.assertRaisesRegex(ValueError, "invalid empty/control field"):
            installer.compile_dictionary({"tiny.csv": (",".join(fields) + "\n").encode()})

    def test_atomic_replacement_preserves_exact_bytes(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "nested/output"
            installer.atomic_write(path, b"first")
            installer.atomic_write(path, b"second\n")
            self.assertEqual(path.read_bytes(), b"second\n")
            self.assertEqual(list(path.parent.iterdir()), [path])


if __name__ == "__main__":
    unittest.main()
