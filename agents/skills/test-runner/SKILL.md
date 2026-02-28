---
name: test-runner
description: Run tests using the project Makefile. Use for executing test suites, running specific tests, and validating code changes.
triggers: ["*test", "*qa test"]
---

# Test Runner Skill

## Overview

This skill provides standardized test execution using the project's Makefile. All test commands should go through `make` to ensure consistent environment setup.

## Commands

### Run All Tests
```bash
make test
```
Runs the complete test suite with pytest.

### Run Specific Test File
```bash
pytest tests/unit/test_store.py -v
```

### Run Tests Matching Pattern
```bash
pytest -k "test_pattern" -v
```

### Run with Coverage
```bash
pytest --cov tests/ -v
```

## Quick Reference

| Action | Command |
|--------|---------|
| All tests | `make test` |
| Unit tests only | `pytest tests/unit/ -v` |
| Integration tests | `pytest tests/integration/ -v` |
| Single file | `pytest tests/unit/test_X.py -v` |
| By pattern | `pytest -k "pattern" -v` |
| Verbose output | Add `-v` or `-vv` flag |
| Stop on first fail | Add `-x` flag |

## Workflow

1. **Before testing**: Ensure dependencies are installed (`make install`)
2. **Run tests**: Use appropriate command from above
3. **On failure**: Read error output, identify failing test, fix issue
4. **Re-run**: Run specific failing test first, then full suite

## Integration with Personas

- **Neo** (`*swe test`): Run tests after implementing changes
- **Trin** (`*qa test`): Run full test suite for verification
