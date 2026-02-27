# Neo Context

## Project: Happening (Flutter Desktop)
**Last active**: 2026-02-27 — Sprint 2 COMPLETE, app running end-to-end

## Sprint 2 Services (all tested, 71/71 GREEN)
| File | Class | Notes |
|---|---|---|
| `lib/features/auth/token_store.dart` | `TokenStore` (abstract only) | FlutterSecureTokenStore REMOVED — json.hpp/LLVM 20 incompatibility |
| `lib/features/auth/auth_service.dart` | `AuthService` (abstract only) | GoogleAuthService REMOVED — google_sign_in has no Linux impl |
| `lib/features/calendar/calendar_service.dart` | `CalendarService` (abstract) / `GoogleCalendarService` | Filters all-day (start.dateTime == null); static fromApiEvent() |
| `lib/features/calendar/event_repository.dart` | `EventRepository` | Cache (5min TTL) + dedup by id + invalidate() |

## Key Contracts
- **CalendarService.fromApiEvent** is static — testable without mocks
- **All-day filter**: `e.start?.dateTime != null` — all-day events have only `start.date`
- **EventRepository** deduplication: `Set<String>` on event.id, first occurrence wins
- **Cache TTL**: 5 minutes (`_maxAge = Duration(minutes: 5)`)

## Auth Architecture (FINAL — googleapis_auth loopback)
- `app.dart` loads `assets/client_secret.json` (gitignored, Drew's credentials)
- `clientViaUserConsent()` from `googleapis_auth` opens browser → loopback HTTP server → captures auth code
- `url_launcher` opens the browser via `launchUrl(..., mode: LaunchMode.externalApplication)`
- No token persistence (no silent restore) — user re-auths each launch until S3-token

## Linux Build Lessons (see oracle.docs/LESSONS.md for full details)
- **Never use Flutter snap** — LLVM 10 PATH hijacking, no linker
- **Never use google_sign_in on Linux** — no platform implementation
- **Never add flutter_secure_storage** until upstream fixes LLVM 20 json.hpp compat
- **window_manager on Linux takes logical pixels** — do NOT divide by DPR; GTK handles scaling

## Window Height
- `logicalHeight = _kStripHeightLogical` (30.0) — NOT `30.0 / dpr`
- DPR division was a snap-Flutter workaround; non-snap Flutter + GTK handles DPI correctly

## Dependencies (pubspec.yaml — final Sprint 2 state)
- `window_manager: ^0.3.8`
- `screen_retriever: ^0.1.9`
- `googleapis: ^13.2.0`
- `googleapis_auth: ^2.0.0`
- `url_launcher: ^6.2.0`
- Assets: `assets/client_secret.json`

## Project Layout
```
happening/
  Makefile                  — setup/test/build/run
  app/
    lib/
      features/
        auth/
          token_store.dart   (abstract only)
          auth_service.dart  (abstract only)
        calendar/
          calendar_service.dart
          event_repository.dart
          calendar_event.dart
          video_link_extractor.dart
        timeline/
          timeline_strip.dart
          ...
    assets/
      client_secret.json    (gitignored — Drew's OAuth credentials)
    test/                   — 71 tests, all GREEN
```

## Test Status
- 71/71 GREEN (Sprint 1: 44, Sprint 2 TDD: 27 new)

## Sprint Status
- Sprint 1: COMPLETE ✅
- Sprint 2: COMPLETE ✅ — app runs, OAuth works, calendar events load
- Sprint 3: READY TO START
