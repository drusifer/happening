# Bob Context

## Session: 2026-07-08 — judge loop BUG-2/3/4 fixes
- BUG-2: `neo.docs/SKILL.md` was a stale Python/pytest template (Languages: Python (Primary),
  `pytest`/`make coverage` examples) in a 100%-Dart/Flutter project. Rewrote Technical Profile,
  Command Interface, Running Tests, added a missing Code Quality section, fixed Via glob patterns
  (`*.py` → `*.dart`). Trin's SKILL.md has the same *kind* of residue in its test-table details
  (`make test-unit`, `ARGS="-k pattern"` — neither exists in this Makefile) — not fixed this pass
  (out of BUG-3's scope), flagging for a future pass.
- BUG-3: bob-protocol's ENTRY had no relevance-scoping — added guidance to skim state-file
  headers before reading in full, and an EXIT-time hygiene note to trim closed workstreams from
  `current_task.md` rather than letting it grow unbounded.
- BUG-4: `agents/skills/chat/SKILL.md` never documented its own 255-char limit or the
  write-to-docs-file recovery pattern (it was only ever recorded ad hoc in a persona's
  context.md). Added directly to the chat skill so every persona sees it regardless of whose
  state they're reading.
- Handed to Trin for judge-loop verification re-run (`agents/smith.docs/trace_eval.md` iteration 2).

## Session: 2026-04-14
- Bob Protocol initialized on Windows workspace.
- Loaded `agents/CHAT.md` tail, Bob `SKILL.md`, Bob state files, and `agents/skills/bob-protocol/SKILL.md`.
- `make help` and `make chat` currently fail under PowerShell due Unix-shell assumptions in the Makefile (`grep`, `[ -n ... ]`). Direct `python agents/tools/chat.py ...` works for chat posting.

## Session: 2026-04-02
- Calendar fetch: `Future.wait` on per-calendar calls — one 404 poisons all; fixed with `.catchError` per item in `calendar_controller.dart`.
- Sign-out: added `selectedCalendarIds: const []` reset so stale calendar IDs don't bleed to next account (`app.dart`).
- OAuth UX: removed `setState(loading)` from `_signIn()` — strip stays visible during OAuth flow, user retains exit control.
- OAuth cancellation: `GoogleAuthService` stores `_pendingServer`; `cancelSignIn()` closes it; strip shows "Signing in… tap to cancel" and calls cancel on tap (`_isSigningIn` state in `app.dart`, `onCancelSignIn` param on `TimelineStrip`, `isSigningIn` threaded through `TimelinePainter` → `SignInLayer`).

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
