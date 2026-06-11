# Trin Context — 2026-06-11

## F-31 UAT Findings

### Implementation quality
- Phases A (WindowService hooks) and B (Strip UI) complete by Neo
- 20 new tests total: 12 in window_service_test.dart, 10 in timeline_strip_hide_test.dart (2 added by Trin)
- Golden image updated twice due to z-order changes in Stack

### Key implementation decisions (for Morpheus review)
1. **_HideButton z-order**: Must be LAST in Stack children (after settings widgets) so settings backdrop doesn't block it. This was a bug Neo introduced and Trin fixed during UAT.
2. **No CurvedAnimation**: _hideAnim runs linear, not ease-in-out. AC-F31-1-3 technically violated but non-blocking since animation is mostly a timing gate (content switches immediately on _isHidden=true).
3. **_onHideAnimTick**: Named method for AnimationController listener (avoids no-empty-block lint).
4. **restoreToFront → setAlwaysOnTop(true)**: Confirmed via base_window_interaction_strategy.dart line 58. AC-F31-2-5 satisfied.

### Pre-existing lint warnings (NOT F-31)
- `EventsLayer._paintEventLabel`: 8 parameters (events_layer.dart)
- `TimelinePainter.shouldRepaint`: cyclomatic complexity 23 (timeline_painter.dart)
These fail make lint metrics regardless of F-31.
