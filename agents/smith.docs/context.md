# Smith Context

## Recent Decisions
- 2026-06-11: F-31 Timestrip Hide/Show Gate 1 APPROVED with 1 must-add AC (Note B: 24×24px target) + 2 non-blocking notes. Review: `agents/smith.docs/f31_gate1_review_2026-06-11.md`
- 2026-04-24: Approved transparent timestrip sprint stories with UX constraints.
- 2026-04-24: Approved transparent timestrip architecture with implementation notes.
- 2026-05-13: Send-to-Back Gate 1 + Gate 2 both approved.
- 2026-05-16: F-28 Linux Reserved Space Gate 1 approved with 3 AC wording amendments.
- 2026-05-18: F-29 Astronomical Timeline Theme Gate 1 approved with 4 non-blocking notes.
- 2026-05-29: F-30 Multi-Monitor Support Gate 1 APPROVED with 1 must-fix note + 4 non-blocking notes. Review: `agents/smith.docs/f30_gate1_review_2026-05-29.md`
- 2026-05-29: F-30 Multi-Monitor Support Gate 2 APPROVED with 3 non-blocking notes. Review: `agents/smith.docs/f30_gate2_review_2026-05-29.md`

## Key Findings

### F-31 Timestrip Hide/Show (2026-06-11)
- Gate 1 APPROVED. Review: `agents/smith.docs/f31_gate1_review_2026-06-11.md`
- Gate 2 APPROVED. Review: `agents/smith.docs/f31_gate2_review_2026-06-11.md`
- Note A: pointer cursor on mini widget (for Neo)
- Note B (applied at Gate 1): AC-F31-1-5 — hide button touch target ≥ 24×24px
- Note C: z-order resolved by Morpheus (D4 — STB save/restore)
- Note D (for Neo): `_buildCountdownPositioned` returns Positioned — extract content helper for mini widget
- Note E (for Neo): Test hide-end snap on Windows — may produce double-animation
- Note F (for Neo): Validate mini width formula vs "23 h 59 min" during Phase B

### F-30 Multi-Monitor (2026-05-29)
- Gate 1 + Gate 2 both APPROVED. Reviews: `f30_gate1_review_2026-05-29.md`, `f30_gate2_review_2026-05-29.md`
- Gate 2 notes (non-blocking): (A) Indicator size = min(14, stripHeight-8)px; (B) Wayland exempt from 2s fallback budget (≤7s on Wayland, matches F-28 posture); (C) Tap on indicator must auto-scroll Settings → Display section into view
- **MUST-FIX**: Fallback indicator must appear on the strip itself (Heuristic #1), not buried in Settings. Strip silently overriding user's display choice = unacceptable UX.
- Note 2: OS-name fallback chain needs explicit "garbage name" rule (empty / generic / duplicate → use "Display N — {res}").
- Note 3: Picker shows only currently-connected displays; persisted-but-unavailable choice shown as separate "Currently set: X — unavailable" row.
- Note 4: Auto-return on reconnect needs a brief visibility cue (toast / fade / border highlight).
- Note 5: "Sharpness" AC must be testable — tie to OS DPI scale factor.

### F-29 Astronomical Theme (2026-05-18)
- Gate 1 approved. Review: `agents/smith.docs/f29_gate1_review_2026-05-18.md`
- Note 1: Sunrise icon must sit at actual sunrise time, not civil twilight begin. Gradient starts at civil twilight begin; icons mark solar events.
- Note 2: Raw lat/lng manual entry is too technical. City name search should be the primary manual fallback.
- Note 3: Rising vs. setting moon icon — use directional arrow cue, not just dimming opacity.
- Note 4: Moon phase badge must not reduce settings gear tap target. Sit left of gear, 8px min separation.

### Send-to-Back (2026-05-13)
- Timer: 10s not 7s. Restore must NOT steal focus. Icon: flip_to_back.
- Full reviews in smith.docs/ send_to_back_gate1/gate2.

### Earlier decisions
- Transparent pass-through: DROPPED. Settings labels = outcome language, not platform terms.
- Idle transparent passes clicks; Focused has clear visual state + Escape dismissal.
- Linux transparent hidden unless proven in real session.

## Important Notes
- Settings labels must always describe user outcomes, not platform implementation terms.
- Any badge or decorative element near settings gear must not reduce gear tap target.
- Moon icons at strip height (~28–36px) need directional cues (arrows) not just color/opacity shifts.

---
*Last updated: 2026-05-29*
