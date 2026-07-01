# Morpheus Context — 2026-06-03

## 2026-07-01 — ASWebAuthenticationSession guidance (Apple review feedback)
Drew asked whether OAuth needs ASWebAuthenticationSession + custom Swift for macOS App Store review. Answered: `flutter_web_auth_2` package wraps it natively, pure Dart API, no Swift needed. Recommended macOS-only branch in AuthService (keep existing googleapis_auth PKCE + proxy loopback flow for Windows/Linux, unaffected by App Store). Flagged 2 risks for Neo to spike first: (1) whether Google's OAuth desktop client type accepts a custom-URL-scheme redirect_uri, since loopback is deprecated for iOS/Android client types; (2) an open unresolved ASWebAuthenticationSession bug in the plugin's tracker. Not yet recorded as a DECISIONS.md entry — pending Neo's spike. Full writeup: `agents/morpheus.docs/aswebauth_guidance_2026-07-01.md`.

## 2026-07-01 — *impl loop complete, APPROVED (final review)
Risk (1) resolved without a new spike run — Neo found the answer already proven by this app's own
shipped v0.5.3 code (existing custom-scheme redirect_uri already works with the Desktop client type).
Risk (2) (the plugin bug) remains genuinely unresolved/unconfirmed — correctly left as a flagged gap,
not guessed at. Reviewed Neo's implementation + Trin's UAT, approved with no changes requested. Full
review: `docs/sprints/macos-aswebauth-oauth/morpheus_final_review_2026-07-01.md`. Still pending: Oracle
DECISIONS.md entry (my own suggested follow-up, not yet executed — Drew hasn't reviewed/committed yet).

## Current State
- F-31 Timestrip Hide/Show architecture COMPLETE + sprint plan APPROVED. Arch doc: `F31_HIDE_SHOW_ARCH_2026-06-11.md`.
- F-30 Polish & app.dart displayService Fix APPROVED.
- Fixed structural bug in `app.dart` where `displayService` was omitted in the authenticated `TimelineStrip` instantiation.
- Coupling of telemetry resolved: `onWeakMatch` is successfully hoisted and `DisplayService.setPersistedChoice` handles wrapping the choice.
- Caching logic added to DisplayService to resolve display once per refresh, preventing duplicate telemetry events.
- All empty method style warnings in WindowService resolved. Integration tests compile and pass.

## Key Decisions & Architecture

### F-31 Timestrip Hide/Show (2026-06-11)
- State in `_TimelineStripState`: `bool _isHidden`, `bool _preHideSentToBack`, `AnimationController _hideAnim`
- No new controller class — one-shot user action, no debouncing needed
- Animation: Flutter-only width tween within full-size OS window; single `setSize()` call at animation boundary
- Strut/AppBar: released via `onHideStrip()` BEFORE animation; re-acquired via `onShowStrip()` AFTER animation
- Z-order: on hide, save isSentToBack; restore to front + force alwaysOnTop for mini widget; on show, re-apply sendToBack if needed
- Mini width formula: `fontSizePx * 6.0 + 60` (countdown est + padding + button)
- Hide button positioned at `left: 0` (before existing toolbar at `left: 8`)
- 3 phases: A (WindowService hooks), B (Strip UI), C (UAT+Docs)
- Must add `SingleTickerProviderStateMixin` to `_TimelineStripState` for `AnimationController`
- Public wrapper methods added (plan review): `prepareToHide()`, `completeShow()`, `resizeToMiniStrip()`, `resizeToFullStrip()` — arch doc updated


- All branches of structural composition (such as authenticated/unauthenticated state branches in `app.dart`) must consistently wire dependencies to child widgets.
- Hoisting callbacks into ChangeNotifier services is preferred over constructing resolvers inside the UI widgets.
- Caching results of resolver resolution inside display refresh prevent duplicate side-effects.
- Virtual hook methods in WindowService use `return;` inside blocks to comply with linter rules.
