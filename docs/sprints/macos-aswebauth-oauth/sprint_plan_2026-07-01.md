# Sprint Plan — macOS ASWebAuthenticationSession — Mouse — 2026-07-01

**Source:** `docs/sprints/macos-aswebauth-oauth/MACOS_ASWEBAUTH_STORIES_ARCH_2026-07-01.md` (Smith Gate APPROVED, AC-6 added)
**Size:** Small — 3 short phases, strictly sequential. Runs parallel to the F-31 Phase C carry-over in `task.md`.

## Phase A — Spike: redirect URI acceptance (Neo)
**Gate:** Answer before writing implementation code — this can change scope.
- Confirm whether the existing Google Cloud OAuth **desktop** client type accepts a custom-URL-scheme
  `redirect_uri` for the macOS `ASWebAuthenticationSession` callback, or whether Google requires registering a
  separate iOS-type client for this to work.
- If a second client registration is required: **stop, escalate to Cypher/Drew** — that's a Cloud Console change
  outside repo scope, not a code task.

## Phase B — Implement macOS branch (Neo)
**Gate:** `make test` green; macOS-only code path; Win/Linux untouched.
- Add `flutter_web_auth_2` dependency (macOS/iOS only usage; no need to touch Win/Linux code paths)
- Branch `AuthService` on `Platform.isMacOS`: use `FlutterWebAuth2.authenticate(url:, callbackUrlScheme:)` for the
  browser-launch + code-capture leg
- Add `CFBundleURLTypes` entry to macOS `Info.plist` for the callback scheme
- Handle `ASWebAuthenticationSessionError` (cancel/dismiss) → route to existing "sign-in cancelled" state (AC-6)
- Token exchange via `make proxy` unchanged

## Phase C — UAT (Trin)
**Gate:** Smith sign-off on AC-6 path; Morpheus final review.
- Happy path: macOS sign-in completes via the system sheet, tokens stored, matches existing behavior
- Cancel path (AC-6): dismiss the system sheet → sign-in-cancelled state, no crash/hang
- Regression: Windows/Linux sign-in flow unaffected (spot-check, not full re-run — no code touched there)
- Check the known open `flutter_web_auth_2` / `ASWebAuthenticationSession` bug report (flagged in Morpheus's
  research) against our exact flow — confirm it doesn't manifest, or document the workaround if it does

---
*Plan by Mouse — 2026-07-01. Fast-tracked per bloop rule #4. Morpheus final review next.*
