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

def read_version():
    if not VERSION_FILE.exists():
        print(f"Error: Single source of truth file not found at {VERSION_FILE}", file=sys.stderr)
        sys.exit(1)
    with open(VERSION_FILE, 'r', encoding='utf-8') as f:
        return f.read().strip()


def write_version(version):
    VERSION_FILE.parent.mkdir(parents=True, exist_ok=True)
    with open(VERSION_FILE, 'w', encoding='utf-8') as f:
        f.write(f"{version}\n")
    print(f"[OK] Updated version source: {VERSION_FILE} -> '{version}'")


def update_pubspec(version):
    if not PUBSPEC_FILE.exists():
        print(f"Warning: pubspec.yaml not found at {PUBSPEC_FILE}", file=sys.stderr)
        return False
    
    with open(PUBSPEC_FILE, 'r', encoding='utf-8') as f:
        content = f.read()

    # 1. Update version field (may carry a Flutter build suffix, e.g. 0.5.3+2)
    content, count_v = re.subn(r'^version:\s*[\d.]+(?:\+\S+)?', f"version: {version}", content, flags=re.MULTILINE)

    # 2. Update msix version field (four-part format like 1.0.X.Y or 1.0.5.1)
    # Parse version to check parts
    parts = version.split('.')
    if len(parts) >= 3:
        msix_ver = f"1.0.{parts[0]}.{parts[1]}{parts[2]}" # Keep standard format: 1.0.<major>.<minor><patch>
    else:
        msix_ver = f"1.0.{version}"
    
    content, count_m = re.subn(r'msix_version:\s*[\d\.]+', f"msix_version: {msix_ver}", content)

    with open(PUBSPEC_FILE, 'w', encoding='utf-8') as f:
        f.write(content)
    
    if count_v or count_m:
        print(f"[OK] Updated {PUBSPEC_FILE.name} (version, msix_version)")
        return True
    return False


def update_metadata(version):
    if not METADATA_FILE.exists():
        print(f"Warning: app_metadata.dart not found at {METADATA_FILE}", file=sys.stderr)
        return False
    
    with open(METADATA_FILE, 'r', encoding='utf-8') as f:
        content = f.read()

    # Existing value may carry a Flutter build suffix, e.g. '0.5.3+1'.
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
