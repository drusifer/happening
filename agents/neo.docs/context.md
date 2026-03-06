# Neo Context

## PKCE Auth Migration — 2026-03-06
- Replaced `clientViaUserConsent()` (needs secret) with manual PKCE flow in `GoogleAuthService.signIn()`
- PKCE helpers: `_generateVerifier()` (32 random bytes, base64url) + `_sha256Challenge()` (SHA256, base64url)
- Local `HttpServer.bind('localhost', 0)` captures auth code redirect
- Token exchange POSTs to `https://oauth2.googleapis.com/token` with `code_verifier` — no secret
- `autoRefreshingClient` kept for `tryRestore()` — refresh works with empty secret for Desktop app type
- `assets/client_secret.json` deleted; `_kGoogleClientId` hardcoded in `app.dart`
- `crypto: ^3.0.0` added to pubspec; asset entry removed
- 185/185 tests GREEN


## Sprint 5: Refinement — 2026-03-02
- Implemented `ExpansionLogic` (pure logic) in `app/lib/features/timeline/expansion_logic.dart`.
- TDD complete: `app/test/features/timeline/expansion_logic_test.dart` passes with 9 tests.
- Logic covers: Settings overrides, Interaction Zone (dy >= stripHeight), Hit Zone (event bounds), and Default (collapsed).
