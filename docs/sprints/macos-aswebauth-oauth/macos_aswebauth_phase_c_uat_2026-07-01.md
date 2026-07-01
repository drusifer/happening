# Phase C UAT — macOS ASWebAuthenticationSession — Trin — 2026-07-01

**Reviewing:** Neo's Phase A/B work (`agents/neo.docs/current_task.md`, 2026-07-01 section).
**Against:** `docs/sprints/macos-aswebauth-oauth/MACOS_ASWEBAUTH_STORIES_ARCH_2026-07-01.md` AC-1..6,
`sprint_plan_2026-07-01.md` Phase C gate.

## Acceptance Criteria

| AC | Verdict | Evidence |
|----|---------|----------|
| AC-1 (ASWebAuthenticationSession, not url_launcher+HTTP) | **PASS** | `_ASWebAuthRedirectHandler.authenticate` calls `FlutterWebAuth2.authenticate()`, which invokes `ASWebAuthenticationSession` natively on macOS (`FlutterWebAuth2Plugin.swift`). |
| AC-2 (Windows/Linux unchanged) | **PASS** | `_LoopbackRedirectHandler` diff is a pure reshuffle — same `HttpServer` bind + `launchUrl` external-browser flow, just relocated behind the new shared `authenticate()` method. Full suite: 483/485 green, only the 2 pre-existing golden failures (unrelated, already logged in CHAT.md 2026-06-23). |
| AC-3 (token exchange/storage/refresh unchanged) | **PASS** | `auth_service.dart`'s PKCE verifier/challenge, proxy token exchange, `AutoRefreshingAuthClient`, and `TokenStore` paths are untouched — only the redirect-capture call site changed (`launchUrl`+`waitForCallback()` → `authenticate(authUrl)`). |
| AC-4 (no new visible UI) | **PASS** | No widget/UI files touched. |
| AC-5 (passes App Review) | **UNVERIFIED — not testable pre-submission.** Architecturally correct per AC-1; actual App Review outcome is only known after Apple resubmission. |
| AC-6 (cancel/dismiss → sign-in-cancelled, no hang/crash) | **PASS** | `oauth_redirect_handler_test.dart`: `authenticate returns null when the user cancels (AC-6)` — fakes the plugin's platform channel to throw `PlatformException(code: 'CANCELED')` (verified against the actual native Swift source, not just the README, which documents nothing here) and asserts `null`. `auth_service.dart.signIn()` already treats a null callback as "cancelled" → returns `false` → existing sign-in-cancelled UI state. No new exception path introduced. |

## Regression

- Full suite: `flutter test` → 483/485. The 2 failures are `timeline_strip_golden_test.dart` goldens,
  pre-existing per CHAT.md (2026-06-23 Linux window-hide work) — outside this diff's scope (auth-only
  files touched: `auth_service.dart`, `oauth_redirect_handler.dart`, `AppDelegate.swift`, `pubspec.yaml`,
  new `oauth_redirect_handler_test.dart`). Confirmed by `git diff` scope — nothing under
  `lib/features/timeline/` or `test/goldens/` touched.
- `flutter analyze lib/ test/` — clean.
- Real `flutter build macos --debug` succeeds — confirms the SPM-resolved native plugin compiles and
  `GeneratedPluginRegistrant.swift` registers `FlutterWebAuth2Plugin` (and no longer references `AppLinks`,
  consistent with removing the now-unused `app_links` dependency).

## Gaps / Not Coverable By This UAT (flag, not block)

1. **No real system-sheet smoke test.** Everything above is unit-level (fakes the plugin's platform
   channel). Nobody has actually seen the real `ASWebAuthenticationSession` sheet appear and complete a
   real Google sign-in on this build. Recommend Drew do one manual sign-in before the App Store
   resubmission — first real run of this path.
2. **Known upstream bug (Morpheus's research, risk #2): `flutter_web_auth_2` has an open, unresolved
   GitHub issue (#136) — errors on macOS when Chrome is the default browser.** Checked the installed
   version's CHANGELOG (5.0.3) — no fix entry for this issue. Cannot confirm or deny it manifests in our
   exact flow without a real run. If Drew's (or App Review's) Mac has Chrome as default, this is worth
   testing explicitly before submission — not something CI/unit tests can catch.
3. **`cancelSignIn()` is now a no-op on macOS** (Neo flagged this in current_task.md) — our own "tap to
   cancel" affordance on the sign-in strip can't dismiss the native sheet anymore; only the user's own tap
   on the sheet's Cancel button does (which AC-6 covers). This is a real, if minor, UX regression from the
   prior `_AppLinksRedirectHandler` behavior, not a spec violation (AC-6 only requires handling the user's
   own cancel-via-sheet). Smith should weigh in on whether this is acceptable or needs a follow-up.

## Verdict

**Gate → APPROVED for Morpheus's final review**, with gaps 1–3 above carried forward as known
limitations/follow-ups rather than blockers — they're either untestable in this environment (1, 2) or a
pre-existing scope boundary of AC-6 as written (3).
