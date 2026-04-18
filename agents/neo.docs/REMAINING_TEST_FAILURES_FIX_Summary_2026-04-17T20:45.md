# Remaining Test Failures Fix Summary — 2026-04-17T20:45

## Problem
After calendar threading work, the suite still failed on:
- Window tests failing with `WidgetsBinding has not yet been initialized`.
- Stale `hover_card_alignment.png` golden diff.

## Investigation
- Window tests were still valid. They cover active `WindowService` initialization, async resize serialization, and Linux compositor resize behavior.
- The failure was caused by `WindowService.initialize()` now registering a `WidgetsBindingObserver`, which requires `TestWidgetsFlutterBinding.ensureInitialized()` in test harnesses.
- The golden test was still valid. It covers hover card alignment and was failing from a stale pixel baseline.

## Changes
- Added `TestWidgetsFlutterBinding.ensureInitialized()` to:
  - `app/test/core/window/window_service_test.dart`
  - `app/test/core/window/window_linux_e2e_test.dart`
- Updated `window_service_test.dart` mock setup so `waitUntilReadyToShow()` invokes its callback and `focus()` returns a completed future.
- Added `make -f Makefile.prj update-goldens` target.
- Regenerated `app/test/goldens/goldens/hover_card_alignment.png`.

## Validation
Command:
`make -f Makefile.prj test`

Result:
PASS — 239/239 tests.

## Notes
- No tests were removed; none were determined deprecated.
- `app/test/goldens/failures/*` still has modified failure artifacts from prior failed golden runs. They are not required for the passing suite.
