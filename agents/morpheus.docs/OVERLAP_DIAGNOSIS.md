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

### Proposed fix scope

| Priority | Fix | Effect |
|----------|-----|--------|
| **P0** | Handle `ABN_POSCHANGED` callback — re-call `_reserveCollapsedSpace()` | Re-asserts reservation after any system work-area change |
| **P0** | Listen for `WM_DISPLAYCHANGE` / `WM_DPICHANGED` — update `_dpr`, `_screenWidth`, re-reserve | Fixes the DPI-change repro |
| **P1** | Periodic re-assert (every 30–60s, re-call `ABM_SETPOS`) as a safety net | Catches edge cases where callbacks are missed |
| **P1** | Refresh button re-asserts AppBar — call `ABM_REMOVE` + `ABM_NEW` + `_reserveCollapsedSpace()` | User-triggered escape hatch to recover overlapped windows without restarting |
| **P2** | "Nudge down" — on strip click/hover, if strip detects a window overlapping, bring-to-front + flash | UX mitigation for apps that ignore work area (Zoom etc.) |

### NOT in scope (same as secondary monitor plan)
- Live display switching without restart
- Per-display DPR differences
