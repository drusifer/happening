# Trin Context — 2026-06-11 (see 2026-07-08 UPDATE for latest)

## 2026-07-08 UPDATE — Astro Background Luminance-Merge Fix UAT
- Full report: `trin.docs/AstroBackground_UAT_2026-07-08.md`. Gate APPROVED.
- `make lint`'s `lint-metrics` step still fails project-wide on a pre-existing empty-block in
  `oauth_redirect_handler.dart:79` (from commit 9186dfa, macOS ASWebAuth) — NOT this fix. When
  `make lint` fails, always scope-check with `git log -- <file>` before assuming a new change
  caused it; run the scoped `dart_code_linter:metrics analyze <files>` command directly against
  just the touched files to verify them in isolation.
- `dart format --set-exit-if-changed` catches formatting drift `make lint`'s composite target
  won't reach if an earlier step (`lint-metrics`) already failed and short-circuited the chain —
  check format independently, don't assume lint-format ran just because `make lint` was invoked.
- `via -mg <file> -tf -tm --stale --lang dart` (scoped to one file at a time — glob doesn't support
  OR across multiple patterns) is now a fast way to confirm a specific change didn't introduce a
  coverage gap, without wading through the ~655 pre-existing project-wide stale hits.
- The 1 pre-existing golden flake (`timeline_strip_golden_test.dart` S4-31) mentioned in the
  2026-07-01 note below is now RESOLVED — Drew authorized `flutter test --update-goldens
  test/goldens/`, only `hover_card_alignment.png` changed, suite is 494/494 green as of this UAT.

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
