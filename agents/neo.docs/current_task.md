# Current Task

## Sprint 2 — COMPLETE ✅
**Status**: All tasks done. App running end-to-end on Linux desktop.

### Done
- [x] S2-03 AuthService (abstract interface)
- [x] S2-04 TokenStore (abstract interface)
- [x] S2-05 CalendarService + GoogleCalendarService
- [x] S2-06 EventRepository (cache + dedup)
- [x] S2-07 Wire EventRepository into HappeningApp
- [x] S2-08 5-min Timer.periodic polling
- [x] S2-09 _SignInStrip auth gate
- [x] OAuth working: clientViaUserConsent loopback flow
- [x] Calendar events loading (confirmed empty set today = correct)
- [x] Window height fixed (logical pixels, not physical)

### Auth flow (final)
1. App starts → `_AuthState.unauthenticated` → `_SignInStrip` shown
2. User taps → `_loadClientId()` reads `assets/client_secret.json`
3. `clientViaUserConsent()` starts loopback server, opens browser
4. User completes Google OAuth → code captured → tokens exchanged
5. `_startCalendar(client)` → `EventRepository` → fetch events → `_AuthState.authenticated`
6. `TimelineStrip` displayed, 5-min poll timer started

### Removed (breaking changes worked around)
- `google_sign_in` — no Linux desktop implementation
- `extension_google_sign_in_as_googleapis_auth` — transitive removal
- `flutter_secure_storage` — LLVM 20 json.hpp incompatibility
- `FlutterSecureTokenStore` class
- `GoogleAuthService` class
