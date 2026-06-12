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
- Hide button (`arrow_left`) is positioned at `left: 8.0`, with width of 38px (layout icon size 24 + 12px padding + 2px border) -> ends at x = 46.0.
- Left toolbar starts at `left: 54.0`. Spacing between the hide button and the first toolbar icon (refresh) is `54 - 46 = 8`px.
- Spacing between other toolbar buttons is exactly 8px, ensuring uniform spacing.
- Show button in the mini-widget is also padded by `left: 8.0` for consistent padding/margin.
- All icons inside `_IconButton` default to a visual scale size of 32px, while retaining a layout footprint size of 24px to preserve structural spacing.
- Spacing around `DisplayFallbackIndicator` is managed dynamically (it packages its own trailing `SizedBox(width: 8.0)` when visible) to prevent a 16px double-gap when hidden.

### Mini widget
- In `_buildLayout`: when `_isHidden || _hideAnim.value < 1.0` → return `_buildMiniWidget`.
- Mini widget: `MouseRegion(cursor: click) > GestureDetector(showStrip) > Row[countdown StreamBuilder + show button]`.
- Countdown uses `_buildCountdownContent` (not `_buildCountdownPositioned` — avoid Positioned in Row).

## Session Key Findings (2026-06-11)
- **Window Resizing Positioning**: Shrinking a window using `setSize` alone on Windows/Linux without explicitly defining position offsets can cause the window manager to relocate the window relative to its right edge or cascaded placement (causing the mini-widget to drift to the right side of the screen/about an inch down). Fixed by explicitly positioning the window at `_activeDisplay.workAreaOrigin` during `resizeToMiniStrip` and `resizeToFullStrip`.
- **Defensive UI Alignment**: Wrapped the mini widget in `Align(alignment: Alignment.topLeft)` to defend against OS constraints forcing the layout to center or shift right.
- **Hide-When-Expanded Race Condition**: Tapping the hide button when the strip is expanded (either via mouse hover or open settings) can trigger a race condition where the asynchronous collapse operation runs concurrently with/after the hide operation. We resolved this by introducing `sendAndAwait` in `ExpansionController` to await the completion of the collapse before proceeding with the hide sequence. We now unconditionally collapse and await the collapse completion when hiding.
- **Debug Logging**: Added detailed `_log.info` and `_log.fine` logging statements to track the sequence of operations inside `_hideStrip()` and `_showStrip()`.
