# Linux Wayland Simplification Gate 2 Review

**Date**: 2026-04-25T16:41  
**Reviewer**: Smith  
**Artifact**: `agents/morpheus.docs/LINUX_WAYLAND_SIMPLIFICATION_ARCH_2026-04-25T16:41.md`

## Verdict
Approved.

## UX Findings
- The architecture supports the correct user model: Happening should be visible without interfering with normal window use.
- Removing shell-reservation behavior is acceptable because transparent mode changes the interaction contract.
- The validation gate protects users from seeing a Linux mode that the current session cannot support.

## Approval Conditions
- Settings labels must remain outcome-based, not compositor-based.
- A failed Linux Wayland smoke test should hide transparent mode rather than blocking the whole native-code removal.
- Manual smoke results must be recorded before release notes claim Linux transparent support.
