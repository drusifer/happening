# Morpheus Final Review — macOS ASWebAuthenticationSession *impl — 2026-07-01

**Reviewing:** Neo's Phase A/B implementation + Trin's Phase C UAT
(`docs/sprints/macos-aswebauth-oauth/macos_aswebauth_phase_c_uat_2026-07-01.md`).

## Architecture check vs. the original design (my own doc, `agents/morpheus.docs/aswebauth_guidance_2026-07-01.md`)

- **Scope held**: macOS-only branch in `AuthService`/`OAuthRedirectHandler`, Windows/Linux loopback
  flow untouched. No 3-platform migration crept in. Confirmed by diff — only
  `auth_service.dart`, `oauth_redirect_handler.dart`, `AppDelegate.swift`, `pubspec.yaml`, and one new
  test file touched.
- **Interface reshape is the right call, not scope creep**: moving the browser-launch responsibility
  into `OAuthRedirectHandler.authenticate()` (replacing the old `start()`+external-`launchUrl`+
  `waitForCallback()` split) is necessary, not gratuitous — `flutter_web_auth_2` doesn't expose
  "launch" and "wait" as separate steps, they're one atomic native call. Trying to keep the old 3-step
  shape would have forced an awkward fake `start()` for macOS. The `_LoopbackRedirectHandler` side of
  the same interface change is a pure mechanical move (launchUrl called from inside authenticate() now
  instead of by the caller) — zero behavior change, correctly covered by the unchanged loopback tests
  passing.
- **Phase A resolution is sound, not a shortcut.** Neo didn't skip the spike — the question ("does the
  Desktop OAuth client type accept a custom-scheme redirect_uri") has been empirically answered by this
  app's *own shipped v0.5.3 code* for months. Google's redirect_uri validation is server-side and
  string-based; it can't distinguish "the browser that opened this URL was launched via `url_launcher`"
  from "via `ASWebAuthenticationSession`" — both send the identical `redirect_uri` param. That's correct
  reasoning, not an assumption. No second Google Cloud client, no scope increase to escalate.
- **`app_links` removal is correctly total, not partial.** Grepped for remaining references myself
  before trusting the "zero usages" claim — confirmed clean (pubspec, Dart source, and the now-dead
  `AppDelegate.swift` override all removed together). Leaving any one of those in place while removing
  the others would've been the kind of half-migration that causes confusion later.

## Code quality

- `_ASWebAuthRedirectHandler.authenticate`'s catch-and-log-both-branches (CANCELED vs. other codes) is
  good: it doesn't silently swallow real failures into the same bucket as user-cancel without at least
  logging the distinction, even though both currently return `null` to the caller (matching AC-6's
  literal requirement — "cancel → sign-in-cancelled state" — without over-engineering a third return
  state the UI doesn't have a slot for yet).
- The `cancel()` no-op is **documented at the call site with why**, not left as an empty method someone
  has to reverse-engineer later. Correct to flag it to Smith rather than pretend it's equivalent to the
  old behavior.
- Test approach (fake `FlutterWebAuth2Platform` via the plugin's own platform-interface seam) is the
  right level — verifies our error-handling logic without needing a real system sheet, and would catch
  a regression if the CANCELED-code assumption ever changes upstream.

## On Trin's 3 flagged gaps

1. **No real system-sheet smoke test** — accepted as a genuine environment limitation, not a process
   gap. Recommend Drew do one real sign-in before resubmitting to App Review; this is the only
   remaining unverified link in the chain (AC-1 through AC-4/6 are all verified up to that boundary).
2. **Chrome-default-browser bug (#136)** — correctly identified as outside our control (upstream/Apple
   bug) and correctly left unresolved rather than guessed at. Not a blocker; worth a one-time manual
   check if convenient.
3. **`cancelSignIn()` no-op on macOS** — real, minor UX regression from the old behavior, correctly
   scoped as *not* an AC-6 violation (AC-6 only covers the user's own sheet-cancel path). Deferring to
   Smith is right — this is a UX call, not an architecture one.

## Verdict: **APPROVED**

Implementation matches the architecture and stays in scope. No changes requested. Ready for Drew to
review the diff and decide whether to commit.

## Recommended follow-up (not part of this *impl loop)

Per my original research doc's "Next steps": once Drew reviews, this warrants a DEC-0XX entry in
`DECISIONS.md` via `@Oracle *ora record decision` — scoped to macOS OAuth only, so future readers don't
wonder why macOS and Windows/Linux use different transport mechanisms for the same OAuth flow.
