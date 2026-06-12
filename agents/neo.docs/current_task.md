# Neo Current Task — 2026-06-11

## Status: F-31 positioning, race conditions, logging, padding/spacing, 32px icon scale, and snap launch path fix COMPLETE — 451/451 green

## DONE in this session
- [x] Fix snap launch error ("Not running in AOT mode but could not resolve the kernel binary") by correcting `--aot-shared-library-name` in the snap launcher to point to `$SNAP/lib/libapp.so`.
- [x] Add left padding/margin of 8.0px to the hide button (`arrow_left`) in the full strip view.
- [x] Ensure equal spacing of 8px between all buttons (including hide, refresh, flip-to-back, fallback indicator, settings) in the full strip view.
- [x] Set all strip icons to a visual scale size of 32px (retaining 24px layout size).
- [x] Fix double-spacing (16px) gap in toolbar when `DisplayFallbackIndicator` is hidden.
- [x] Regenerate golden test images to match the new layout positions and 32px icon sizes.
- [x] Fix hide-when-expanded race condition: Introduced `sendAndAwait` in `ExpansionController` and updated `_hideStrip()` in `timeline_strip.dart` to unconditionally await the collapse completion.
- [x] Fix mini-widget positioning: updated `resizeToMiniStrip` and `resizeToFullStrip` in `window_service.dart` to explicitly position the window at `_activeDisplay.workAreaOrigin`.
- [x] Wrap mini widget in `Align(alignment: Alignment.topLeft)` to defend against OS minimum width restrictions forcing the layout to center or shift right.
- [x] Add detailed debug logging to `_hideStrip()` and `_showStrip()` methods in `timeline_strip.dart` to track state transitions and window resize steps.
- [x] Updated unit tests in `window_service_test.dart` to verify `setPosition(Offset.zero)` is invoked.
- [x] Added unit tests in `expansion_controller_test.dart` to verify `sendAndAwait` future resolution behavior.

### Phase A — WindowService hooks
- ✅ **F31-A1**: Added to `window_service.dart`:
  - Protected hooks: `onHideStrip()`, `onShowStrip()` (no-ops in base)
  - Public API: `getMiniWidth()`, `prepareToHide()`, `completeShow()`, `resizeToMiniStrip()`, `resizeToFullStrip()`
- ✅ **F31-A2**: Platform overrides:
  - `LinuxWindowService.onHideStrip()` → `undock()` (only if reserved mode)
  - `LinuxWindowService.onShowStrip()` → `_reserveLinuxStrut()` (only if reserved)
  - `WindowsWindowService.onHideStrip()` → `_disposeAppBar()` (only if enabled)
  - `WindowsWindowService.onShowStrip()` → `_registerAppBar()` (only if enabled + reserved)
- ✅ 12 new tests in `window_service_test.dart` (getMiniWidth formula, delegation, Linux hide/show, overlay no-op, idempotent cycle)

### Phase B — Strip UI
- ✅ **F31-B1**: Added to `_TimelineStripState`:
  - `SingleTickerProviderStateMixin`
  - State: `_isHidden = false`, `_preHideSentToBack = false`, `_hideAnim` (300ms, value=1.0)
  - `_hideStrip()` / `_showStrip()` with STB save/restore, settings close on hide, EC reset
- ✅ **F31-B2**: UI:
  - `_HideButton` widget (← arrow, 24×24 min target, no horizontal padding to avoid toolbar overlap)
  - `_buildMiniWidget()` with live countdown StreamBuilder + show button (→)
  - Mini widget branch in `_buildLayout` (`_isHidden || _hideAnim.value < 1.0`)
  - Hide button Positioned at `left: 0` AFTER toolbar in Stack (correct z-order)
- ✅ 8 new widget tests in `timeline_strip_hide_test.dart`
- ✅ Golden regenerated (hover_card_alignment.png updated to include hide button)

## Test Status
- `make test` → **451/451 passing**

## Key implementation note
The `_HideButton` has NO horizontal padding (just `BoxConstraints(minWidth: 24, minHeight: 24)`)
so it covers exactly x=0..24. The toolbar starts at `left: 8` with `_IconButton(padding: all(6))`
making the first icon center at x=26. No overlap between hide button (0..24) and refresh (center 26).
The `_HideButton` Positioned is placed AFTER `_buildLeftToolbar` in the Stack so it has higher
z-order and receives taps over the toolbar area if ever needed.

## NOT YET STARTED (next)
- ☐ F31-C1: Trin multi-platform UAT matrix
- ☐ F31-C2: Smith UX pass
- ☐ F31-C3: Oracle docs
