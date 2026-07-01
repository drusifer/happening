# Guidance: ASWebAuthenticationSession requirement (Apple review) — 2026-07-01

**Asked by:** Drew, via `*chat @morpheus`
**Question:** Apple wants `ASWebAuthenticationSession` for OAuth. Is there a Flutter/Dart frontend, or do we need custom Swift?

## Answer

Yes — [`flutter_web_auth_2`](https://pub.dev/packages/flutter_web_auth_2) (pub.dev, actively maintained, MIT) is a pure Dart API wrapping `ASWebAuthenticationSession` natively on iOS 12+/macOS 10.15+ (current major version bumps min OS to iOS 17.4+/macOS 14.4+ following Apple's deprecation of the old APIs). Call is `FlutterWebAuth2.authenticate(url: ..., callbackUrlScheme: ...)`. **No custom Swift required** — the plugin ships its own native implementation; our side is a pub dependency + an `Info.plist` `CFBundleURLTypes` entry for the callback scheme (plist config, not code).

It also has Windows/Linux/Android/Web backends (Windows/Linux via `desktop_webview_window` or a loopback server depending on config), so it *could* unify our whole OAuth flow. But scope creep isn't warranted here.

## Recommendation

Scope the swap to **macOS only** — the only platform under Apple review pressure:

- Branch `AuthService` on `Platform.isMacOS` → use `flutter_web_auth_2` for the browser-launch + code-capture leg on macOS.
- Keep the existing `googleapis_auth` PKCE + `make proxy` loopback flow (ARCH.md §7) unchanged for Windows/Linux — it works, and isn't subject to App Store review.
- Token exchange (code → tokens via our local proxy, which holds `client_secret`) is unaffected either way; only how the auth *code* is captured changes on macOS.

## Risks to spike before committing (Neo)

1. **Redirect URI type** — Google's docs mark loopback-IP redirects deprecated for iOS/Android OAuth client types; unclear whether a custom URL-scheme redirect on a *desktop* client type (which is what we register today) is accepted by Google's OAuth server, or whether this forces registering a second (iOS-type) OAuth client just for macOS. Confirm before touching Cloud Console config.
2. **Known plugin bug** — `flutter_web_auth_2`'s issue tracker has an open, unresolved `ASWebAuthenticationSession` bug report (no workaround found as of this search). Check it against our exact flow before UAT sign-off.

## Follow-up: why not use flutter_web_auth_2 on all 3 platforms? (2026-07-01)

Checked what `flutter_web_auth_2` actually does on Windows/Linux: it doesn't reuse the system browser there. Its Win/Linux backend is built on `desktop_webview_window`, which is an **embedded webview** (WebView2 on Windows, webkit2gtk on Linux) — the plugin opens Google's login page *inside the app*, not in the user's default browser.

That's a hard blocker, not a style preference: Google has enforced a `disallowed_useragent` block on its OAuth endpoint for embedded webviews since 2021/2023 (`android.webkit.WebView`, `WKWebView`, and by extension embedded Win/Linux webviews are all caught by this). Sign-in would fail outright, or at minimum violate Google's OAuth Native App policy, which requires the system browser.

Our *current* Windows/Linux flow (`googleapis_auth` PKCE + loopback, ARCH.md §7) already opens the **system browser** — it's correctly positioned relative to Google's policy today. Switching it to `flutter_web_auth_2` for "consistency" would trade a compliant, working, shipped implementation for a non-compliant one, purely to match macOS.

macOS is the special case here, not the other way around: `ASWebAuthenticationSession` is Apple's *own* system-browser-equivalent primitive (shares Safari's cookie jar, gets the anti-phishing chrome, satisfies App Review) — the macOS backend of `flutter_web_auth_2` is fine because it's not an embedded webview, it's a first-class OS auth session. The Win/Linux backend of the same plugin is a different, weaker mechanism under the hood. So "one plugin" doesn't mean "one mechanism" — adopting it everywhere would actually widen platform divergence in practice (good on macOS, a regression on Win/Linux), which is the opposite of what unification is supposed to buy us.

**Conclusion holds:** macOS-only branch in `AuthService`; leave Windows/Linux as-is.

## Next steps

- Neo: short spike on risk #1 (redirect URI acceptance) before implementation.
- Once confirmed, `@Oracle *ora record decision` (this would be a new DEC-0XX in DECISIONS.md, scoped to macOS OAuth only).
- Then `@Mouse *sm plan` a small task (F-32-adjacent) — this is not a new PRD feature, it's a platform-compliance fix to existing F-02/OAuth.

## Sources

- https://pub.dev/packages/flutter_web_auth_2
- https://github.com/Mabenan/flutter_web_auth_2
- https://developers.google.com/identity/protocols/oauth2/native-app
