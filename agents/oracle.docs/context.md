# Oracle Context

## Project: Happening
**Date**: 2026-04-02
**Status**: Post-v0.3.x. Sign-in refactored to TimelineStrip compositor layer. Settings panel overflow fixed. OAuth cancellation implemented.

## Recent Changes Documented (2026-04-02)
- LESSONS.md: Settings panel `Positioned` needs `bottom` anchor for bounded height.
- LESSONS.md: Sign-in screen must live inside TimelineStrip as a compositor layer (SignInLayer).
- LESSONS.md: `Future.wait` on per-calendar fetches — single 404 poisons whole fetch; use `.catchError` per-calendar.
- LESSONS.md: `selectedCalendarIds` must be cleared on sign-out to prevent account bleed.
- LESSONS.md: Don't set loading auth state during OAuth — strip disappears and there's no way to exit.
- LESSONS.md: OAuth `server.first` blocks forever if window is closed — store `_pendingServer` and expose `cancelSignIn()`.

## Recent Changes Documented (2026-03-16)
- ARCH.md v0.5: Section 6 rewritten (solid background, Wayland layer-shell, always-visible controls, countdown precision fix). AOQ-8, AOQ-9 added. Package table updated with versions.
- README.md: Linux build deps updated with optional `libgtk-layer-shell-dev`.
- LESSONS.md: X11 DOCK type must be set before gtk_widget_show (race condition fix).

## Pending Tasks
- [ ] Update USER_GUIDE.md if quit button UX changes affect end-user docs.
