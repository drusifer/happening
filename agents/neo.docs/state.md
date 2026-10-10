# Neo Agent State — Linux send-to-back not lowering (*fix loop)

## Context
- Bug (2026-10-09, Drew's Fedora Silverblue toolbox): Send to Back does not lower the timestrip.
- Root cause: BaseWindowInteractionStrategy.sendToBack shells out to `xdotool getactivewindow` then `python3` (ctypes XLowerWindow). `xdotool` is not installed in the toolbox; the exception is logged at fine and the lower step is skipped. Undeclared runtime dependency.
- Drew's direction: fix the DEPENDENCY, do not change the code. A native `lower` method-channel rewrite was started and REVERTED at Drew's request ("don't do that"). Do not re-propose it unprompted.
- Fix applied: scripts/setup.sh now checks `xdotool` and `python3` as runtime deps (Debian + Fedora names). No Dart/C++ changes.
- Noted, not acted on: my_application.cc:58 sets GDK_WINDOW_TYPE_HINT_DOCK; Mutter keeps docks above normal windows, so lowering may still not work on GNOME even with xdotool. Unverified.
- Flatpak (flatpak/works.gs.happening.yml) does not bundle xdotool, so send-to-back is degraded there too.

- 2nd finding (2026-10-09, Drew's run log after installing xdotool): `XLowerWindow wid=... exit=-11` = python helper SEGFAULT. Cause: ctypes script passed the Display* back as a bare Python int -> 32-bit C int -> truncated pointer. Only worked where the heap pointer fit in 32 bits. Reproduced standalone (Python 3.14, x86_64, ptr 0x5621...). Fix: `d=ctypes.c_void_p(l.XOpenDisplay(None))` — one line, same xdotool+python approach (DEC-011 respected).
- Possible follow-up (not done): log non-zero helper exit at warning instead of fine so this can't hide again.

- 3rd finding (2026-10-09): Drew retested after the ctypes fix — strip STILL does not lower. xprop on the strip (wid 12582915): _NET_WM_WINDOW_TYPE_DOCK, state ABOVE+STICKY+SKIP_*, strut set. Mutter layers docks above normal windows; XLowerWindow only restacks inside a layer. Mutter rule: dock + _NET_WM_STATE_BELOW -> bottom layer. `xdotool windowstate --add BELOW <wid>` sets it (xdotool 3.20211022). NOTE: xdotool ignores --remove when combined with --add in one call; use separate calls.
- Experiment (no code change) set BELOW for 4s then restored; window state verified back to original. Visual result unknown (Neo cannot see the screen; _NET_CLIENT_LIST_STACKING lists only this one X11 window under XWayland).
- debug.log only records INFO+, so sendToBack fine-level lines are not on disk; Neo cannot read Drew's terminal.

- 4th step (2026-10-09): watched experiment — ABOVE removed + BELOW added via xdotool -> Drew confirmed the strip went behind. Root cause CONFIRMED: dock layer on Mutter.
- Fix applied (attempt 3, Drew's go-ahead): base_window_interaction_strategy.dart — after XLowerWindow (kept), `xdotool windowstate --add BELOW <wid>`; restoreToFront runs `--remove BELOW <wid>` (remembered in _belowWid) before setAlwaysOnTop(true). Added `runProcess` static test seam. 4 new tests (Linux-only, skip elsewhere). Strategy tests 8/8, analyze clean.
- XLowerWindow python helper kept alongside BELOW (Drew did not choose replace vs keep; kept = smaller change).

- Send-to-back BELOW fix CONFIRMED working by Drew (2026-10-10).
- NEW reports from Drew (2026-10-10, same Fedora 44 / GNOME Shell 50.5 / Wayland+XWayland machine, dpr 2): (1) space reservation "not working"; (2) after changing monitor default to display one the strip showed a title bar.
- Reservation evidence: strut IS set and honoured, but too small. Strip sits at logical y=32 (below GNOME top bar) = 64..174 px; `_reserveLinuxStrut` sends height = collapsedHeight*dpr = 110, measured from the screen top, so _NET_WORKAREA starts at 110 and maximized windows overlap the strip by 64 px. Live test: setting strut top=174 via xprop moved _NET_WORKAREA to y=174 (restored to 110 afterwards). Formula unchanged since 2026-05-25 (git log -S) -> not a code regression; it only shows where the strip is not at screen y=0.
- Title bar: NOT reproduced. Live window is DOCK, _MOTIF_WM_HINTS decorations=0, no _GTK_FRAME_EXTENTS. No runner/window code changed this session except base_window_interaction_strategy.dart (send-to-back).
- Session-wide window-code diff vs HEAD: only base_window_interaction_strategy.dart + its test. pubspec pins equal the committed lock versions.

- Drew confirmed (2026-10-10): no other machine had a top bar above the strip -> strut bug is real, env-exposed.
- Reservation fix applied: linux_window_service.dart — strut = (baseTop + collapsedHeight) * dpr where baseTop = active display work-area top EXCLUDING our own strut. `_baseTop()` detects our strut in a refreshed probe (round(top*dpr) == _lastStrutPx) and returns the remembered base, so the strip does not walk down. applyReservation in reserved mode now returns Offset(dx, baseTop) for shown AND hidden (mirrors the Windows service). 2 new tests. test/core/window 97/97 green, analyze clean.
- Known adjacent hazard NOT touched: persisted_display_choice matches a saved display by workAreaOrigin.dy; a refreshed probe that includes our strut changes that value (32 -> 87), so the saved choice may stop matching. Possibly related to Drew's display-change/title-bar report. Needs Morpheus.

- Cleanup (2026-10-10, Drew: "no backward compat, just clean it up"): Linux X11 logic moved out of BaseWindowInteractionStrategy into NEW LinuxWindowInteractionStrategy (extends Reserved; ProcessRunner injected via constructor). Base is plain setAlwaysOnTop/blur again, no dart:io. python3 XLowerWindow helper REMOVED (BELOW alone lowered in the watched test). Factory + LinuxWindowService return the Linux strategy. xdotool failures now log at warning. setup.sh no longer checks python3. DEC-011, ARCH.md, LESSONS.md updated to match. test/core/window 98/98, analyze clean.

- Drew (2026-10-10): reservation fix CONFIRMED working in app. Send-to-back after refactor not yet re-checked.
- New report: hide/show now looks like two steps, a "gray" band is revealed then goes away. NOT verified visually (Neo cannot see the screen). Code facts: _hideStrip sets _isHidden (build switches to the mini pill inside the still full-width transparent window), awaits the 300ms _hideAnim, THEN stripController.hide() shrinks the window and releases the strut. That order is committed code, unchanged this session (timeline_strip.dart, strip_controller.dart, window_service.dart identical to HEAD; an accidental dart-format whitespace change to window_service.dart was reverted).
- Hypothesis: with the reservation now correct the whole band behind the strip is empty desktop, so for ~300ms the wallpaper shows through, then maximized windows slide up when the strut is released. Before the fix windows overlapped the lower 32px of the strip on this machine.
- Do NOT reorder hide/show without Drew: sequence is shared with macOS/Windows and documented in LESSONS (hide pattern, AppBar ordering).

- Drew confirmed hide/show diagnosis (gray band = empty reserved area, vanishes when windows slide up).
- Normal windows CANNOT overlap the strip in reserved mode on GNOME (test GTK window at y=40/80 was forced to y=174), so send-to-back cannot be eyeballed with a test window. Verified by watching _NET_WM_STATE instead.
- SEND-TO-BACK STILL BROKEN IN APP (2026-10-10 00:18 watch): pressing the button removes ABOVE but BELOW never appears on the strip; no warnings in debug.log (xdotool exit 0). Cause: `xdotool getactivewindow` does not reliably return the strip. Under Wayland+XWayland the X11 active window was 4194307 (no WM_CLASS/name/pid - not ours), so BELOW is set on the wrong window. It matched the strip in the 23:45 log only because the strip happened to be the active X11 window then.
- Found: window_manager 0.5.2 has `setAlwaysOnBottom(bool)` (linux, windows) -> gtk_window_set_keep_below on our own GtkWindow = the same _NET_WM_STATE_BELOW, no window id, no xdotool. NOT applied: DEC-011 says no native lower without Drew.

## Current Task
Send-to-back: BLOCKED on Drew's choice of fix (window id lookup is wrong). Strut fix confirmed. Hide/show two-step confirmed as diagnosed, fix not started.

## Next Steps
- Drew to choose: (B, recommended) replace xdotool with windowManager.setAlwaysOnBottom(true/false) in LinuxWindowInteractionStrategy, drop xdotool dependency, amend DEC-011; or (A) keep xdotool and find our own window by pid (`xdotool search --pid`, pick the DOCK one).
- Then hide/show: release strut + shrink at the START of hide (Linux-only if possible), mirror on show - needs Drew OK.
- Then @Trin *qa uat; @Morpheus *lead review.
- Still open: title bar after display change (not reproduced); xdotool in Flatpak/snap (moot if B); F-33 A1; Impeller macOS UAT; golden platform decision.
