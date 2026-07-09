#!/usr/bin/env python
"""Unit tests for sync_version.py — run via `make test-tools`."""

import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import sync_version as sv  # noqa: E402


class UpdateMetadataTest(unittest.TestCase):
    def setUp(self):
        self._tmpdir = tempfile.TemporaryDirectory()
        self._orig_metadata_file = sv.METADATA_FILE
        sv.METADATA_FILE = Path(self._tmpdir.name) / "app_metadata.dart"

    def tearDown(self):
        sv.METADATA_FILE = self._orig_metadata_file
        self._tmpdir.cleanup()

    def _write(self, version):
        sv.METADATA_FILE.write_text(
            f"const String appVersion = '{version}';\n"
            "const String appAboutUrl = 'https://gs.works/happening';\n"
        )

    def test_updates_plain_version(self):
        self._write("0.5.3")
        self.assertTrue(sv.update_metadata("0.5.4"))
        self.assertIn("appVersion = '0.5.4'", sv.METADATA_FILE.read_text())

    def test_updates_version_with_build_suffix(self):
        # Real-world case: appVersion carries a Flutter build suffix (e.g. '0.5.3+1'),
        # which the settings panel displays via app_metadata.dart's appVersion constant.
        self._write("0.5.3+1")
        self.assertTrue(sv.update_metadata("0.5.4"))
        self.assertIn("appVersion = '0.5.4'", sv.METADATA_FILE.read_text())


class UpdatePubspecTest(unittest.TestCase):
    def setUp(self):
        self._tmpdir = tempfile.TemporaryDirectory()
        self._orig_pubspec_file = sv.PUBSPEC_FILE
        sv.PUBSPEC_FILE = Path(self._tmpdir.name) / "pubspec.yaml"

    def tearDown(self):
        sv.PUBSPEC_FILE = self._orig_pubspec_file
        self._tmpdir.cleanup()

    def _write(self, version):
        sv.PUBSPEC_FILE.write_text(
            "name: happening\n"
            f"version: {version}\n"
            "environment:\n"
            "  sdk: '>=3.0.0 <4.0.0'\n"
        )

    def test_updates_version_with_build_suffix(self):
        self._write("0.5.3+2")
        self.assertTrue(sv.update_pubspec("0.5.4"))
        content = sv.PUBSPEC_FILE.read_text()
        self.assertIn("version: 0.5.4\n", content)
        self.assertNotIn("+2", content)


if __name__ == "__main__":
    unittest.main()
