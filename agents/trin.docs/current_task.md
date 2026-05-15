# Current Task

## Session 2026-05-14 — Send-to-Back Sprint Phase G/H UAT
**Status**: COMPLETE — UAT PASS
**Progress**: 100%

### Phase H1 Full QA Gate

| Check | Result |
|-------|--------|
| Zero `passThrough` in `app/lib` + `app/test` | ✅ CLEAN |
| Zero `click_through` in `app/lib` + `app/test` | ✅ CLEAN |
| Zero `setIgnoreMouseEvents` in `app/lib` + `app/test` | ✅ CLEAN (removed stale stub + verifyNever) |
| Zero `supportsTransparent` in `app/lib` + `app/test` | ✅ CLEAN |
| Zero `WindowMode.transparent` in `app/lib` + `app/test` | ✅ CLEAN |
| Zero `HoverFocusController` / `hover_focus` | ✅ CLEAN |
| Zero `linuxTransparentSupported` in lib | ✅ CLEAN |
| Zero `isFocusedNotifier` in lib | ✅ CLEAN |
| Strategy hierarchy: Base → MacOs + Reserved | ✅ |
| `sendToBack()` implemented: `setAlwaysOnTop(false)` + `blur()` | ✅ |
| `restoreToFront()` implemented: `setAlwaysOnTop(true)` | ✅ |
| `wm.lower()` not available in window_manager | ⚠️ N/A — using blur() as fallback |
| Button `Icons.flip_to_back` wired to TFC | ✅ |
| 10s auto-restore timer in TFC | ✅ |
| `make test` 266/266 GREEN | ✅ |
| `flutter analyze` — sprint-introduced errors | ✅ CLEAN (only pre-existing) |

### Note on `wm.lower()`
`window_manager` does not expose `lower()`. `sendToBack()` uses `setAlwaysOnTop(false)` + `blur()` instead. Window drops behind newly-focused windows; it doesn't actively push below existing windows. Acceptable behavior for v1.

---
*Last updated: 2026-05-14*
