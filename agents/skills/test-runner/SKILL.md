---
name: test-runner
description: Run tests using the project Makefile. Use for executing the Flutter test suite and validating code changes.
triggers: ["*test", "*qa test"]
---

# Test Runner Skill

## Overview

Run tests via `make` to ensure consistent environment setup (pub deps, LLVM path, etc.).

## Commands

| Action | Command |
|--------|---------|
| All tests with coverage | `make test` |
| Watch mode (re-run on change) | `make test-watch` |

## Workflow

1. **Run tests**: `make test`
2. **On failure**: Read error output, identify failing test, fix issue
3. **Re-run**: `make test` again to confirm green

## Integration with Personas

- **Neo** (`*swe test`): Run after implementing changes
- **Trin** (`*qa test`): Run full suite for verification
