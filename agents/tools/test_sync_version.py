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

    def _write(self, version, msix_version="1.0.0.0"):
        sv.PUBSPEC_FILE.write_text(
            "name: happening\n"
            f"version: {version}\n"
            "environment:\n"
            "  sdk: '>=3.0.0 <4.0.0'\n"
            "msix_config:\n"
            f"  msix_version: {msix_version}\n"
        )

    def test_updates_version_with_build_suffix(self):
        self._write("0.5.3+2")
        self.assertTrue(sv.update_pubspec("0.5.4"))
        content = sv.PUBSPEC_FILE.read_text()
        self.assertIn("version: 0.5.4\n", content)
        self.assertNotIn("+2", content)

    def test_msix_version_mirrors_minor_patch_and_always_ends_in_zero(self):
        # Microsoft Store requires the 4th field to always be 0 (see the
        # msix_version comment in pubspec.yaml) — major is fixed at 1
        # (independent of the app's own pre-1.0 major).
        self._write("0.5.3", msix_version="1.5.3.0")
        self.assertTrue(sv.update_pubspec("0.5.4"))
        self.assertIn("msix_version: 1.5.4.0", sv.PUBSPEC_FILE.read_text())

    def test_rejects_new_version_with_build_suffix(self):
        # App stores require a clean X.Y.Z version — a Flutter build-number
        # suffix on the NEW version must be rejected outright, not silently
        # dropped.
        self._write("0.5.3")
        with self.assertRaises(SystemExit):
            sv.update_pubspec("0.5.4+9")


class UpdateSnapcraftTest(unittest.TestCase):
    def setUp(self):
        self._tmpdir = tempfile.TemporaryDirectory()
        self._orig_snapcraft_file = sv.SNAPCRAFT_FILE
        sv.SNAPCRAFT_FILE = Path(self._tmpdir.name) / "snapcraft.yaml"

    def tearDown(self):
        sv.SNAPCRAFT_FILE = self._orig_snapcraft_file
        self._tmpdir.cleanup()

    def test_rejects_new_version_with_build_suffix(self):
        sv.SNAPCRAFT_FILE.write_text("version: '0.5.3'\n")
        with self.assertRaises(SystemExit):
            sv.update_snapcraft("0.5.4+9")


class VersionFileValidationTest(unittest.TestCase):
    def setUp(self):
        self._tmpdir = tempfile.TemporaryDirectory()
        self._orig_version_file = sv.VERSION_FILE
        sv.VERSION_FILE = Path(self._tmpdir.name) / "version.txt"

    def tearDown(self):
        sv.VERSION_FILE = self._orig_version_file
        self._tmpdir.cleanup()

    def test_read_version_rejects_build_suffix(self):
        sv.VERSION_FILE.write_text("0.5.4+9\n")
        with self.assertRaises(SystemExit):
            sv.read_version()

    def test_write_version_rejects_build_suffix(self):
        with self.assertRaises(SystemExit):
            sv.write_version("0.5.4+9")
        # Must not have written the rejected value.
        self.assertFalse(sv.VERSION_FILE.exists())

    def test_read_version_accepts_plain_version(self):
        sv.VERSION_FILE.write_text("0.5.4\n")
        self.assertEqual(sv.read_version(), "0.5.4")


if __name__ == "__main__":
    unittest.main()
