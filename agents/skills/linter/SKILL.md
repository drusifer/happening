---
name: linter
description: Run code quality checks including linting, formatting, type analysis, and complexity metrics.
triggers: ["*qa lint", "*qa quality", "*qa check"]
---

# Linter Skill

## Overview

Code quality analysis via `make`. All checks run against the Flutter/Dart toolchain.

## Quick Reference

| Check | Command |
|-------|---------|
| All quality checks | `make lint` |
| Style + fatal warnings | `make lint-style` |
| Complexity + duplication metrics | `make lint-metrics` |
| Formatting check (no changes) | `make lint-format` |
| Auto-format source | `make format` |
| Dart analyzer (non-fatal) | `make analyze` |

## Workflow

1. **Before PR**: `make lint` — runs style, metrics, and format checks
2. **On failure**: Fix issues by priority (errors > warnings > style)
3. **Auto-fix formatting**: `make format` then re-run `make lint-format`

## Integration with Trin

- `*qa lint` — Run `make lint` on changed files area
- `*qa quality` — Full quality report via `make lint`
- `*qa check` — Pre-commit gate: `make lint && make test`
