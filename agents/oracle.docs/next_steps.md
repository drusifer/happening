# Next Steps

## Immediate handoff — Makefile analyzer scope
1. Trin: verify `make analyze` and `make lint-style` always pass `lib test` and conditionally append
   `integration_test` only if the directory exists.
2. Verify `win-test` uses the same analyzer-root rule so the Windows helper does not drift.
3. If `app/integration_test` is recreated later, confirm it automatically returns to analysis.

## Immediate handoff — lunar-day sunset bug
1. Trin: use `Lunar_Day_Sunset_Expected_Behavior_Summary_2026-07-21T16-55.md` as the evidence-backed
   answer: expected target is lunar `upColor`, and the former exact harness was removed in `6b09cd9`.
2. If a fix is authorized, restore an independent regression assertion for a moon that rose before
   sunset and remains up past civil twilight end; assert the dusk endpoint is lunar `upColor`.
3. Preserve the distinction between solar-only dusk (ends at `nightNavy`) and moon-up dusk (ends at
   illumination-scaled lunar shade).

## Done in the 2026-06-21 groom (pass 1 + 2)
ARCH §6 rewritten + DEC-009 + EXPANSION_CONTROLLER superseded + ARCH v0.8; CHAT.md deduped/archived
(1476→761); WINDOW_* plans → `docs/sprints/window-convergence-2026-06/`; scratch logs removed; 25 en-dash
files renamed; stale memory refreshed → `project_strip_controller.md`. See current_task.md.

## Remaining / lower priority
1. **ARCH.md §8 decision table** — optionally add an AOQ row pointing at DEC-009 (the §6 body is current).
2. **`docs/sprints/window-convergence-2026-06/`** — consider a one-line README (other sprint dirs mostly
   lack one, so optional). The authoritative pointers are ARCH §6 + DEC-009.
3. **CHAT.md still ~761 lines** (2026-06-03→today). The 06-03→06-11 portion (F-31 + early window work) could
   be archived next time it crosses the threshold again; the 06-11→today window-refactor history is still
   active context, keep it live.
4. **`docs/EXPANSION_CONTROLLER.md`** kept with SUPERSEDED banner (history). If Drew prefers, move it under
   `docs/sprints/window-convergence-2026-06/` alongside the other historical window docs.

## Ongoing
- [ ] `*ora archive` when CHAT.md > ~100 msgs again.
- [ ] Record a follow-up decision when the Linux/macOS show/hide convergence lands (deferred per DEC-009).
- [ ] Watch DECISIONS/ARCH consistency as the StripController fold-in settles.
