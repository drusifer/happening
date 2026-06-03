# Morpheus Context — 2026-06-03

## Current State
- F-30 Polish & app.dart displayService Fix APPROVED.
- Fixed structural bug in `app.dart` where `displayService` was omitted in the authenticated `TimelineStrip` instantiation.
- Coupling of telemetry resolved: `onWeakMatch` is successfully hoisted and `DisplayService.setPersistedChoice` handles wrapping the choice.
- Caching logic added to DisplayService to resolve display once per refresh, preventing duplicate telemetry events.
- All empty method style warnings in WindowService resolved. Integration tests compile and pass.

## Key Decisions & Architecture
- All branches of structural composition (such as authenticated/unauthenticated state branches in `app.dart`) must consistently wire dependencies to child widgets.
- Hoisting callbacks into ChangeNotifier services is preferred over constructing resolvers inside the UI widgets.
- Caching results of resolver resolution inside display refresh prevent duplicate side-effects.
- Virtual hook methods in WindowService use `return;` inside blocks to comply with linter rules.
