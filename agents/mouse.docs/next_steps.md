# Next Steps — Send-to-Back Sprint

- [x] Phase board written in `task.md` — 8 phases (A–H), 15 tasks.
- [ ] Morpheus review and approve phase plan → `@Morpheus *lead review sprint plan`.
- [ ] Neo: Phase A (STB-A1 doc cleanup, STB-A2 WindowMode rename).
- [ ] Trin: verify Phase A → Morpheus approve.
- [ ] Neo: Phase B (STB-B1 strategy hierarchy, STB-B2 WindowService purge).
- [ ] Trin: verify Phase B → Morpheus approve.
- [ ] Neo: Phase C (STB-C1 TFC redesign + HoverFocusController delete).
- [ ] Trin: Phase D green gate (STB-D1 — hard stop before Phase E).
- [ ] Neo: Phase E (STB-E1 sendToBack in strategy+service).
- [ ] Neo: Phase F (STB-F1 TFC wire, STB-F2 button wire).
- [ ] Trin: Phase G tests (STB-G1).
- [ ] Trin + Oracle: Phase H close (STB-H1 QA, STB-H2 docs).

## Key Risks to Watch
- STB-E1: `wm.lower()` Linux availability — Neo must verify before closing task.
- STB-D1: Hard green gate — Phase E does NOT start until all tests pass.
