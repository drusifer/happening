# Morpheus Context — 2026-06-03

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
