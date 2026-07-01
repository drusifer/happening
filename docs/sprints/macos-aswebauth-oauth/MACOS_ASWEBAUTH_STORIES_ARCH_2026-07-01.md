# macOS ASWebAuthenticationSession — Stories + Architecture (Fast-Tracked)

**Sprint ID:** macos-aswebauth-oauth
**Authors:** Cypher (PM) / Morpheus (Arch) — combined per bloop fast-track rule (small maintenance item)
**Date:** 2026-07-01
**Status:** Draft — pending Smith gate
**Trigger:** Apple App Review feedback on the macOS submission (v0.5.3) requiring OAuth to use `ASWebAuthenticationSession`

---

## 1. Why (not a new PRD feature)

This is a platform-compliance fix to the existing F-02 (Google Calendar Integration / OAuth 2.0 login), not a new
user-facing feature. No PRD table entry needed — behavior from the user's point of view is unchanged (they still
sign in with Google via a browser-style flow); only the underlying macOS mechanism changes to satisfy Apple review.

## 2. User Story

### US-AUTH-01 — Sign in on macOS passes App Review
> As a macOS user installing "What's Happening?" from the App Store, I want the Google sign-in flow to use Apple's
> standard system authentication UI, so the app passes App Review and I get the same trusted, familiar sign-in
> experience as other Mac apps.

**Acceptance Criteria:**
- AC-1: On macOS, the OAuth browser step is presented via `ASWebAuthenticationSession` (not a raw `url_launcher` +
  local HTTP server flow).
- AC-2: Windows and Linux OAuth flows are unchanged (still system-browser + loopback, per ARCH.md §7) — this AC
  set does not regress either platform.
- AC-3: Sign-in success/failure behavior, token storage, and refresh are unchanged — only how the authorization
  *code* is captured changes.
- AC-4: No new user-visible UI, copy, or settings are introduced. This is invisible plumbing.
- AC-5: macOS build passes Apple App Review's OAuth requirement on resubmission.
- AC-6 (added by Smith Gate, 2026-07-01): If the user cancels/dismisses the `ASWebAuthenticationSession` system
  sheet, the app returns to the sign-in screen and shows the existing "sign-in cancelled, try again" state — no
  unhandled exception, no silent hang. Trin must test this explicitly, not just the happy path.

## 3. Architecture (Morpheus)

**Decision:** Add a macOS-only branch inside `AuthService` (`app/lib/features/auth/auth_service.dart`) using the
[`flutter_web_auth_2`](https://pub.dev/packages/flutter_web_auth_2) plugin, which wraps `ASWebAuthenticationSession`
natively as a pure Dart API — no custom Swift required from us. Windows and Linux keep the existing
`googleapis_auth` PKCE + `make proxy` loopback flow untouched.

**Why not use the plugin on all 3 platforms** (see full research: `agents/morpheus.docs/aswebauth_guidance_2026-07-01.md`):
`flutter_web_auth_2`'s Windows/Linux backend is an *embedded webview* (WebView2 / webkit2gtk via
`desktop_webview_window`), which Google's OAuth endpoint has blocked since 2021/2023
(`disallowed_useragent`). Our current Windows/Linux loopback flow already opens the **system browser**, which is
compliant. Adopting the plugin everywhere would fix nothing on Win/Linux (nothing's broken there) and risk breaking
sign-in outright. So: macOS-only, not a 3-platform migration.

**Mechanism change on macOS only:**
- Code capture: `localhost` HTTP loopback server → `ASWebAuthenticationSession` callback via a custom URL scheme
  (`FlutterWebAuth2.authenticate(url:, callbackUrlScheme:)`).
- Requires: `CFBundleURLTypes` entry in macOS `Info.plist` for the callback scheme (plist config, not code).
- Unaffected: token exchange (code → access/refresh tokens) still goes through `make proxy` (holds `client_secret`),
  unchanged — this step doesn't care how the code was captured.

**Open risks (block implementation, not planning):**
1. **Redirect URI type** — Google's docs mark loopback-IP redirects deprecated for iOS/Android OAuth client types.
   Unclear whether our existing *desktop* OAuth client type in Google Cloud Console accepts a custom-URL-scheme
   `redirect_uri` on macOS, or whether a second (iOS-type) client registration is needed. **Neo must spike this
   before implementation** — if it forces a second Google Cloud OAuth client, that's a scope increase Cypher needs
   to know about.
2. **Known plugin bug** — `flutter_web_auth_2`'s issue tracker has an open, unresolved `ASWebAuthenticationSession`
   bug report as of this research. Check against our exact flow before Trin's UAT sign-off.

## 4. Non-Requirements

- No change to Windows/Linux auth code.
- No change to token storage (`flutter_secure_storage`, unchanged).
- No new settings UI.
- Not bundling a second Google OAuth client unless Neo's spike (Risk 1) proves it's required — if so, escalate to
  Cypher/Drew before proceeding (that would need Cloud Console changes outside repo scope).

---
*Combined doc per bloop fast-track rule #4 — single Smith gate below, see `docs/sprints/macos-aswebauth-oauth/` for gate review once posted.*
