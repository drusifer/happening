# Neo Context — 2026-06-11

## F-31 Architecture Summary

### WindowService hooks (Phase A)
- `getMiniWidth(fontSizePx)` = `fontSizePx * 6.0 + 60.0` (formula from arch)
- `prepareToHide()` → `onHideStrip()` (virtual, no-op base)
- `completeShow()` → `onShowStrip()` (virtual, no-op base)
- `resizeToMiniStrip(fontSizePx)` → `wm.setSize(miniWidth × collapsedHeight)`
- `resizeToFullStrip()` → `wm.setSize(_screenWidth × collapsedHeight)`
- Linux: undock on hide, redock on show (only if reserved mode)
- Windows: disposeAppBar on hide, registerAppBar on show (only if enabled + reserved)
- macOS: inherits base no-ops

### Strip hide/show state machine (Phase B)
- `_isHidden = false` (starts visible per AC-F31-3-6)
- `_preHideSentToBack = false` (saves STB state for restore after show)
- `_hideAnim`: AnimationController, 300ms, value=1.0 (fully visible)
- On hide: save STB → restoreToFront if STB → prepareToHide → close settings → `_isHidden=true` → `_hideAnim.reverse()` → `resizeToMiniStrip`
- On show: `resizeToFullStrip` → `_isHidden=false` → `EC.collapsed` → `_hideAnim.forward()` → `completeShow` → restore STB if needed

### Critical layout detail
`_HideButton` is at `left: 0`, NO horizontal padding → covers x=0..24px exactly.
Left toolbar starts at `left: 8` with `_IconButton(padding: all(6))` → first icon center at x=26.
No overlap. `_HideButton` Positioned comes AFTER toolbar in Stack for correct z-order.

### Mini widget
In `_buildLayout`: when `_isHidden || _hideAnim.value < 1.0` → return `_buildMiniWidget`.
Mini widget: `MouseRegion(cursor: click) > GestureDetector(showStrip) > Row[countdown StreamBuilder + show button]`.
Countdown uses `_buildCountdownContent` (not `_buildCountdownPositioned` — avoid Positioned in Row).
