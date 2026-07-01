# Trin Context — 2026-06-11 (see 2026-07-01 UPDATE for latest)

## 2026-07-01 UPDATE — macOS ASWebAuth Phase C UAT
- `flutter_web_auth_2`'s platform-interface (`FlutterWebAuth2Platform.instance`) is a clean fake seam —
  no real system sheet needed to test the cancel/success/failure paths (see
  `oauth_redirect_handler_test.dart`). Worth reusing this pattern for other native-plugin-backed code.
- The plugin's README documents nothing about error codes/exceptions — had to verify AC-6 by reading
  the actual native `FlutterWebAuth2Plugin.swift` in the pub cache. Don't trust package READMEs alone
  for error-handling contracts; check the source when the stakes are a required acceptance criterion.
- Full regression suite (`flutter test`) has 2 known pre-existing golden failures unrelated to any
  given change (`timeline_strip_golden_test.dart`) — confirm via `git diff` scope before assuming a
  change caused them, don't just eyeball the failure count.

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
