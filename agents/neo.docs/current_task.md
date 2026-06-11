# Neo Current Task — 2026-06-11

## Status: F-31 button style fix COMPLETE — 449/449 green

## DONE in this session

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
- `make test` → **447/447 passing**

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
