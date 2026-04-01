# Bob Context

## Session: 2026-04-01
- SignIn screen refactored to SignInLayer painter (FetchingLayer pattern) — TimelineStrip always mounted, window sizing correct pre-auth.
- Settings panel: 3-col layout, Calendars rowspans full height, bounded by Positioned(bottom:8). No overflow at any font size.
- app.dart: _SignInStrip removed, unauthenticated state uses TimelineStrip(onSignIn: _signIn).

## Session: 2026-03-07 (Post-v0.2.0 Ship)
- v0.2.0 SHIPPED: commit c39603e, tagged 2026-03-06.
- 185/185 tests GREEN.
- Auth migrated: PKCE + localhost proxy (no client_secret in binary).
- Dist targets: dist-linux, dist-windows, dist-proxy-linux in Makefile.
- Docs groomed: README.md, docs/ARCH.md, docs/task.md, USER_GUIDE.md updated.
- macOS deferred to v0.2.1 (pending hardware).
- Awaiting Drew's instructions for next sprint.
