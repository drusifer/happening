# Next Steps — 2026-07-01 (updated)

## macOS ASWebAuth compliance sprint — IMPLEMENTED + REVIEWED, awaiting Drew's commit
`*bloop impl` ran the full Neo→Trin→Morpheus chain. APPROVED, no changes requested. Nothing further
for this team to do until Drew reviews the diff — then optionally `@Oracle *ora record decision`.

---

## PRIOR (2026-07-01, planning phase) — superseded by the above

## macOS ASWebAuth compliance sprint — PLANNING COMPLETE, awaiting go-ahead
- Full fast-track loop done: Cypher+Morpheus doc → Smith gate (APPROVED + AC-6) → Mouse phases → Morpheus review (APPROVED)
- Plan: `docs/sprints/macos-aswebauth-oauth/sprint_plan_2026-07-01.md`
- **Not started.** Next action is Drew's call: `*bloop *impl macos-aswebauth phase-a` (or `@Neo *swe impl phase-a`)
  to kick off the Phase A spike (Google redirect URI client-type question) whenever ready.

## F-31 — IMPL LOOP COMPLETE
- Neo Phase A+B ✅, Trin UAT ✅, Morpheus review APPROVED ✅
- Follow-up: F-32 cleanup task for countdown duplication (item A) + redundant GD (item C)
- Sprint Phase C (docs): Oracle doc pass still needed

## F-28 Phase C (still pending)
- `@Trin *qa test F-28` — UAT against AC-L1..L3
- `@Morpheus *lead review F-28` — C++ memory safety + WindowService serialisation

## F-30
- C3/F1/F2: hardware-blocked on Drew's machine
- F3 docs: Oracle can do post-hardware-verify
