---
name: tldr
description: Get a quick map of all files and what they do by extracting TLDR headers. Use before diving into an unfamiliar area of the codebase.
triggers: ["*tldr", "*ora map", "*swe tldr", "*pe tldr"]
requires: []
---

# TLDR Skill — Codebase File Map

## Overview

Every source file in this project contains a TLDR header block:

```
// Short description of the file
//
// TLDR:
// Overview: What this file does.
// Problem:  What problem it solves.
// Solution: How it solves it.
// Breaking Changes: None / list any.
```

This skill extracts those headers with a single command — giving you a fast, readable map of the entire codebase without opening any files.

---

## Commands

### Full codebase map (all Dart source files)
```bash
rgrep "TLDR" app/lib -B2 -A6 --include="*.dart"
```

### Specific subdirectory
```bash
rgrep "TLDR" app/lib/features/calendar -B2 -A6 --include="*.dart"
rgrep "TLDR" app/lib/core -B2 -A6 --include="*.dart"
```

### All file types (agents, docs, scripts)
```bash
rgrep "TLDR" . -B2 -A6 --include="*.dart" --include="*.py" --include="*.md" \
  --exclude-dir=".git" --exclude-dir=".dart_tool" --exclude-dir="build"
```

### Makefile shortcut
```bash
make tldr
```

---

## Quick Reference

| Scope | Command |
|-------|---------|
| All lib files | `make tldr` |
| Features only | `rgrep "TLDR" app/lib/features -B2 -A6 --include="*.dart"` |
| Core only | `rgrep "TLDR" app/lib/core -B2 -A6 --include="*.dart"` |
| Tests | `rgrep "TLDR" app/test -B2 -A6 --include="*.dart"` |
| Everything | `rgrep "TLDR" . -B2 -A6 --exclude-dir=.git --exclude-dir=build` |

---

## Output Format

```
path/to/file.dart-// Short one-line description of the file
path/to/file.dart-//
path/to/file.dart:// TLDR:
path/to/file.dart-// Overview: What this thing does.
path/to/file.dart-// Problem:  What problem prompted it.
path/to/file.dart-// Solution: How it solves it.
path/to/file.dart-// Breaking Changes: No.
path/to/file.dart-//
path/to/file.dart-// -------------------------------------------------------
--
(next file...)
```

`--` separates each file match. `-B2` shows the description line above TLDR. `-A6` captures through Breaking Changes.

---

## Workflow

1. **Orient before coding**: Run `make tldr` to understand what exists before writing anything.
2. **Targeted exploration**: Scope to a subdirectory when working on a specific feature.
3. **New file checklist**: Every new file MUST include a TLDR header. Template:

```dart
// <One-line description of what this file does>.
//
// TLDR:
// Overview: <What does this class/module do?>
// Problem:  <What problem does it solve?>
// Solution: <How does it solve it?>
// Breaking Changes: No.
//
// ---------------------------------------------------------------------------
```

---

## Integration with Personas

- **Oracle** (`*ora map`): Use to orient before answering "where is X?" questions.
- **Neo** (`*swe tldr`): Run before starting any new feature to understand the landscape.
- **Morpheus**: Use during arch reviews to verify all files are documented.
- **Bob** (`*pe tldr`): Use to audit TLDR coverage across the codebase.
