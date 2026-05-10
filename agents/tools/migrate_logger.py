#!/usr/bin/env python3
"""
migrate_logger.py  <file.dart>

Migrates one Dart file from AppLogger to native logging package Logger instances.

Changes made:
  unawaited(AppLogger.debug/log/warn/err(...))  →  _log.fine/info/warning/severe(...)
  await AppLogger.debug/log/warn/err(...)        →  _log.fine/info/warning/severe(...)
  AppLogger.debug/log/warn/err(...)              →  _log.fine/info/warning/severe(...)

  Adds  static final _log = Logger('ClassName');  to each class body.
  Adds  import 'package:logging/logging.dart';
  Removes  import 'package:happening/core/util/logger.dart';

Note: AppLogger.initialize() is intentionally NOT replaced (main.dart setup call).
Note: async/await cleanup on methods is left for a follow-up pass.

A .bak file is written before any changes. Delete backups once you're happy.
"""

import re
import shutil
import sys
from pathlib import Path

LEVEL_MAP = {
    'debug': 'fine',
    'log':   'info',
    'warn':  'warning',
    'err':   'severe',
}

LOGGING_IMPORT = "import 'package:logging/logging.dart';"
APPLOGGER_IMPORT_RE = re.compile(
    r"import 'package:happening/core/util/logger\.dart';\n?"
)


# ── Paren matching ────────────────────────────────────────────────────────────

def _find_closing_paren(src: str, open_pos: int) -> int:
    """Return index of ')' matching '(' at src[open_pos], or -1 on failure."""
    assert src[open_pos] == '('
    depth = 0
    i = open_pos
    in_str = False
    str_char = ''
    while i < len(src):
        c = src[i]
        if in_str:
            if c == '\\':
                i += 2
                continue
            if c == str_char:
                in_str = False
        else:
            if c in ('"', "'"):
                in_str = True
                str_char = c
            elif c == '(':
                depth += 1
            elif c == ')':
                depth -= 1
                if depth == 0:
                    return i
        i += 1
    return -1


# ── AppLogger call replacement ────────────────────────────────────────────────

def _replace_calls(src: str) -> str:
    """Replace every AppLogger.X(...) call pattern with _log.Y(...)."""
    result: list[str] = []
    i = 0
    n = len(src)

    while i < n:
        # Try longest prefix first so unawaited( is consumed correctly.
        matched = False
        for prefix, strip_outer in [
            ('unawaited(', True),
            ('await AppLogger.',     False),
            ('AppLogger.',           False),
        ]:
            if not src[i:].startswith(prefix):
                continue
            # For unawaited(, skip optional whitespace then require AppLogger.
            if strip_outer:
                skip = len(prefix)
                while skip < len(src) - i and src[i + skip] in ' \t\n\r':
                    skip += 1
                if not src[i + skip:].startswith('AppLogger.'):
                    continue  # not an AppLogger unawaited — leave as-is
                after_prefix = src[i + skip + len('AppLogger.'):]
                prefix_len = skip + len('AppLogger.')  # offset past unawaited( + ws + AppLogger.
            else:
                after_prefix = src[i + len(prefix):]
                prefix_len = len(prefix)
            m = re.match(r'(\w+)\(', after_prefix)
            if not m:
                continue
            method = m.group(1)
            log_method = LEVEL_MAP.get(method)
            if log_method is None:
                # e.g. AppLogger.initialize — leave untouched
                break
            # Position of '(' that opens the AppLogger call args
            call_open = i + prefix_len + len(method)
            call_close = _find_closing_paren(src, call_open)
            if call_close < 0:
                break  # malformed — leave as-is
            inner = src[call_open + 1 : call_close]
            if strip_outer:
                # consume the outer unawaited ')' too
                outer_close = call_close + 1
                if outer_close < n and src[outer_close] == ')':
                    result.append(f'_log.{log_method}({inner})')
                    i = outer_close + 1
                    matched = True
                    break
                # malformed unawaited — fall through
            else:
                result.append(f'_log.{log_method}({inner})')
                i = call_close + 1
                matched = True
                break

        if not matched:
            result.append(src[i])
            i += 1

    return ''.join(result)


# ── Logger field insertion ────────────────────────────────────────────────────

# FFI base types whose subclasses cannot have Dart fields.
_FFI_SKIP = {'Struct', 'Union', 'Opaque', 'NativeType'}

# Match a class declaration at the START of a line (rules out comments).
# Optional modifiers: abstract, final, base, sealed, interface, mixin.
_CLASS_LINE_RE = re.compile(
    r'^[ \t]*(?:(?:abstract|final|base|sealed|interface|mixin)\s+)*'
    r'class\s+(\w+)((?:[^{]|\n)*?)\{',
    re.MULTILINE,
)


def _add_logger_fields(src: str) -> str:
    """Insert 'static final _log = Logger(ClassName);' into each class body."""
    result = src
    offset = 0
    for m in _CLASS_LINE_RE.finditer(src):
        class_name = m.group(1)
        header_rest = m.group(2)  # everything between class Name and {

        # Skip FFI structs / unions — they can't have Dart static fields.
        if any(base in header_rest for base in _FFI_SKIP):
            continue

        insert_pos = m.end() + offset

        # Skip if _log is already declared anywhere in the class body (next 400 chars).
        if '_log' in result[insert_pos : insert_pos + 400]:
            continue

        field = f"\n  static final _log = Logger('{class_name}');"
        result = result[:insert_pos] + field + result[insert_pos:]
        offset += len(field)
    return result


# ── Import fixup ─────────────────────────────────────────────────────────────

def _fix_imports(src: str) -> str:
    src = APPLOGGER_IMPORT_RE.sub('', src)
    if LOGGING_IMPORT not in src:
        # Insert after the last `dart:` import (before first `package:` import),
        # or before the first import if there are no `dart:` imports.
        last_dart = None
        for m in re.finditer(r"^import 'dart:[^']*'[^;]*;\n?", src, re.MULTILINE):
            last_dart = m
        if last_dart:
            pos = last_dart.end()
        else:
            first_import = re.search(r"^import ", src, re.MULTILINE)
            pos = first_import.start() if first_import else 0
        src = src[:pos] + LOGGING_IMPORT + '\n' + src[pos:]
    return src


# ── Entry point ───────────────────────────────────────────────────────────────

def migrate(path: Path) -> None:
    if not path.exists():
        print(f'ERROR: {path} not found')
        sys.exit(1)

    # Skip logger.dart itself
    if path.name == 'logger.dart':
        print(f'SKIP: {path} (AppLogger definition — migrate manually)')
        return

    src = path.read_text()

    if 'AppLogger' not in src:
        print(f'SKIP: {path} (no AppLogger usage)')
        return

    bak = path.with_suffix(path.suffix + '.bak')
    shutil.copy2(path, bak)
    print(f'BAK:  {bak}')

    out = _replace_calls(src)
    out = _add_logger_fields(out)
    out = _fix_imports(out)

    path.write_text(out)
    print(f'DONE: {path}')
    print(f'      Review, run `make test`, then delete {bak.name} if happy.')


if __name__ == '__main__':
    if len(sys.argv) != 2:
        print(__doc__)
        print(f'Usage: python3 {sys.argv[0]} <file.dart>')
        sys.exit(1)
    migrate(Path(sys.argv[1]))
