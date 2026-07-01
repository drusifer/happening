# Smith Gate Review — macOS ASWebAuthenticationSession — 2026-07-01

**Reviewing:** `docs/sprints/macos-aswebauth-oauth/MACOS_ASWEBAUTH_STORIES_ARCH_2026-07-01.md`
**Gate:** Fast-track single gate (stories + arch combined per bloop rule #4)

## Evaluation

This is backend/platform plumbing with (by AC-4) no new user-visible UI — most Nielsen heuristics don't apply
directly. Two things are worth checking against real user behavior:

1. **System dialog is actually a UX upgrade, not a risk** (Heuristic #1, Visibility of System Status /
   Heuristic #2, Match Real World): `ASWebAuthenticationSession` presents Apple's own trusted system sheet
   ("`happening` wants to use `google.com` to sign in") instead of our current flow bouncing the user out to a
   full browser tab. Users already recognize this pattern from other Mac apps (Sign in with Apple, etc.) — this
   is a net UX improvement, not just a compliance checkbox. Worth noting for the user-facing changelog even
   though AC-4 says no visible UI change is *required* — one is happening anyway, for the better.

2. **Gap: cancel/error path is unspecified.** None of AC-1..5 say what happens if the user dismisses the
   `ASWebAuthenticationSession` system sheet (tap "Cancel", or click away). `ASWebAuthenticationSession` returns
   an `ASWebAuthenticationSessionError.canceledLogin` in that case — if `AuthService` doesn't handle it explicitly,
   this could surface as an unhandled exception or a silent hang instead of returning the user to the existing
   sign-in screen with a clear message (Heuristic #9, Help Users Recognize/Recover from Errors).

## Verdict: **APPROVED with 1 must-add AC**

- **AC-6 (must add):** If the user cancels/dismisses the `ASWebAuthenticationSession` sheet, the app returns to
  the sign-in screen and shows the same "sign-in was cancelled, try again" state used elsewhere in the app —
  no unhandled exception, no silent hang. Trin must test this explicitly in UAT (not just the happy path).

Non-blocking: note the improved system-trust-chrome as a nice side effect when Oracle does the eventual doc pass —
not a scope change, just don't let it go unrecorded.

**Gate → APPROVED.** Proceed to Mouse for phase breakdown.
