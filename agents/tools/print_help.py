#!/usr/bin/env python
"""
print_help — Cross-platform Makefile help parser.

TLDR:
    Parses and prints Makefile target descriptions in a clean, unified format.
    Usage: print_help.py targets | project <targets-list>

"""

import sys
import re
from pathlib import Path

# ── Configuration ────────────────────────────────────────────────────────────

SCRIPT_DIR = Path(__file__).resolve().parent
PROJECT_ROOT = SCRIPT_DIR.parent.parent
MAKEFILE_PATH = PROJECT_ROOT / 'Makefile'

# ── Parser ───────────────────────────────────────────────────────────────────

def print_targets():
    if not MAKEFILE_PATH.exists():
        print(f"Error: Makefile not found at {MAKEFILE_PATH}", file=sys.stderr)
        sys.exit(1)
        
    seen = set()
    pattern = re.compile(r'^([a-zA-Z_-]+):.*?##\s*(.*)$')
    
    with open(MAKEFILE_PATH, 'r', encoding='utf-8') as f:
        for line in f:
            match = pattern.match(line)
            if match:
                target = match.group(1)
                desc = match.group(2)
                if target not in seen:
                    seen.add(target)
                    # Format matching make help spacing
                    print(f"    {target:<22} {desc}")


def print_project_targets(targets_str):
    targets = [t for t in targets_str.split(' ') if t.strip()]
    for target in targets:
        print(f"    {target:<22}")


def main():
    if len(sys.argv) < 2:
        print("Usage: print_help.py targets | project <targets-list>", file=sys.stderr)
        sys.exit(1)
        
    mode = sys.argv[1]
    if mode == 'targets':
        print_targets()
    elif mode == 'project':
        targets_str = sys.argv[2] if len(sys.argv) > 2 else ""
        print_project_targets(targets_str)
    else:
        print(f"Error: unknown mode {mode}", file=sys.stderr)
        sys.exit(1)


if __name__ == '__main__':
    main()
