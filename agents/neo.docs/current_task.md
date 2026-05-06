# Linux Click-Through XWayland Only — 2026-05-05
**Status**: COMPLETE
**Progress**: 100%

## Request
XWayland is the only supported Linux click-through path; remove logic for other Linux variants.

## Done
- `ClickThroughCapability.detect()` now returns supported only when:
  - backend is exactly `xwayland`
  - native channel reports click-through available
- Renamed the channel capability method:
  - `isLayerShellAvailable()` -> `isClickThroughAvailable()`
  - Dart channel invokes native `isClickThroughAvailable`
- Native Linux plugin now reports click-through availability only for `xwayland`.
  - pure `x11` is unsupported
  - native `wayland` is unsupported
  - layer-shell compile-time capability is no longer used for click-through support
- Updated tests to enforce:
  - X11 rejected even if fake native support is true
  - XWayland accepted when native support is true
  - Wayland rejected even if fake native support is true

## Validation
- `make format` passed.
- `make test FILE=test/core/linux/click_through_capability_test.dart` passed 4/4.
- `make test` passed 304/304.
- `make build-linux` passed.

# Linux Click-Through Capability + Makefile Test Target — 2026-05-05
**Status**: COMPLETE
**Progress**: 100%

## Request
Remove the Linux transparent env var gate, remove the Wayland-only restriction because X11 works too, and fix `make test FILE=...` running the full suite.

## Done
- Removed `LINUX_TRANSPARENT` and `HAPPENING_LINUX_TRANSPARENT` from `Makefile run-linux`.
- Changed `ClickThroughCapability.detect()` so it trusts the native channel support result instead of rejecting non-Wayland backends.
- Updated Linux native click-through plugin:
  - X11 and XWayland now report support because GDK input-shape is available there.
  - Wayland still reports support only when `LAYER_SHELL_AVAILABLE` is compiled in.
- Added capability tests for X11, XWayland, and unsupported native results.
- Fixed Makefile/mkf forwarding:
  - `make test FILE=...` forwards `FILE` into the inner make invocation.
  - `test` and `test-watch` pass `$(FILE) $(ARGS)` to `flutter test`.

## Validation
- `make format` passed.
- `make test FILE=test/core/linux/click_through_capability_test.dart` ran only that file and passed 3/3.
- `make test` passed 303/303.
- `make build-linux` passed.

# Window Behavior Checkbox Layout — 2026-05-05
**Status**: COMPLETE
**Progress**: 100%

## Request
Change the settings panel window behavior setting from a vertical two-option layout into a compact horizontal checkbox using the same real estate.

## Done
- Replaced the `Window behavior` section header plus two-option `_PickerRow<WindowMode>` with one compact checkbox row.
- Checkbox behavior:
  - checked = `WindowMode.transparent` / clicks pass through
  - unchecked = `WindowMode.reserved` / reserve top space
  - disabled when the platform forces one mode (macOS transparent, Linux unsupported reserved)
- Removed the visible reserved-space option text and the Linux unsupported explanatory paragraph from the panel.
- Updated settings panel widget tests for checkbox value/enabled states and tap behavior.

## Validation
- `make format` passed.
- `make test` passed 300/300.
- `make build-linux` passed.

# Expanded Settings Room — 2026-05-05
**Status**: COMPLETE
**Progress**: 100%

## Request
Add more room in the expanded section because settings controls are taller after the new buttons.

## Done
- Increased `WindowService.getExpandedHeight()`:
  - small: `240 -> 300`
  - medium: `250 -> 320`
  - large: `260 -> 340`
- Updated tests/fakes that asserted the old medium expanded height.
- Aligned standalone demo/test entry constants in `simple_main.dart` and `windows_test.dart` from `250` to `320`.

## Validation
- `make format` passed.
- `make test` passed.
- `make build-linux` passed.

# Refresh Fresh-Collapsed Recovery — 2026-05-05
**Status**: COMPLETE
**Progress**: 100%

## Request
Refresh should revert the timeline/window to a fresh collapsed state and clear state variables that might be stuck. Conditional display variables must be logged so the next black-area reproduction can show which branch is wrong.

## Done
- Added `WindowService.resetToFreshCollapsedState()`:
  - clears `_wantsExpanded`
  - sets `isExpandedNotifier=false` immediately
  - serializes a physical collapse through the existing resize gate
  - logs before/after desired/rendered expansion state
- Refresh button now clears strip state before calendar refresh:
  - settings closed
  - hovered event cleared
  - hovering flag cleared
  - focus indicator timer/state cleared
  - layout cache cleared
  - interaction hold re-synced
- Expanded backdrop remains `Colors.transparent` on every platform.
- Paint/state debug logs now include conditional display inputs without event IDs:
  - expanded, wantsExpanded, card, settings, hovered bool, hovering, focus, mode
  - transparentIdle, canInteract, sign-in/loading flags, layout present, event count
  - collapsed/expanded heights, surface opacity, transparent backdrop ARGB, painter bg ARGB, maxH
- Calendar runtime logs are count-only; detailed calendar/event diagnostics and fixture raw response logging were removed.

## Validation
- `make format` passed.
- `make test` passed 300/300.
- `make build-linux` passed.
- `make analyze` is still blocked by existing unrelated warning in `lib/main.dart:66` (`linuxTransparentSupported` visible-for-testing use).

## Next
User smoke should press refresh after the expanded area turns black, then try expanding again. The log should show `TimelineStrip.resetFreshCollapsed START/DONE` followed by collapsed `expanded=false wantsExpanded=false ...` state.

# Deterministic Expansion State Correction — 2026-05-05
**Status**: COMPLETE
**Progress**: 100%

## Request
Stop trying to be clever with sync state; make expansion deterministic.

## Correction
- `_wantsExpanded` is the declared desired state and is set synchronously by `expand()` / `collapse()`.
- `isExpandedNotifier` is now the rendered/allocated expanded state and flips to true only after Linux resize commands complete via `onExpanded`.
- This prevents `TimelineStrip` from rendering `expanded=true` while the Flutter root is still constrained to 60px.

## Validation
- `make test` passed 299/299.
- `make build-linux` passed.

# Linux Expand Surface Allocation Fix — 2026-05-05
**Status**: COMPLETE
**Progress**: 100%

## Request
Fix the black expanded area after first expand succeeds and second expand is black.

## Requirement
Expanded backdrop remains transparent on all platforms. The fix must make Flutter/card content paint into the expanded transparent area; it must not add an opaque backdrop.

## Diagnosis
Latest logs showed:
- first expand: `maxH=260.0`
- second expand: `expanded=true card=true ... maxH=60.0` even after Linux expand completed

That means the native window exposed expanded transparent space, but Flutter's render surface/layout remained collapsed-height.

## Fix
- In `LinuxResizeStrategy.expand()`, added a final `setSize(targetSize)` after `setMaximumSize(targetSize)`.
- This keeps the GTK min>max grow trick, then forces a fresh size allocation once constraints are valid.
- Updated strategy test order.

## Validation
- `make format` passed.
- `make test` passed 299/299.
- `make build-linux` passed.

## Next
User smoke should check that every expand reaches `maxH=260.0`, especially second/subsequent expands.

# Linux Expansion Race Fix — 2026-05-05
**Status**: COMPLETE
**Progress**: 100%

## Request
Fix the expansion race causing Linux expanded area black/collapse behavior.

## Root Cause
`AppLifecycleState.resumed` can fire while an expand request is in flight. The previous guard checked only `isExpandedNotifier.value`; at that instant it could still be `false`, so resume queued `collapse()` behind the active expand. The log showed exactly:
- `_doExpand() target ... isExpanded=false`
- `resumed — re-asserting collapsed window size`
- `collapse requested`
- expand completed
- queued collapse ran immediately

## Fix
- Added `_wantsExpanded` to `WindowService` as the latest requested logical state.
- `expand()` and `collapse()` update `_wantsExpanded` synchronously before any async work.
- Lifecycle resume skips collapsed recovery when expand is intended or complete.
- `_doExpand()` sets `isExpandedNotifier=true` before its first awaited debug log.

## Validation
- `make format` passed.
- `make test` passed 299/299.
- `make build-linux` passed.

## Next
User smoke should verify the first expand no longer logs a collapsed resume recovery and no queued collapse follows an expand.

# Calendar Logging Privacy Cleanup — 2026-05-05
**Status**: COMPLETE
**Progress**: 100%

## Request
Remove sensitive calendar event logging; keep only counts.

## Done
- Removed `[CalendarDiag]` metadata/event logs from `GoogleCalendarService`.
- Added count-only `[CalendarFetch] fetched <raw> raw items, <timed> timed items`.
- Changed `CalendarController` logs:
  - no selected calendar ID set
  - no calendar ID in per-calendar fetch count
  - no calendar ID in fetch failure warning

## Validation
- `make format` passed.
- `make test` passed 298/298.

# Linux Paint Debug Instrumentation — 2026-05-05
**Status**: COMPLETE
**Progress**: 100%

## Request
Add debug logs to painting calls for the Linux all-black expanded-area bug.

## Added
- `app/lib/features/timeline/timeline_strip.dart`
  - `TimelineStrip.paint-state` logs deduplicated render state changes:
    - expanded/collapsed
    - hover card/settings visibility
    - hovered event ID
    - focus/window mode/transparent idle
    - backdrop and painter background ARGB
    - layout max height
- `app/lib/features/timeline/timeline_painter.dart`
  - `TimelinePainter.paint` logs throttled paint calls:
    - canvas size
    - background ARGB
    - surface/emphasis opacity
    - event count and hovered ID
    - loading/sign-in flags

## Validation
- `make format` passed.
- `make test` passed 298/298.
- `make build-linux` passed.

## Latest Hypothesis
The latest run showed a `resumed` event can still queue collapsed recovery during an in-flight expand, before lifecycle handling observes `isExpanded=true`. The new paint logs should confirm whether Flutter continues painting the card/strip correctly when the native surface goes black.

# Linux Expanded Black Background Fix — 2026-05-05
**Status**: COMPLETE
**Progress**: 100%

## Request
Fix Linux black expanded window/card background using `build/build-expand-black-bug.out`. Expanded backdrop must remain transparent on all platforms.

## Findings
- The log shows resize itself completing: expand reaches `setMaximumSize done — calling onExpanded` and `_doExpand() onExpanded fired`.
- Failed-looking cycles correlate with Linux lifecycle resume reassertions that call `_doExpand()` again while `isExpanded=true`.
- `resumed` is a lifecycle notification, not a sticky state that needs to be cleared.
- Its impact was indirect: `WindowService` used every `resumed` to run another physical resize. Re-expanding an already expanded transparent window can expose GTK/native black before Flutter composites the next frame.
- The expanded full-height backdrop remains transparent.

## Fix
- `app/lib/core/window/window_service.dart`
  - On `AppLifecycleState.resumed`, return immediately when `isExpandedNotifier.value` is true.
  - Keep collapsed resume recovery, but route it through `collapse()` so it uses the normal gate.
- `app/test/core/window/window_service_test.dart`
  - Updated lifecycle test to verify expanded resume makes no resize calls.

## Validation
- `make test FILE=app/test/core/window/window_service_test.dart` passed; target ran full suite, 298/298.
- `make format` passed.
- `make build-linux` passed.

## Next
Needs user smoke on Linux hover expansion.

# Protocol Init Load Neo — 2026-05-05
**Status**: COMPLETE
**Progress**: 100%

## Done
- Loaded `bob-protocol` instructions.
- Loaded Neo persona instructions and state files.
- Read recent `agents/CHAT.md` context.
- Read `agents/PROJECT.md`; confirmed `via: enabled`.

## Active Engineering Task
No new implementation task is active from this invocation.

## Last Completed Engineering Task
Linux transparency/black expanded section fix is complete and validated:
- `make test` recorded green at 298/298.
- `make build-linux` recorded clean.

## Resume Point
Await user direction. If the user reports Linux transparency still failing, follow `next_steps.md`.

# Linux Black Expanded Section Fix — 2026-05-05
**Status**: COMPLETE ✅
**Progress**: 100%

## Bug
All-black layer covered expanded section on Linux, blocking hover cards and settings.
Not the GTK window background issue (separate RGBA fix). This was the Flutter background
Container being `Colors.transparent` in transparent-idle mode even when expanded.

## Root Cause
`timeline_strip.dart` background Container used `_isTransparentIdle` to pick transparent color.
In transparent mode, `_isTransparentIdle = true` during the 300ms before HoverFocusController
fires. During that window: window expands, Container is transparent, GTK black background
bleeds through, covering the expanded section (hover cards still render but can't be seen
over the black — they're painted after by the Stack but the black comes from the GTK layer
behind all Flutter content).

Windows is fine because `(isExpanded && Platform.isWindows)` short-circuits to transparent
and DWM compositing handles it. Linux has no DWM equivalent.

## Fix
`app/lib/features/timeline/timeline_strip.dart` (background Container color):

```
Before: _isTransparentIdle || (isExpanded && Platform.isWindows)
After:  (isExpanded && Platform.isWindows) OR (_isTransparentIdle && !isExpanded)
        fallback: stripBackgroundColor.withValues(alpha: _surfaceOpacity)
```

Expanded section now ALWAYS gets solid background on non-Windows.
Collapsed strip in idle transparent mode stays see-through as intended.

## Also fixed (same session)
`app/linux/runner/my_application.cc`: Added RGBA visual + app_paintable so GTK window
background itself is transparent (compositor sees alpha). Without this, `Colors.transparent`
in Flutter shows GTK black rather than the desktop.

## Validation
- `make test` ✅ 298/298 green
- `make build-linux` ✅ clean
