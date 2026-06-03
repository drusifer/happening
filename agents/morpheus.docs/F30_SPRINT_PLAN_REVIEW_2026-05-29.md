# F-30 Sprint Plan Review — Morpheus
*Morpheus — 2026-05-29*

## Verdict: APPROVED — sprint ready to start with Phase A

Mouse's plan in `task.md` and `agents/mouse.docs/f30_sprint_plan_2026-05-29.md` is faithful
to the F-30 architecture. Phase boundaries align with component boundaries in the arch doc;
dependency graph (A → {B, C, E}; B → D; {C, D, E} → F) is correct and enables Neo to
pipeline C/D/E once A+B land — which is the right call for sprint velocity.

Three observations, none of which block the sprint:

---

### Observation 1 — F30-A2-probe is the right shape (Approval)

The Wayland event-coverage probe being folded into F30-A2 (rather than as a separate task)
is correct because: (a) the probe requires the DisplayService to be wired enough to log
events, so it can't precede A2, and (b) its result only matters at Phase C wiring time
(switch to polling vs. event-driven). Keeping it inside A2 with a defined output ("flag for
polling fallback in Phase C") is well scoped.

### Observation 2 — F30-C3 BLOCKING flag is correct (Approval)

Mouse correctly identified that Windows AppBar verification on a secondary monitor is a
*real* unknown that could force the ABM_REMOVE + ABM_NEW fallback path. Marking F30-C3 as
BLOCKING the rest of Phase C is the right risk treatment. If C3 fails, C1's Windows
implementation needs a second iteration before C2 can land cleanly.

### Observation 3 — Phase F1 / F2 parallelism is acceptable as written (Approval)

F30-F1 (Trin multi-platform UAT) and F30-F2 (Smith UX pass) can begin in parallel for some
checks (Smith's indicator-legibility test only needs Linux build; Trin's matrix is
multi-platform). Mouse's serial listing is fine — no need to refactor. Neo + QA can
coordinate timing live.

---

## Architecture Coverage Check

| Arch component | Plan task | Verdict |
|----------------|-----------|---------|
| `DisplayInfo` + `labelFor` | F30-A1 | ✓ |
| `DisplayService` + state machine | F30-A2 (+ probe) | ✓ |
| `PersistedDisplayChoice` + fingerprint match | F30-B1, F30-B2 | ✓ |
| `WindowResizeStrategy.moveToDisplay` (3 platforms) | F30-C1 | ✓ |
| WindowService rewiring + race guard | F30-C2 | ✓ |
| Windows AppBar verification | F30-C3 | ✓ (BLOCKING flag is correct) |
| SettingsPanel Display section | F30-D1 | ✓ |
| "Currently set: X — unavailable" row | F30-D2 | ✓ |
| `DisplayFallbackIndicator` + deep-link + auto-scroll | F30-E1 | ✓ (includes Smith Notes A + C) |
| Fade + slide animation | F30-E2 | ✓ (matches Smith Note 4 design) |
| UAT matrix | F30-F1 | ✓ (Wayland ≤7s correctly tracked) |
| Smith UX pass | F30-F2 | ✓ |
| Docs + PRD update | F30-F3 | ✓ |

No arch component is unrepresented in the plan. No plan task lacks architectural backing.

---

## Sprint Start Recommendation

Neo can begin **F30-A1** immediately. F30-A1 has zero dependencies (pure value object +
unit tests) and is the shortest path to a green light. Once A1 lands, A2 unblocks B, C, E
in parallel.

Mouse: F-28 Phase C parallel-track is correctly preserved in task.md. Trin should pull
F-28 Phase C while Neo is in A1/A2, freeing Trin's bandwidth for F30-C3 verification when
Phase C reaches it.

---

*Sprint plan APPROVED by Morpheus — 2026-05-29. Loop `*plan sprint F-30` complete.*
