# Overlap Diagnosis — Strip Blocking Windows

## Questions

**1. When does the overlap happen?**
- [x] While the strip is collapsed (30px strip)?
- [ ] While expanded (hover card ~250px)?
- [ ] After an expand/collapse cycle (strip returns to 30px but other windows still act clipped)?
- [ ] On app launch before any interaction?
- Notes: It's hard to reproduce on my setup.  If i drag a window towards the timestrip it does that thing where it auto sizes to full screen / half / quarter etc. Most of the time it slides back down below the timestrip after i relase the mouse (THIS IS GOOD!).  It might have to do with 

**2. What is the blocked window doing?**
- [ ] Maximized (Win+Up / double-click titlebar)?
- [ ] Snapped to half-screen (Win+Left/Right)?
- [ ] Manually positioned near the top?
- [ ] Full-screen app (F11 / game)?
- Notes: When it happens it's doing nothing.  The time strip is painted over the top of the other apps window and then you can't access the title bar to move or resize anymore. It might as well be frozen.

**3. Timing — is it immediate or eventual?**
- [ ] Other window was already open when Happening launched
- [ ] Maximized/snapped a window *after* Happening was already running
- [ ] Both
- Notes: I think it is after launch - eventually a window ends up being overlapped but i'm not sure how it happens.  I do observe that when happening starts it "pushes" down the other app windows that might be in the reserved space which is the correct and expected behavior.  I can definately reproduce by switching my DPI settings after launch So we should a least make the app respond to screen changes like that.

**4. Does the blocked window *ever* respect the strip?**
- [ ] Initially leaves space, then creeps up later
- [ ] Never respects the reservation
- [x] Sometimes works, sometimes doesn't (flaky)
- Notes: 

**5. Quick smoke test — maximize Notepad *after* Happening is running in collapsed mode. Does Notepad's title bar sit below the strip, or behind it?**
- Result: PASS - maximizing windows correctly alighs with the bottom of the collapsed strip.

---

## Morpheus Analysis — 2026-04-14

### Confirmed behavior
- AppBar reservation **works on init** — maximized Notepad correctly sits below strip.
- Windows correctly "pushed down" on Happening launch.
- **Flaky**: eventually some window ends up overlapping. Not easily reproducible.
- **DPI change after launch** is a reliable repro trigger.
- **Zoom** launches into reserved space ~25% of the time (screenshot confirms).

### Root cause: stale AppBar registration after system changes

The AppBar rect is registered once in `_registerAppBar()` with physical pixel values
computed from the DPI at launch time. There is **no listener** for:

1. **`WM_DISPLAYCHANGE`** — fires on resolution change, monitor connect/disconnect
2. **`WM_DPICHANGED`** — fires when effective DPI changes (e.g. user changes scaling)
3. **`ABN_POSCHANGED`** — AppBar callback telling us to re-negotiate position
   (we registered `uCallbackMessage` but never handle it)

When any of these happen, the physical-pixel rect in our `_AppBarData` is stale.
Windows silently stops enforcing the work area reservation. Apps that launch after
that point (like Zoom) see the full screen as available and can land on top of the strip.

The Zoom-specific issue (happens even without DPI change) is likely **(C)** — some apps
query work area at their own launch time but position themselves before the
`ABN_POSCHANGED` round-trip completes, or ignore it entirely. This is a known Windows
issue with certain Electron/CEF apps. We can't fix their behavior, but we can mitigate.

### Fix status

| Priority | Fix | Status |
|----------|-----|--------|
| **P0** | Refresh button — `ABM_REMOVE` + `ABM_NEW` + `_reserveCollapsedSpace()` | ✅ SHIPPED |
| **P0** | Display/DPI change — `didChangeMetrics()` in `WindowService`, refresh `_dpr` + `_screenWidth`, re-reserve on Windows | ✅ SHIPPED (2026-04-14) |
| ~~P1~~ | ~~Periodic re-assert timer~~ | ❌ REMOVED — caused window to shrink to 136px on fire |
| **P2** | "Nudge down" — detect overlapping window on hover | NOT in scope |

### Display change approach — 2026-04-14

**Why `didChangeMetrics()`**: Flutter's `WidgetsBindingObserver.didChangeMetrics()` is
platform-neutral. Fires on Windows (DPI change, resolution change, monitor
connect/disconnect), Linux (scale factor change), and macOS (Retina switch). No Win32
message subclassing, no platform channels — the Flutter framework handles detection.

**What it does**: `WindowService` registers itself as a `WidgetsBindingObserver`. On
`didChangeMetrics`, it refreshes `_dpr` and `_screenWidth` from the live display state.
On Windows, it additionally calls `_reserveCollapsedSpace()` to re-assert the AppBar
band with the updated physical-pixel values. Linux and Mac get correct sizing for
expand/collapse after any display change.

### NOT in scope
- `ABN_POSCHANGED` Win32 callback handling (Win32 message subclassing — not needed now)
- Live display switching without restart
- Per-display DPR differences
