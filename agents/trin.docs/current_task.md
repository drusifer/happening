# Sprint 1 UAT — Open Bugs

## BUG-01: NowIndicator fraction — product decision
- **Drew says**: 15% (not 33% or 20%)
- **Fix**: `_kNowIndicatorFraction = 0.15` in `timeline_strip.dart`
- **Severity**: Minor / product preference

## BUG-02: Strip not at top of display
- **Symptom**: Strip appears ~65% down the screen, not y=0
- **Root cause**: `windowManager.setPosition(Offset.zero)` not honoured on Wayland/GNOME
  - Wayland compositors control window placement; apps cannot force arbitrary position via XDG Shell
- **Fix options**: Run under X11/XWayland (`GDK_BACKEND=x11`), or use a Wayland layer-shell approach
- **Severity**: HIGH — core feature broken

## BUG-03: Strip way too thick (~5 inches)
- **Symptom**: Strip is many inches tall, should be a thin bar (~30 logical px)
- **Root cause candidates**:
  - GTK enforces a minimum window height > 30px on this compositor
  - `screen_retriever.visibleSize` may return physical pixels on this HiDPI display, but `window_manager` Size is in logical pixels → mismatch
- **Severity**: HIGH — unusable

## BUG-04: Not truly always-on-top
- **Symptom**: Strip starts on top but new windows can cover it
- **Root cause**: `alwaysOnTop: true` via window_manager uses `_NET_WM_STATE_ABOVE` which only applies to existing window stack; new windows may still appear above it on some compositors
- **Fix**: `windowManager.setAlwaysOnTop(true)` called after every `show()`, or run under X11
- **Severity**: HIGH — core feature broken

## Recommended approach for Neo
All three HIGH bugs (02, 03, 04) likely share the same root cause: Wayland.
Try forcing X11 first: `GDK_BACKEND=x11 flutter run -d linux` — if that fixes positioning and always-on-top, update Makefile to set that env var.
