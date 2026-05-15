# Neo Context — 2026-05-14

## Current State
Send-to-Back sprint COMPLETE. 266/266 green. No active sprint.

## Architecture (post-sprint)
- `WindowInteractionStrategy` interface: `initialize(mode)`, `sendToBack()`, `restoreToFront()`
- `BaseWindowInteractionStrategy`: `sendToBack()` = `setAlwaysOnTop(false)` + `blur()`; `restoreToFront()` = `setAlwaysOnTop(true)`
- `MacOsWindowInteractionStrategy` extends Base (macOS, supportsReserved=false)
- `ReservedWindowInteractionStrategy` extends Base (Linux + Windows, supportsReserved=true)
- `WindowService`: delegates `sendToBack()`/`restoreToFront()` to strategy; no pass-through code
- `TimelineFocusController`: `sendToBack()` + `restoreToFront()` + `isSentToBackNotifier` + 10s `_restoreTimer`
- `TimelineStrip`: `Icons.flip_to_back` button; active state via `isSentToBackNotifier`; no transparent focus model
- `HoverFocusController`: DELETED
- `WindowMode.transparent` → renamed to `WindowMode.overlay` (Phase A)

## Key files
- `app/lib/core/window/interaction_strategy/` — 4 files (interface, base, macos, reserved)
- `app/lib/core/window/window_service.dart`
- `app/lib/features/timeline/focus/timeline_focus_controller.dart`
- `app/lib/features/timeline/timeline_strip.dart`
- `task.md` — sprint board (complete)
