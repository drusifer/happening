# Trin Next Steps — 2026-07-21

## Lunar transition + Make lint workstreams CLOSED
QA approved. Focused 26/26, composite lint clean, full suite 507 passed / 5 skipped. No rerun or
follow-up is owed unless the project files change again. Ready for user review/commit.

---

## Lint-gate repair pending from Neo
On handback, inspect the Makefile diff, run composite `make lint`, then run the full test suite once.
The lunar focused suite already passed 26/26; lint-metrics and lint-format already passed and must
not be run separately again unless code changes touch their scope.

---

## Lunar transition matrix RED — waiting for Neo implementation
Resume by reviewing Neo's compositor change, then run the focused astronomical background test.
Do not alter the 12-row expected-color matrix to accommodate implementation behavior. If focused
tests pass, run format/analyze and one full regression suite because product code will have changed.

---

## Lunar-day sunset diagnosis DONE — awaiting user decision on implementation
No QA work remains for the diagnosis. If asked to fix, Neo should first restore an independent
regression test for a moon that rose before sunset and remains up after civil twilight, asserting
that the merged gradient transitions to `LunarBody.upColor` without reaching `nightNavy`. Trin
then verifies only the touched gradient tests and relevant quality gates.

---

# Trin Next Steps — 2026-07-08 (prior)

## Astro Background Luminance-Merge Fix UAT DONE — no follow-up owed by Trin
Gate approved, suite 494/494 green (see current_task.md / AstroBackground_UAT_2026-07-08.md).
If a cold start resumes here: there is nothing pending — this was a closed-loop QA pass in the
same session as the fix, not a handoff to another persona. If Drew wants a Morpheus architecture
review of the ramp()/mergeByBrightness design before committing, that would be a new request, not
implied by this UAT.

---

# Trin Next Steps — 2026-07-01 (prior)

## macOS ASWebAuth Phase C UAT DONE — Awaiting Morpheus review (parallel track)
Gate approved with 3 flagged, non-blocking gaps (see current_task.md / the UAT report). If Morpheus's
review finds real issues → Neo fixes → Trin re-UAT just the failing item. If Smith wants to weigh in
on the `cancelSignIn()` no-op gap, that's a separate follow-up, not a re-open of this UAT.

---

# Trin Next Steps — 2026-06-11 (F-31, prior)

## F-31 UAT DONE — Awaiting Morpheus review

UAT is complete. All quality gates passed:
- `make lint` PASS (exit 0)
- `make test` PASS (449/449)
- Handoff posted to Morpheus

If Morpheus review finds issues → Neo fixes → Trin re-UAT the failing items only.

## Files changed in F-31 (for Morpheus review scope)
- `app/lib/core/window/window_service.dart` — public hide/show API + protected hooks
- `app/lib/core/window/linux_window_service.dart` — onHideStrip/onShowStrip overrides
- `app/lib/core/window/windows_window_service.dart` — onHideStrip/onShowStrip overrides
- `app/lib/features/timeline/timeline_strip.dart` — state machine + UI
- `app/test/core/window/window_service_test.dart` — F-31 A tests (12 new)
- `app/test/features/timeline/timeline_strip_hide_test.dart` — NEW, 10 tests
- `app/test/goldens/goldens/hover_card_alignment.png` — updated golden
