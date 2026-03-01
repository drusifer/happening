# Morpheus Context

## Sprint 4: Visual QA & Regression Closure — 2026-03-01
- PROBLEM: BUG-14 (missing ticks) passed unit tests but failed live on March 1st.
- ROOT CAUSE: Every unit test used 10:00 AM (mid-day). The logic `windowEnd.day > windowStart.day` failed at Midnight (00:00) and at Month boundaries (Mar 1st vs Feb 28th).
- SOLUTION: Neo implemented a robust `while` loop for ticks.
- REGRESSION GUARD: Trin added a "Midnight/Month Crossing" integration test that specifically mocks the Feb 28 -> Mar 1 boundary.
- UX FIX: Reverted hover card logic to "Fixed Center" (stable UX) as per user feedback.
- OVERALL STATUS: 181/181 unit/widget + 18/18 integration GREEN.

## Decisions
- Always use while/iterator for temporal windows (don't assume same-day).
- Anchoring hover cards to mouse X is a "clever but wrong" UX for this application. Stick to stable event-centered layouts.
