# New Requirement: Timestrip Hide/Collapse Button

**From:** User  
**Date:** 2026-06-09  

## Feature Request

Add a **hide button on the left side of the timestrip** that collapses the full timestrip by sliding the whole panel off to the left, leaving only:

- The **countdown timer**
- The **expand button** (to restore)

Clicking either the countdown timer or the expand button restores the timestrip to its full extent.

## Strut / Reserved Space Behavior

If a strut is currently being used to reserve space at the top of the screen (Linux reserved space), that strut should be **released** when the timestrip enters hidden mode — allowing that screen space to be used by other windows again.

When the timestrip is restored (expanded), the strut should be re-acquired as normal.

## Questions

- Does this fit the current sprint or start a new one?
- Any concerns about animation approach (slide left) vs fade or snap?
- How should this interact with the send-to-back / always-on-top behavior?

wdyt?
