# Oracle Context

## Project: Happening
**Date**: 2026-04-02
**Status**: Post-v0.3.x. Sign-in refactored to TimelineStrip compositor layer. Settings panel overflow fixed. OAuth cancellation implemented.

## Recent Changes Documented (2026-04-14)
- ARCH.md v0.6: Added Display/DPI Metric Refresh under Window Strategy.
- DECISIONS.md: Added DEC-004 for refreshing DPR and primary display width via `WindowService.didChangeMetrics()`.
- LESSONS.md: Recorded rule that DPR/screen width are not launch-only constants; refresh live display metrics and reapply Windows AppBar reservation.
- APPBAR_REASSERT_PLAN.md: Marked shipped; documented that periodic reassert timer was removed after shrink regression and replaced by metrics-driven refresh plus refresh-button reassert.
- README.md: Updated project status to v0.4.0 and architecture overview with display/DPI refresh + Windows AppBar reassert behavior.
- USER_GUIDE.md: Added troubleshooting note for Windows overlap after display scale/resolution changes; Refresh button re-applies reserved screen space.

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

## Recent Changes Documented (2026-04-02)
- README.md: v0.3.1 bump, `libsecret-1-dev` Linux dep, MSIX Windows install, FlutterSecureTokenStore + per-cal isolation in arch section.
- USER_GUIDE.md: New §3 First Launch/Sign-In (tap-to-sign-in, tap-to-cancel, OS keychain), Quit vs Logout clarified, sections renumbered.

## Pending Tasks
- None.
