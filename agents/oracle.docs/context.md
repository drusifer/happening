# Oracle Context

## Project: Happening
**Date**: 2026-05-26
**Status**: Post-v0.5.1. Astronomical theme fully implemented and documented. Send-to-Back shipped and documented. GeoNames offline city search integrated. Tooling fixed for Windows compatibility.

## Recent Changes Documented (2026-05-26)
- Build System & Versioning: Created a single-source-of-truth version file (`app/assets/version.txt`) registered in `pubspec.yaml`, and implemented `sync_version.py` to auto-propagate versions. Created `Makefile.windows` and streamlined `Makefile` variables (universally exposed before `MKF_ACTIVE` block). Rewrote the `mkf.py` redirection engine using Python's standard `threading` instead of POSIX `select.select()`, achieving complete native Windows compatibility. Refactored the `fetch-cities` target into a pure Python tool (`fetch_cities.py`) that handles GeoNames zip downloads/extracts/formatting cross-platform. Introduced a platform-independent help-rendering parser (`print_help.py`) and wired it up via lazy Make variables (`HELP_COMMAND` and `HELP_PROJECT_TARGETS`) to enable `make help` to function identically across all Unix/Windows shell environments.
- Brand Consistency: Updated root `README.md`, `USER_GUIDE.md`, `docs/PRD.md`, `docs/ARCH.md`, `docs/DECISIONS.md`, and `docs/WINDOWS_BUILD_STRATEGY.md` to consistently refer to the app by its official full name **"What's Happening?"** instead of the shorthand "Happening".
- README.md: Bumped version status to v0.5.1. Documented F-27 (Send-to-Back), F-28 (Linux Reserved Space), F-29 (Astronomical Theme), GeoNames city geocoding, and z-order rendering updates. Added `AstroDataService` and `SkyBody` subsystems to the Architecture Overview. Directed Windows installation guidance to the Official Microsoft Store.
- USER_GUIDE.md: Expanded description of the Send-to-Back feature (10-second auto-restore, non-intrusive focus behavior, continuous extending). Added a comprehensive section explaining the opt-in Astronomical Theme (dynamic sky gradients, celestial timeline markers, moon phase badge, offline computing) and instructions for GeoNames-backed local city search location setup. Documented z-ordering refinements.
- CHAT.md: Archived 1,627 lines of chat history into `chat_archive/CHAT-ARCHIVE-20260526.md`, keeping the active chat file lightweight and clean, and added summaries for past milestones.
- chat.py: Added explicit `encoding="utf-8"` handling to read/write routines, resolving `UnicodeDecodeError` crashes on Windows.
- Makefile: Removed bash-specific validation syntax from `make chat` to support Windows PowerShell/cmd environments.
- TLDR: Added and updated standardized TLDR blocks across 11 core astronomical modules, rendering layers, and window resize strategies (city_search.dart, astro_data_service.dart, astro_settings.dart, solar_calculator.dart, astronomical_background_layer.dart, sky_body.dart, solar_body.dart, lunar_body.dart, astro_objects.dart, linux_resize_strategy.dart, macos_resize_strategy.dart).

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
