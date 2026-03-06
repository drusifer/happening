# PKCE Auth Migration Plan

## Goal
Remove `client_secret.json` from the app bundle. Replace `clientViaUserConsent()` (needs secret) with a PKCE flow (no secret needed). Approved by Drew 2026-03-06.

## Client ID (was in client_secret.json)
`732125393297-j5m383u2fdek7j24olmn2vnmjmf49cqn.apps.googleusercontent.com`

## Tasks

### T1 — pubspec.yaml
- Add `crypto: ^3.0.0`
- Remove `assets/client_secret.json` from the assets list

### T2 — auth_service.dart
- Add imports: `dart:io`, `dart:math`, `package:crypto/crypto.dart`
- Replace `signIn()` body with PKCE flow:
  1. `_generateVerifier()` — 32 random bytes, base64url, strip `=`
  2. `_sha256Challenge(verifier)` — BASE64URL(SHA256(verifier)), strip `=`
  3. `HttpServer.bind('localhost', 0)` — OS picks free port
  4. Build auth URL with: client_id, redirect_uri, code_challenge, code_challenge_method=S256, access_type=offline, prompt=consent
  5. `launchUrl(authUrl, ...)`
  6. `await server.first` — capture redirect request
  7. Extract `code` from query params; send 200 HTML response; close server
  8. POST to `https://oauth2.googleapis.com/token` with code + code_verifier (NO secret)
  9. Parse response → `AccessCredentials`
  10. `autoRefreshingClient(_clientId, creds, _httpClient)` — unchanged
- Remove `clientViaUserConsent` import dependency (keep rest of `auth_io.dart`)
- `tryRestore()`, `signOut()`, `_encode`, `_decode` — NO CHANGES

### T3 — app.dart
- Add const: `const _kGoogleClientId = '732125393297-...'`
- Replace `await _loadClientId()` with `ClientId(_kGoogleClientId, '')`
- Delete `_loadClientId()` method
- Remove now-unused imports: `dart:convert`, `package:flutter/services.dart`

### T4 — auth_service_test.dart
- Change `ClientId('id', 'secret')` → `ClientId('id', '')` in test setUp
- No other test changes needed (signIn is not tested on real GoogleAuthService)

### T5 — Delete assets/client_secret.json
- After implementation verified working, delete the file

## PKCE Flow Diagram
```
App                     Browser              Google
 |                         |                    |
 |--generate verifier+---->|                    |
 |  challenge              |                    |
 |--open auth URL--------->|                    |
 |  (with code_challenge)  |--GET /auth-------->|
 |                         |<--consent page-----|
 |                         |--user approves---->|
 |<--localhost redirect----|<--redirect code----|
 |  (capture code)         |                    |
 |--POST /token (code + verifier, NO secret)--->|
 |<--access_token + refresh_token---------------|
 |  store in TokenStore                         |
```

## Notes
- `autoRefreshingClient` refresh calls work with empty secret for Desktop app type
- Google Cloud Console: confirm client type is "Desktop app" (installed type)
- Existing stored tokens (`~/.config/happening/google_credentials.json`) remain valid
