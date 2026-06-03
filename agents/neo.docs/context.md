# Neo Context — 2026-06-03

## Current State
- F-30 Polish, Display Selection Bug Fix, Primary Classification Fix, Window Anchoring Fix, Display Naming Fallback Duplication Fixes, and Startup Monitor Positioning Fix COMPLETE.
- Fixed positioning bug where restarting the app on a secondary display initially painted it on the primary display. We call `_strategy.moveToDisplay` inside the `waitUntilReadyToShow` callback before showing/painting the window at startup.
- Fixed display naming UX bug where cryptic hardware connector names (like `eDP-1` and `DP-3`) were shown to the user.
- Introduced `_connectorNameRegex` in `display_info.dart` that detects port formats (like `eDP-1`, `DP-3`, `HDMI-1`, `VGA-1`, `HDMI1`, `dp2`) and treats them as generic names, allowing `DisplayInfo.labelFor()` to fall back to clean `"Display N — WxH"` labels. Real monitor names remain unaffected.
- Fixed Display fallback name numbering duplication (both called "Display 1") under generic duplicate ID environments by modifying `DisplayInfo._stableIndex` to compare `d == this` (structural equality) instead of comparing display IDs (`d.id == id`), making indexing structurally unique.
- Refactored fallback name indexing in `DisplayInfo.labelFor()` to only count/index the displays that actually fall back to default names, rather than the total index of all displays. In a mixed setup, a display with a real OS name will be labeled with its name, and fallback displays will be labeled sequentially starting at "Display 1".
- Added unit tests in `display_info_test.dart` confirming correct fallback behaviors for connector patterns, duplicate display IDs, and mixed named/fallback display structures.
- Fixed anchoring bug where timestrip remained on the primary display at X=0 even when switched to a secondary monitor. Compare `_activeDisplay` structurally (`_activeDisplay != nextActive`) to ensure correct monitor re-anchoring.
- Fixed bug where all connected displays were labeled as "primary" when sharing generic/duplicate display IDs under some OS-level window servers (like X11/Wayland).
- Modified `ScreenRetrieverDisplayProbe._toInfo` to compare physical display size and visible work area coordinates in addition to the display ID (`d.id == primary.id && d.size == primary.size && (d.visiblePosition ?? Offset.zero) == (primary.visiblePosition ?? Offset.zero)`) to ensure correct primary designation.
- Fixed bug where multiple display options could appear selected simultaneously in the settings panel by changing the comparison logic from raw `DisplayId` comparison to structural `DisplayInfo` equality (`d == activeDisplay`).
- Swapped inline `FingerprintChoiceResolver` construction in SettingsPanel (`settings_panel.dart`) for the new `DisplayService.setPersistedChoice(choice)` convenience method.
- Hoisted the `onWeakMatch` callback parameter into `DisplayService` constructor, avoiding duplicate callback execution during display resolver resolution and telemetry loss on user-driven switches.
- Fixed critical bug in `app/lib/app.dart` where `displayService` was not being passed to `TimelineStrip` when the user was in the authenticated state, causing the Display Selection section in the Settings Panel to be hidden.
- Fixed mock `WindowService` compile error in `app/integration_test/timeline_strip_test.dart` by passing a mocked `DisplayService`.
- Fixed all `dart_code_linter` and style warnings across `window_service.dart`, `timeline_layout.dart`, `window_service_test.dart`, `display_fallback_indicator_test.dart`, and `settings_panel_test.dart`.
- Full test suite: 427 passing, 1 pre-existing failing golden (`hover_card_alignment` golden). Lint checks are completely clean (`make lint` exits 0).

## Key context carried into next session
- `DisplayService` constructor exposes `initialChoice` and `onWeakMatch` callback.
- `DisplayService.setPersistedChoice` internally wraps `FingerprintChoiceResolver` and registers the hoisted `onWeakMatch` callback.
- `DisplayService._refresh` resolves display choice once per refresh to prevent duplicate callbacks.
- All empty virtual methods in `WindowService` now have explicit `return;` statements to satisfy `no-empty-block` rules.
- Display picker row uses `d == activeDisplay && !inFallback` for selection checking to be resilient against non-unique OS display IDs.
- Primary monitor classification uses display coordinates and size fallback for robust OS-generic detection.
- Window position changes in `WindowService` compare `_activeDisplay` structurally to guarantee correct monitor re-anchoring when swapped.
- Display labels filter out low-level port connector names using `_connectorNameRegex` to output recognizable, clean labels (Display 1, Display 2) to users.
- Stable display fallback index numbering matches only against filtered displays that actually use a fallback/default label, ensuring contiguous numbering.
- Display index comparison uses `d == this` to correctly isolate individual displays even when OS-level display IDs overlap.
- Window positioning is initialized on the active display (moving the window to `_activeDisplay.workAreaOrigin` prior to performing display reservations and showing the window) to guarantee a correct initial display render on startup.
