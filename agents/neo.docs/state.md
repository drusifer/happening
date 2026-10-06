# Neo Agent State — macOS hidden click-block fix (*fix loop)

## Context
- Bug: while hidden (mini pill), clicks along the top of the screen were blocked on macOS.
- Root causes: (1) WindowService._reapplyCurrentState guessed state from a legacy _isExpanded flag, so display/font callbacks re-inflated hidden -> full width; (2) any collapse()/expand() (e.g. didChangeAppLifecycleState on app deactivate) could un-hide the window while the UI still drew the pill.
- Design now: StripController is the sole owner of StripState. WindowService.reapplyHandler (set by the controller) -> reapplyCurrentState() is the one re-apply path (display, DPI, font, Windows reassertAppBar). StripController._request drops every request while hidden unless show() (unhide: true). _isExpanded/isExpanded removed. Audio countdown keeps playing while hidden (removed stop() in _hideStrip).
- Verified: core+features tests green, analyzer clean; full suite fails only 2 known macOS goldens (hover_card_alignment, timeline_strip_mini_widget). Drew ran on macOS: hidden window stayed 205x55 in every GEO probe; no un-hide without "restoring strip" (out.txt).
- Lesson: this was an unfinished migration (plan step 4: display/font via the controller). Don't reintroduce a second state copy in WindowService.

## Current Task
*fix loop: Neo DONE, Trin verified (tests + Drew's macOS run log), Morpheus review approved. Loop complete.

## Next Steps
- Still open (not part of this fix): Trin manual macOS UAT of Impeller hover-wobble mitigation; golden regeneration platform decision (Drew); F-33 Countdown Swing, resume at F33-A1 (CountdownSwing pure logic, TDD).
- Optional: tag delayed GEO probes with the state they were taken in (stale labels confuse log reading).
