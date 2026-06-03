# Neo Current Task — 2026-06-03

## Status: F-30 Polish, Settings Panel Fixes, Primary Classification Fix, Window Movement Anchoring Fix, Display Naming Fallback Duplication Fixes, and Startup Monitor Positioning Fix COMPLETE — handing off to Trin for UAT

## DONE in this session
- ✅ **Startup Monitor Position Fix**: Modified `WindowService.initialize` to position the window at `_activeDisplay` (via `_strategy.moveToDisplay`) inside the `waitUntilReadyToShow` callback. This resolves the bug where restarting the app on a secondary display would initially position and paint it on the primary display.
- ✅ Added a unit test in `window_service_test.dart` asserting that the window is correctly positioned at the active display's `workAreaOrigin` during initialization.
- ✅ **Window Movement Anchoring Fix**: Modified `_onDisplayChangedInner` in `window_service.dart` to calculate `activeChanged` structurally using `_activeDisplay != nextActive` instead of checking raw ID differences. This ensures the window is correctly moved to the secondary screen via `strategy.moveToDisplay()` under duplicate display ID setups.
- ✅ Added a unit test in `window_service_test.dart` asserting that display changes with generic/duplicate IDs correctly call `setPosition` on the WindowManager with the new coordinates.
- ✅ **Primary Display Classification Fix**: Modified `ScreenRetrieverDisplayProbe._toInfo` in `screen_retriever_adapter.dart` to compare display ID, physical size, and visible position. This ensures that when the OS reports duplicate generic display IDs, only the actual primary display gets classified with `isPrimary: true`, preventing all displays from being labeled as primary.
- ✅ **Display Selection Duplicate Fix**: Modified `_DisplaySectionState.build` in `settings_panel.dart` to compare `d == activeDisplay` instead of `d.id == activeId`. This resolves the issue where multiple displays could appear selected/checked when they shared generic or duplicate IDs from the OS.
- ✅ **F-30 Display Name Fallback Indexing Fix**: Modified `DisplayInfo._stableIndex` to compare `d == this` structurally instead of `d.id == id`, which was causing both screens to resolve to index 0 (and be labeled as "Display 1") under generic duplicate ID environments.
- ✅ **Fallback Count Partitioning Fix**: Modified `DisplayInfo.labelFor` fallback indexing to count only the monitors that actually fall back to default names, rather than indexing all monitors. Now mixed displays (e.g. one real monitor name, two unnamed ones) are numbered cleanly as "Dell U..." (usable) and "Display 1", "Display 2" (fallbacks).
- ✅ Added 2 unit tests to `display_info_test.dart` validating unique indices under identical display IDs, and mixed named/fallback display numbering.
- ✅ **F30-Polish**: Hoisted `onWeakMatch` callback into `DisplayService` constructor.
- ✅ Added `initialChoice` parameter to `DisplayService` constructor to decouple initial resolver creation.
- ✅ Implemented `DisplayService.setPersistedChoice(choice)` convenience method to register `FingerprintChoiceResolver` with the hoisted callback.
- ✅ Refactored `_DisplaySectionState._chooseDisplay` in `settings_panel.dart` to use `setPersistedChoice(choice)`.
- ✅ Fixed `_refresh()` inside `DisplayService` to cache and resolve display match once, preventing duplicate callback invocations.
- ✅ **Critical Fix**: Passed `displayService: widget.displayService` to `TimelineStrip` in `app.dart` inside the authenticated state. This was causing the Display Selection section in the Settings Panel to be hidden when logged in.
- ✅ Fixed `integration_test/timeline_strip_test.dart` compilation error by supplying the mock `DisplayService`.
- ✅ Resolved `no-empty-block` linter warnings in `WindowService` by adding explicit `return;` to empty virtual hooks.
- ✅ Cleared all warnings (unnecessary imports, const constructor recommendations, comment references) to make `make lint` clean.
- ✅ Added 3 new unit tests to `display_service_test.dart` for the hoisted `onWeakMatch`, `initialChoice`, and `setPersistedChoice` functions.
- ✅ Created new headless integration tests in `app_integration_test.dart` validating parameter-forwarding for both authenticated and unauthenticated views.

## Test Status
- `make test` -> **427 passing, 1 failing** (pre-existing golden `hover_card_alignment` test).
- `make lint` -> **PASS** (Zero issues found).

## NOT YET STARTED (next)
- ☐ F30-C3: BLOCKED on Drew's Windows hardware
- ☐ F30-F1, F30-F2: Multi-platform UAT (hardware-blocked)
- ☐ F30-F3: PRD + USER_GUIDE docs (Oracle/Trin can do post-Morpheus-approval)
