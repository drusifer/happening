# Current Task

## Linux Click-Through Sprint — CT Phase C — 2026-04-26
**Status**: COMPLETE ✅
**Progress**: 100%

### Delivered
- [x] CT-C1: HoverFocusController (`app/lib/features/timeline/focus/hover_focus_controller.dart`)
  - 300ms hover entry timer → `focusController.focus()`
  - onExit: cancel timer + `unfocus()` if currently focused
  - Guard: no-op when `!usesTransparentFocusModel`
  - Wired into TimelineStrip via `_onMouseEnter`/`_onMouseExit`
- [x] CT-C2: SettingsPanel CT-04 inline text
  - Linux without layer-shell: shows disabled "Let clicks pass through" chip + inline explanation
  - Text: "Transparent mode is not available in this session. Start Happening from a native Wayland session to enable it."
  - Hidden on verified Linux / macOS / Windows
- [x] Tests: 298/298 green, format clean, build-linux clean

### Next
- Sprint DONE. Await user smoke if desired.
