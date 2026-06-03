# Current Task — 2026-05-29 17:13

**Status:** F-30 stories READY — Smith Gate 1 APPROVED, AC updated, handing off to Morpheus arch

## What was done (2026-05-29)
- Wrote 4 stories, added F-30 to PRD V2 table
- Drew answered OQ-1..4 → baked into AC
- Smith Gate 1 review (APPROVED w/ 1 must-fix + 4 non-blocking notes)
- Updated AC per Smith Notes:
  - **Note 1 (MUST-FIX)**: AC-F30-3-2 rewritten — fallback indicator MUST appear on strip
    itself; Settings cannot be the only surface
  - Note 2: AC-F30-1-2 rewritten — explicit OS-name fallback chain (non-empty, non-generic,
    unique → OS name; else "Display N — {res}"; primary always gets " — primary" suffix)
  - Note 3: AC-F30-1 rewritten — picker shows only connected; persisted-but-unavailable
    choice shown as read-only "Currently set: X — unavailable" row
  - Note 5: AC-F30-2 rewritten — "sharpness" replaced with concrete DPI scale factor test
    (1.0x / 1.25x / 1.5x / 2.0x via Flutter MediaQueryData.devicePixelRatio)
  - Note 4 (auto-return visibility cue): forwarded to Morpheus for design phase (non-blocking)
- Status: DRAFT → READY → SMITH-APPROVED

## Next action (in flight)
- Hand off to `@Morpheus *lead arch F-30` (sprint planning loop step 2)
- Morpheus arch scope: per-display work-area/DPI lookup, strut x-range generalization,
  hot-plug state machine (auto-fallback + auto-return), Windows AppBar move-with-selection
  mechanism, fallback indicator concrete design (per Smith Note 1), auto-return visibility cue
  (per Smith Note 4)
- After Morpheus: Smith Gate 2 review → Mouse sprint plan → Morpheus reviews sprint plan

## Other pending PM work (carried forward)
- F-29 (per memory shipped 2026-05-24 — Cypher state needs reconciliation on next F-29 touch)
- F-28 Phase C (Trin UAT + Morpheus review still pending)
- Stale cypher.docs cleanup (low priority)

---
*Last updated: 2026-05-29 17:13*
