# LINUX_EXPANDED_PAINT_FIX Summary — 2026-04-17T13:38

## Problem
- Expanded Linux hover area sometimes showed cards and sometimes appeared as a black/solid empty band.
- The project architecture intentionally avoids Linux transparency because X11/Wayland compositors can render transparent pixels as black.

## Fix
- `HoverController.setIntent()` now returns `true` when an expansion/collapse intent is accepted and `false` when suppressed.
- `LinuxHoverController` returns `false` for collapse intents dropped during the GTK synthetic-exit suppression window.
- `TimelineStrip` now preserves `_hoveredEvent` and hover state when a collapse intent is suppressed, so the card stays painted instead of leaving only the expanded background.

## Tests
- Hover controller tests assert accepted vs suppressed intent return values.
- TimelineStrip has a Linux regression test for preserving `HoverDetailOverlay` during a suppressed synthetic exit.

## Validation
- `make -f Makefile.prj test V=-vv` ran. New regression coverage passed.
- Full suite still fails on unrelated WindowService tests that access `WidgetsBinding.instance` before test binding initialization.
