# Current Task — 2026-05-14

**Status**: Code Review COMPLETE — APPROVED

## Send-to-Back Sprint — Full Review

### Review Verdict: APPROVED

All Phase B, C, E, F changes reviewed and approved.

### Architecture checklist

| Check | Result |
|-------|--------|
| `setPassThrough`/`setFocused` gone from interface | ✅ |
| `BaseWindowInteractionStrategy` created | ✅ |
| `MacOs` + `Reserved` extend base | ✅ |
| `supportsTransparent` removed from `WindowModeAvailability` | ✅ |
| Factory routes Linux+Windows → Reserved | ✅ |
| `setPassThroughEnabled` removed from WindowService | ✅ |
| `sendToBack`/`restoreToFront` in interface + service | ✅ |
| `sendToBack` impl: `setAlwaysOnTop(false)` + `blur()` | ✅ |
| `restoreToFront` impl: `setAlwaysOnTop(true)` | ✅ |
| `HoverFocusController` deleted | ✅ |
| TFC redesigned: `isSentToBack`, `isSentToBackNotifier`, 10s timer | ✅ |
| Button `Icons.flip_to_back` with active state | ✅ |
| Listener removed before `_focusController.dispose()` | ✅ |
| `_onSentToBackChanged` guards `mounted` | ✅ |
| 266/266 tests green | ✅ |

### Notes
- `wm.lower()` not in window_manager API — `blur()` fallback acceptable for v1
- `_syncWindowBehavior` always calls `setWindowMode` even on init — harmless (WindowService guards idempotently)

---
*Last updated: 2026-05-14*
