# Linux Wayland Simplification Gate 1 Review

**Date**: 2026-04-25T16:41  
**Reviewer**: Smith  
**Artifact**: `agents/cypher.docs/linux_wayland_simplification_sprint_stories_2026-04-25T16:41.md`

## Verdict
Approved.

## UX Findings
- The stories match the user's current intent: simplify Linux support by removing compositor-specific reservation behavior instead of deepening it.
- The scope uses user-facing language: "visible without getting in the way" is the right mental model; "strut," "DOCK," and "layer-shell" stay out of the product surface.
- The proof gate is necessary. Users should not see a Linux transparent-mode choice until the team has real-session evidence that pass-through is safe.

## HCI Notes
- **Error prevention**: hide unsupported Linux modes instead of exposing controls that produce black bars or swallowed clicks.
- **Match with real world**: users understand "window behavior" and "clicks pass through"; avoid exposing compositor terms in settings.
- **Visibility of system status**: manual smoke notes must clearly state which Linux session was tested: X11/XWayland or Wayland.

## Approval Conditions
- Keep Linux transparent mode hidden until validated.
- Do not add explanatory warning copy to the primary settings panel unless there is a user action to take.
- If Linux pass-through fails, the sprint can still pass by simplifying native code and documenting Linux transparent mode as unavailable.
