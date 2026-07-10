# Neo — Pre-existing Lint Fixes + Suppression Audit — 2026-07-08

## Scope
Trin's UAT on the astro background fix surfaced pre-existing lint debt (previously only
partially documented). User asked to fix all of it and audit suppressions for anything worth
re-enabling. Full `make lint` run revealed 6 metric violations (not just the 2-3 previously
known), all fixed via targeted refactors (Fowler: Extract Method, Introduce Parameter Object):

| File | Issue | Fix |
|------|-------|-----|
| `oauth_redirect_handler.dart:79` | empty block (STYLE) | Replaced comment-only body with a real `_log.fine(...)` call documenting the no-op |
| `events_layer.dart` `_paintEventLabel` | 8 params | Introduced `_EventBlockGeometry` (named class, not a raw record — per Drew's preference for typed params) bundling x/w/top/blockHeight |
| `timeline_painter.dart` `shouldRepaint` | cyclomatic complexity 24 | Extract Method into `_timeChanged`/`_eventStateChanged`/`_visualsChanged`/`_astroChanged`; verified all 24 original field comparisons preserved exactly once |
| `timeline_strip.dart` `_handleMouse` | complexity 21 | Extracted `_computeAstroHit` (guard clauses replacing the nested ternary+&&) |
| `timeline_strip.dart` `_buildCountdownContent` | 7 params | Introduced `_CountdownContentSpec` |
| `hover_detail_overlay.dart` `build` | 123 SLOC | Extracted `_buildHeaderRow`, `_buildDescription`, and a `_HoverCardStyle` value object for the style/color computation |

All verified individually via scoped `dart_code_linter:metrics analyze --fatal-*` + existing test
suites before moving to the next file.

## Suppression audit
`analysis_options.yaml` had `unused_element: ignore` (its sibling dead-code rules — unused_field/
unused_local_variable/unused_import/dead_code — are all `error`). Flipped to `error`: zero cost in
`lib/` alone, but scanning `lib test integration_test` (matching `make lint-style`'s actual scope)
surfaced two real, previously-hidden findings:

1. **`ScreenRetriever`/`sr` dead parameter** threaded through `WindowResizeStrategy.create` and all
   three platform strategies (`Linux`/`Windows`/`MacOsResizeStrategy`) — genuinely unused in all
   three (macOS didn't even store it; Linux/Windows stored it behind `// ignore: unused_field`).
   Removed entirely: the factory, all three strategy constructors, the one production call site
   (`window_service.dart`), and the test file that mocked it. `WindowService`'s own
   `screenRetriever`/`_sr` stayed — that one IS used (`_sr.getPrimaryDisplay()` at line ~468); only
   the copy threaded further down into the resize strategies was dead.
2. **`integration_test/timeline_strip_test.dart`** (29 lines) — no `void main()`, never run since
   Sprint 4. Its only class (`_FakeWindowService`) was unused; everything else in the file existed
   only to feed its constructor. Confirmed no other file referenced it. **Deleted with Drew's
   explicit approval** (the harness correctly blocked the first unprompted `rm` attempt — asked via
   AskUserQuestion first).

Other `// ignore_for_file:` directives found are all in auto-generated `*.mocks.dart` (mockito
codegen), already excluded from analysis via `analyzer.exclude` — not genuine suppressions, left
alone.

Considered and declined (per Drew, "not enough juice to justify the squeeze"): retrofitting a
Builder pattern onto high-param-count classes. Surveyed candidates (`TimelinePainter` 27 params,
`CalendarEvent` 13, `TimelineStrip` 12, `EventsLayer` 11) — concluded the widgets/painters are
idiomatically fine as named-constructor value snapshots (rebuilt whole every frame, no staged
construction to benefit from Builder); `CalendarEvent` was the one plausible domain-object
candidate but dropped per Drew's call.

## Verification
- `make lint` — PASS (lint-style + lint-metrics + lint-format all clean; first time all three have
  passed together, per git history showing `unused_element` was suppressed at some unknown past
  point and never revisited).
- `make lint-metrics` standalone — confirmed PASS again on request (includes `check-unused-files`).
- Full suite: **494/494 green**, `flutter test --coverage` exit 0.
- No singletons introduced (Drew's caution, noted for future work too).

## Files touched (beyond the astro fix from earlier today)
- `app/analysis_options.yaml` (unused_element: ignore → error)
- `app/lib/features/auth/oauth_redirect_handler.dart`
- `app/lib/features/timeline/painters/events_layer.dart`
- `app/lib/features/timeline/timeline_painter.dart`
- `app/lib/features/timeline/timeline_strip.dart`
- `app/lib/features/timeline/hover_detail_overlay.dart`
- `app/lib/core/window/resize_strategy/{window,linux,windows,macos}_resize_strategy.dart`
- `app/lib/core/window/window_service.dart`
- `app/test/core/window/window_resize_strategy_test.dart`
- Deleted: `app/integration_test/timeline_strip_test.dart`
- Formatting-only: `app/lib/features/calendar/calendar_event.dart`,
  `app/test/features/auth/oauth_redirect_handler_test.dart`,
  `app/test/goldens/timeline_strip_golden_test.dart` (pre-existing drift, unrelated content)

## Uncommitted at handoff
Everything above sits on top of the earlier `6b09cd9` astro-fix commit, uncommitted. No
persona is blocked; ready for Drew to review/commit whenever convenient.
