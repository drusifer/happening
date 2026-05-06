# Next Steps — Linux Click-Through XWayland Only

## Ready for Smoke
Run `make run-linux` from a Wayland desktop so GTK with `GDK_BACKEND=x11` lands in XWayland. The log should show:
- `Linux click-through: backend=xwayland supported=true`

If it shows `backend=x11` or `backend=wayland`, the settings checkbox should remain disabled by design.

# Next Steps — Linux Click-Through Capability + Makefile Test Target

## Ready for Smoke
Run `make run-linux`; the app will still use `GDK_BACKEND=x11`, but there is no longer a `HAPPENING_LINUX_TRANSPARENT` opt-in variable. The settings checkbox should be enabled on X11/XWayland when the native plugin reports support.

## Test Target
Use `make test FILE=test/core/linux/click_through_capability_test.dart` for a focused Flutter test run. `ARGS=...` is also forwarded.

# Next Steps — Window Behavior Checkbox Layout

## Ready for Smoke
Open settings and verify the left column now has a single compact `Let clicks pass through` checkbox row instead of the vertical `Window behavior` picker.

## Expected Platform States
- Windows / verified Linux: checkbox enabled; toggles transparent vs reserved.
- macOS: checked and disabled.
- Linux without transparent support: unchecked and disabled.

# Next Steps — Expanded Settings Room

## Ready for Smoke
Open settings in the expanded section and confirm the new buttons fit without clipping.

## If Still Tight
Increase only `WindowService.getExpandedHeight()` again; do not add opaque backgrounds or internal layout hacks.

# Next Steps — Refresh Fresh-Collapsed Recovery

## Ready for User Smoke
1. Reproduce the black expanded area.
2. Click refresh.
3. Verify the log shows:
   - `TimelineStrip.resetFreshCollapsed START ...`
   - `WindowService.resetFreshCollapsed START ...`
   - `WindowService.resetFreshCollapsed DONE wantsExpanded=false isExpanded=false`
   - `TimelineStrip.resetFreshCollapsed DONE ... hovered=false hovering=false settings=false`
4. Expand again and compare:
   - if `maxH` stays at collapsed height after reset, the bug is below Dart state in GTK/Flutter surface allocation;
   - if `hovered/card/settings` are wrong after reset, the bug is still in strip conditional state.

## Known Validation Note
`make analyze` remains blocked by unrelated `lib/main.dart:66` visible-for-testing warning; tests and Linux release build are green.

# Next Steps — Deterministic Expansion State

## Ready for User Smoke
Verify the log no longer shows `TimelineStrip.paint-state expanded=true ... maxH=60.0` before `LinuxResizeStrategy.expand() ... onExpanded`.

# Next Steps — Linux Expand Surface Allocation Fix

## Ready for User Smoke
Run Linux and confirm the second/subsequent expand logs include:
- `LinuxResizeStrategy.expand() final setSize done — calling onExpanded`
- `TimelineStrip.paint-state expanded=true ... maxH=260.0`

If it still shows `expanded=true ... maxH=60.0` after final setSize, the next fix should move deeper into native GTK/Flutter view allocation (`my_application.cc` / FlView sizing), not Dart layout.

# Next Steps — Linux Expansion Race Fix

## Ready for User Smoke
Run Linux again and verify:
- no `WindowService.didChangeAppLifecycleState: resumed — re-asserting collapsed window size` appears between `_doExpand()` and `LinuxResizeStrategy.expand() START`;
- no immediate `_doCollapse()` follows `_doExpand() onExpanded fired` unless the pointer genuinely exits;
- expanded area no longer turns black from the first expansion.

## If Still Black
With this race fixed, next investigation should focus on GTK/Flutter surface allocation: logs previously showed `expanded=true card=true` while `maxH=60.0`, meaning native window height and Flutter layout height may diverge.

# Next Steps — Calendar Logging

## Done
- Runtime calendar logs are count-only and do not include calendar IDs, event IDs, titles, emails, organizer/creator, or event timestamps.
- Tests pass.

# Next Steps — Linux Paint Debug Follow-Up

## Ready for User Smoke
Run the app again and reproduce the black expanded area. Inspect `build/build.out` for:
- `TimelineStrip.paint-state expanded=true card=true ... backdrop=#00000000`
- `TimelinePainter.paint ... hovered=<event-id>` around the moment the screen turns black
- any `WindowService.didChangeAppLifecycleState: resumed — re-asserting collapsed window size` during an in-flight expand

## If Black Reproduces With `card=true` And `TimelinePainter.paint` Still Logging
The Flutter widget tree is painting expected transparent/card state; focus next on native GTK/compositor transparency (`my_application.cc`, Flutter view/window visual, CSS/background clearing).

## If Black Reproduces With `card=false` Or Hover Cleared
Focus next on hover-controller/lifecycle event ordering and the queued collapse during in-flight expand.

# Next Steps — Linux Expanded Black Background Fix

## Done
- Kept expanded backdrop transparent for all platforms.
- Stopped `WindowService.didChangeAppLifecycleState(resumed)` from re-expanding an already expanded window.
- Kept collapsed resume recovery via the normal gated `collapse()` path.
- Validation: full test suite passed 298/298, format passed, build-linux passed.

## Next
1. Ask user to smoke test Linux hover expansion again.
2. If black still appears, inspect new logs for:
   - any remaining `_doExpand()` calls while `isExpanded=true`;
   - GTK/native background CSS issues in `app/linux/runner/my_application.cc`;
   - Flutter view alpha/compositor behavior despite `fl_view_set_background_color(#00000000)`.

# Next Steps — Neo Loaded 2026-05-05T18:15

## Current State
- Neo is initialized and idle.
- No new implementation task was assigned by `$bob-protocol init load neo`.
- Last engineering work remains the Linux transparency fix.

## If User Assigns New Implementation/Fix
1. Consult Oracle first per Neo protocol.
2. Use VIA for symbol navigation (`agents/PROJECT.md` declares `via: enabled`).
3. Keep the task small; update CHAT.md and Neo state before handoff/stop.

# Next Steps — Linux Transparency Fix COMPLETE

## Done (2026-05-05)
- Fixed GTK RGBA visual in `app/linux/runner/my_application.cc`
- `make build-linux` and `make test` (298/298) green

## If user reports transparency still not working after smoke test:
1. Check that user has selected "transparent" mode in settings panel (not reserved)
2. Verify `linuxTransparentSupported = true` in logs (`~/.config/happening/happening.log`)
3. Check if Dart-side `effectiveWindowMode` is returning `transparent` — might need to default Linux to transparent when supported (like macOS)
4. If GTK CSS is still painting background, may need CSS provider override in `my_application.cc`

## If starting a new task:
- Consult Oracle first per Neo protocol
- Use VIA for symbol navigation (`agents/PROJECT.md` declares `via: enabled`)
- Read CHAT.md last 10-20 messages to find pending handoffs
