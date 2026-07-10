#!/usr/bin/env python
"""
sync_version — Synchronizes project version across all relevant build files.

TLDR:
    Reads or sets the project version from `app/assets/version.txt` and propagates
    it to `pubspec.yaml` (including msix_config), `app_metadata.dart` (constant),
    and `snapcraft.yaml` configuration.
    Key functions: main() parses arguments; read_version() gets current state;
    set_version() writes new state; sync_all() coordinates file rewrites.
    Usage: sync_version.py [--set <version>]

"""

import sys
import re
import argparse
from pathlib import Path

# ── Paths ────────────────────────────────────────────────────────────────────

SCRIPT_DIR = Path(__file__).resolve().parent
PROJECT_ROOT = SCRIPT_DIR.parent.parent

VERSION_FILE = PROJECT_ROOT / 'app' / 'assets' / 'version.txt'
PUBSPEC_FILE = PROJECT_ROOT / 'app' / 'pubspec.yaml'
METADATA_FILE = PROJECT_ROOT / 'app' / 'lib' / 'core' / 'app_metadata.dart'
SNAPCRAFT_FILE = PROJECT_ROOT / 'snap' / 'snapcraft.yaml'

# ── Core Operations ──────────────────────────────────────────────────────────

def _reject_build_suffix(version):
    """App stores (Microsoft Store, App Store) require a clean X.Y.Z version —
    a Flutter build-number suffix ('+N') is not a supported version format
    here. Fail fast rather than let it propagate into a store submission."""
    if '+' in version:
        print(
            f"Error: version '{version}' contains '+' (a Flutter build-number "
            "suffix). This project does not support build-number suffixes - "
            "app stores require a clean X.Y.Z version. Use a version with no "
            "'+' suffix.",
            file=sys.stderr,
        )
        sys.exit(1)


def read_version():
    if not VERSION_FILE.exists():
        print(f"Error: Single source of truth file not found at {VERSION_FILE}", file=sys.stderr)
        sys.exit(1)
    with open(VERSION_FILE, 'r', encoding='utf-8') as f:
        version = f.read().strip()
    _reject_build_suffix(version)
    return version


def write_version(version):
    _reject_build_suffix(version)
    VERSION_FILE.parent.mkdir(parents=True, exist_ok=True)
    with open(VERSION_FILE, 'w', encoding='utf-8') as f:
        f.write(f"{version}\n")
    print(f"[OK] Updated version source: {VERSION_FILE} -> '{version}'")


def update_pubspec(version):
    _reject_build_suffix(version)
    if not PUBSPEC_FILE.exists():
        print(f"Warning: pubspec.yaml not found at {PUBSPEC_FILE}", file=sys.stderr)
        return False

    with open(PUBSPEC_FILE, 'r', encoding='utf-8') as f:
        content = f.read()

    # 1. Update version field. The OLD value in the file may still carry a
    # legacy Flutter build suffix (e.g. 0.5.3+2) from before this project
    # stopped supporting them — tolerate matching it away, even though the
    # NEW version (validated above) never has one.
    content, count_v = re.subn(r'^version:\s*[\d.]+(?:\+\S+)?', f"version: {version}", content, flags=re.MULTILINE)

    # 2. Update msix_version (four-part Store version: 1.<minor>.<patch>.0).
    # Microsoft Store requires the last field to always be 0 (see the
    # msix_version comment in pubspec.yaml). Major is fixed at 1, independent
    # of the app's own pre-1.0 major.
    version_parts = version.split('.')
    minor = version_parts[1] if len(version_parts) > 1 else '0'
    patch = version_parts[2] if len(version_parts) > 2 else '0'
    msix_ver = f"1.{minor}.{patch}.0"

    content, count_m = re.subn(r'msix_version:\s*[\d.]+(?:\+\S+)?', f"msix_version: {msix_ver}", content)

    with open(PUBSPEC_FILE, 'w', encoding='utf-8') as f:
        f.write(content)
    
    if count_v or count_m:
        print(f"[OK] Updated {PUBSPEC_FILE.name} (version, msix_version)")
        return True
    return False


def update_metadata(version):
    _reject_build_suffix(version)
    if not METADATA_FILE.exists():
        print(f"Warning: app_metadata.dart not found at {METADATA_FILE}", file=sys.stderr)
        return False

    with open(METADATA_FILE, 'r', encoding='utf-8') as f:
        content = f.read()

    # The OLD value in the file may still carry a legacy Flutter build suffix
    # (e.g. '0.5.3+1') from before this project stopped supporting them —
    # tolerate matching it away, even though the NEW version (validated
    # above) never has one.
    content, count = re.subn(
        r"const String appVersion = '[\d.]+(?:\+\S+)?';",
        f"const String appVersion = '{version}';",
        content
    )

    with open(METADATA_FILE, 'w', encoding='utf-8') as f:
        f.write(content)

    if count:
        print(f"[OK] Updated {METADATA_FILE.name} (appVersion)")
        return True
    return False


def update_snapcraft(version):
    _reject_build_suffix(version)
    if not SNAPCRAFT_FILE.exists():
        # Snapcraft is optional / Linux only
        return False
    
    with open(SNAPCRAFT_FILE, 'r', encoding='utf-8') as f:
        content = f.read()

    content, count = re.subn(r"^version:\s*['\"][\d\.]+['\"]", f"version: '{version}'", content, flags=re.MULTILINE)

    with open(SNAPCRAFT_FILE, 'w', encoding='utf-8') as f:
        f.write(content)

    if count:
        print(f"[OK] Updated {SNAPCRAFT_FILE.name} (version)")
        return True
    return False


# ── Main ─────────────────────────────────────────────────────────────────────

def main():
    parser = argparse.ArgumentParser(description="Synchronize project version numbers.")
    parser.add_argument('--set', type=str, help="Set a new version number and sync all files.")
    args = parser.parse_args()

    if args.set:
        version = args.set.strip()
        write_version(version)
    else:
        version = read_version()
        print(f"Syncing all build configurations to version '{version}'...")

    update_pubspec(version)
    update_metadata(version)
    update_snapcraft(version)
    print("[OK] Version synchronization complete.")


if __name__ == '__main__':
    main()
