# Current Task — 2026-07-01

**Status:** macOS ASWebAuthenticationSession compliance item — fast-tracked sprint plan IN PROGRESS (handed to Cypher)

## Final review (2026-07-01)
Reviewed Mouse's phase breakdown against the architecture doc — matches: Phase A gates implementation on the
redirect-URI spike (correctly sequenced before any code), Phase B scopes changes to macOS/AuthService only,
Phase C covers AC-6 explicitly. **APPROVED.** Sprint plan is ready but **not started** — this was a `*plan` request,
not `*impl`. Awaiting Drew's go-ahead to kick off Phase A (Neo spike).

## Earlier (2026-07-01)
- Drew relayed Apple review feedback: macOS build must use ASWebAuthenticationSession for OAuth
- Morpheus answered: `flutter_web_auth_2` wraps it natively (pure Dart, no custom Swift); scope to macOS only —
  Win/Linux backend of the same plugin uses an embedded webview (WebView2/webkit2gtk), which Google's OAuth
  endpoint blocks (`disallowed_useragent`). Full writeup: `agents/morpheus.docs/aswebauth_guidance_2026-07-01.md`
- User invoked `*bloop *plan macos flutter_web_auth_2` → fast-tracking per bloop rule #4 (small maintenance item,
  skip full 2-gate sprint chain): Cypher+Morpheus combined doc → single Smith gate → Mouse phases → Morpheus final review
- Handed off to Cypher to write the combined stories+arch doc

## Previous: F-31 Code Review COMPLETE — APPROVED

## What was done (2026-06-11)
- Reviewed all F-31 implementation files (WindowService hooks, Linux/Windows overrides, timeline_strip.dart, tests)
- Review doc: `agents/morpheus.docs/f31_code_review_2026-06-11.md`
- APPROVED: platform hooks symmetric, state machine correct, tests comprehensive
- 6 non-blocking follow-up items (A=countdown duplication, B=CurvedAnimation, C=redundant GD, D-F=trivial)
- Recommend F-32 cleanup task for items A and C

## Next
- Drew to review and decide on F-32 cleanup scope
- Sprint C (docs) may still be pending — Oracle doc pass

---
*Last updated: 2026-06-11*
