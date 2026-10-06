# Next Steps — 2026-10-02

## F-33 Countdown Swing — QUEUED for *bloop plan (not started)
Drew's request (verbatim intent): in the last ~10s before a meeting, while the
countdown is big + shaking + color-changing, make it swing back and forth across
the WHOLE strip width to grab attention. Fast. Stops once the meeting starts.
If the mouse is over the strip, stop and return to its regular position.
- Tier: likely Tier 2 (UI polish on existing F-32-era countdown phase).
- Open questions to raise when picked up:
  - OQ-F33-1: Resume swinging when mouse leaves the strip before T=0?
  - OQ-F33-2: Mini/hidden (F-31) mode — swing within the pill or not at all?
  - OQ-F33-3: Respect a reduce-motion setting / tie to audio tap-to-mute?
  - OQ-F33-4: Expanded state (hover card) — mouse-over already stops it, confirm.
- Next: `@Cypher *pm` stories+arch with Morpheus → `@Smith *user review` → `@Mouse *sm plan`.

# Next Steps — 2026-07-01

## macOS ASWebAuth compliance sprint (fast-tracked, *bloop *plan)
1. ✓ Combined Cypher+Morpheus doc written: `docs/sprints/macos-aswebauth-oauth/MACOS_ASWEBAUTH_STORIES_ARCH_2026-07-01.md`
2. NOW: `@Smith *user review` — single gate (fast-track skips the 2nd gate since arch is already in the same doc)
3. Smith approve → `@Mouse *sm plan` phase breakdown
4. `@Morpheus *lead review sprint plan` — final review, then report to Drew

## F-31 sprint planning loop (*bloop plan) — DONE, shipped 2026-06

1. ✓ Cypher stories written (5 stories, 3 OQs raised)
2. **NOW: Drew answers OQ-F31-1..3** (see current_task.md)
3. Cypher bakes OQ answers into AC (especially US-F31-5 conditional on OQ-F31-2)
4. `@Smith *user review agents/cypher.docs/f31_timestrip_hide_stories.md` — Gate 1
5. Smith must `*user approve` → proceed to Morpheus
6. `@Morpheus *lead arch F-31` — architecture decisions
7. `@Smith *user feedback <arch>` — Gate 2
8. `@Mouse *sm plan sprint F-31` — phase breakdown
9. `@Morpheus *lead review sprint plan` — final review

## Other parallel work
- F-28 Phase C: `@Trin *qa test F-28` → `@Morpheus *lead review F-28`
- F-29 Oracle doc pass (AST-E2) — low priority

---
*Last updated: 2026-06-09*
