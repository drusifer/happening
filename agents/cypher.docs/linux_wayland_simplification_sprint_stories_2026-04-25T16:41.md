# Linux Wayland Simplification Sprint Stories

**Date**: 2026-04-25T16:41  
**Bloop**: `*bloop plan linux_wayland_simplification sprint`  
**Owner**: Cypher  

## Sprint Goal
Simplify Linux window support by removing native reserved-space panel behavior and aligning Linux with the transparent, non-reserving timestrip model where real-session validation proves it works.

## Scope
In scope:
- Remove Linux-specific reserved-space behavior that exists only to push other windows below Happening.
- Keep the Linux runner as close to the Flutter template as practical.
- Rely on Dart/Flutter plugins for normal window sizing, positioning, transparency, and click-through behavior where they work.
- Validate Linux behavior in both X11/XWayland and Wayland sessions before exposing transparent mode as supported.

Out of scope:
- Replacing X11 struts or Wayland exclusive zones with another native panel-reservation implementation.
- Claiming universal Wayland panel support.
- Changing Windows AppBar behavior.
- Refactoring unrelated Linux resize race fixes unless they conflict with the simplification.

## User Stories

### LWS-01 — Linux Users Get a Non-Blocking Timeline
As a Linux desktop user, I want Happening to stay visible without reserving desktop space, so I can keep using normal window titlebars and desktop layout behavior underneath it.

Acceptance criteria:
- Linux no longer uses native shell-reservation behavior to push other windows down.
- The strip remains top-aligned and always-on-top using Flutter/Dart-supported window APIs where available.
- Idle transparent mode does not trap clicks when Linux pass-through support is verified.
- If pass-through cannot be verified in the current Linux session, the UI does not expose a broken transparent-mode choice.

### LWS-02 — Maintainers Can Build Linux Without X11/Layer-Shell Custom Code
As a maintainer, I want Linux startup code to be minimal and understandable, so we reduce compositor-specific failures and keep future desktop work in Dart where possible.

Acceptance criteria:
- X11 strut/DOCK setup is removed from the Linux runner.
- Optional `gtk-layer-shell` reservation setup is removed from the Linux runner and CMake.
- C++ parsing of `settings.json` for reserved strip height is removed.
- Linux build dependencies no longer require direct `X11` linkage or optional layer-shell detection for Happening-owned code.
- The Linux app still builds with `make build-linux`.

### LWS-03 — Existing Users Do Not Lose Reliability
As an existing Happening user, I want Linux simplification to avoid regressions, so the app does not reintroduce black bars, invisible windows, or broken settings.

Acceptance criteria:
- Existing Linux resize strategy tests remain green.
- Settings availability reflects real support: unsupported modes are hidden, not shown disabled.
- Architecture/docs no longer describe Linux reserved-space behavior as the default product path after the sprint.
- Manual smoke notes cover at least one X11/XWayland run and one Wayland run, or explicitly record the missing environment as a release blocker.

## Product Decision
Linux reserved-space behavior is no longer the preferred product model. The product goal is "visible without getting in the user's way," and transparent non-reserving behavior matches that goal better than shell-reserved panels when reliable.

## Risks
- `window_manager.setIgnoreMouseEvents(forward: true)` may not work consistently across Linux compositors.
- GNOME Wayland does not provide generic layer-shell-style panel behavior for normal apps, so this sprint must avoid promising shell reservation.
- Removing native reservation may change expectations for users who preferred other windows being pushed below the strip.

## Done
- The sprint board is planned.
- Smith approves the user-facing scope.
- Morpheus approves the technical architecture.
- Mouse breaks implementation into short phases with QA gates.
