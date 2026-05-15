# Neo Current Task — 2026-05-14

**Status**: Send-to-Back Sprint COMPLETE — all phases done, 266/266 green

## What was completed this session
- Phase C (STB-C1): TFC redesigned (no transparent model), HoverFocusController deleted, timeline_strip.dart cleaned
- Phase F (STB-F1+F2): sendToBack/restoreToFront wired in TFC + button (`Icons.flip_to_back`) in strip
- Phase G/H: Tests written, analyze errors fixed (sprint-introduced only)
- Trin UAT: PASS; Morpheus review: APPROVED; Oracle: docs updated

## Sprint acceptance criteria — ALL MET
1. ✅ Zero passThrough/click_through/setIgnoreMouseEvents/supportsTransparent/WindowMode.transparent in app/lib + app/test
2. ✅ Strategy: Base → MacOs (macOS), Base → Reserved (Linux + Windows)
3. ✅ Send-to-back button on all platforms (Icons.flip_to_back)
4. ✅ setAlwaysOnTop(false)+blur() on sendToBack; setAlwaysOnTop(true) on restore; 10s timer; no focus steal
5. ✅ 266/266 green
6. ✅ PRD updated; docs updated; no click-through as active feature
