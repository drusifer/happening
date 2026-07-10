# Trin UAT — Astro Background Luminance-Merge Fix — 2026-07-08

## Scope
Reviewed the committed fix (6b09cd9 "Astro Theme fix", authored by Drew) for the reported bug:
astro-theme background painted night/moonlit color during real daylight when the moon was up
across a sunrise/sunset. Root cause and fix design were established collaboratively earlier in
this session (see the Neo-side work); this is independent QA verification.

## Checks Run
1. **`make lint`** — failed at `lint-metrics` on `lib/features/auth/oauth_redirect_handler.dart:79`
   (empty `cancel()` block, STYLE/no-empty-block). Confirmed via `git log` this is **pre-existing**
   from commit `9186dfa` (macOS ASWebAuth), not touched by this fix — out of scope, already known
   (see Trin's 2026-07-01 UAT notes on that feature).
2. **Scoped `dart_code_linter:metrics analyze`** on the 4 touched files (`sky_body.dart`,
   `solar_body.dart`, `lunar_body.dart`, `astronomical_background_layer.dart`) with
   `--fatal-style --fatal-performance --fatal-warnings` — clean, no issues.
3. **`dart format --set-exit-if-changed`** — found 6 of the touched files (3 lib + 3 test) were not
   formatted; applied `dart format` scoped to just those 6 files (left pre-existing unformatted
   files elsewhere in the tree untouched, out of scope). Re-verified clean after.
4. **`via -mg <file> -tf -tm --stale --lang dart`** — zero stale-coverage hits on all 4 touched
   files (tests are current relative to source). Broader project-wide stale count (655) is
   pre-existing and unrelated.
5. **Full suite** (`flutter test --coverage`) — was 493/494 (1 pre-existing golden flake,
   `timeline_strip_golden_test.dart` S4-31 hover-card-follows-mouse-X, confirmed failing
   identically on unmodified `main` via `git stash` before this fix touched anything). Drew
   authorized regenerating it; ran `flutter test --update-goldens test/goldens/`, confirmed only
   the intended `hover_card_alignment.png` changed. **Suite now 494/494 green.**

## Verdict: GATE APPROVED
No regressions, no new lint/format debt, no coverage gaps introduced. The one pre-existing golden
flake is now resolved (regenerated golden committed to working tree, not yet git-committed).

## Uncommitted at handoff
- `app/test/goldens/goldens/hover_card_alignment.png` (regenerated golden)
- 6 reformatted files (3 lib, 3 test) under `app/lib/features/timeline/painters/` and
  `app/test/features/timeline/painters/`
- Untracked `dist/happening-0.5.3+1-linux-arm64.tar.gz` — stray build artifact, not mine, left
  alone (rm was denied by the harness's destructive-action guard; harmless, in `dist/`).
