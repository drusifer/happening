# Trin QA Context

## Sprint 1 UAT — 2026-02-26

### Automated: 44/44 GREEN ✅

### S1 Task Review

| ID | Status | Notes |
|----|--------|-------|
| S1-01 | ✅ | Flutter project created, Linux confirmed running |
| S1-02 | ✅ | pubspec trimmed to only actual deps (window_manager, screen_retriever) |
| S1-03 | ✅ | alwaysOnTop, frameless, 30px, Offset.zero — all verified in code |
| S1-04 | ✅ | HappeningApp StatefulWidget, mock events, clock wired |
| S1-05 | ✅ | ClockService 1s tick — confirmed by tests |
| S1-06 | ✅ | TimelineStrip StreamBuilder + CustomPainter — clock-driven redraws |
| S1-07 | ⚠️ | NowIndicator at 20% (`_kNowIndicatorFraction = 0.2`), task spec said "left-third" (~33%). Functional but discrepancy noted. |
| S1-08 | ✅ | EventBlock — colored chip, title, start time |
| S1-09 | ✅ | CountdownDisplay — T-minus, clamped to zero when past |
| S1-10 | ✅ | CelebrationWidget — shown when future events empty |
| S1-11 | 👁 | Needs Drew visual confirmation: strip on top of all windows |
| S1-12 | 👁 | Needs Drew visual confirmation: events scroll left, countdown ticks |

### DoD Check
"App launches, strip is always-on-top, mock events animate left, countdown ticks every second."
- App launches: ✅ (make run works)
- Always-on-top: ✅ code, 👁 visual confirm needed
- Events animate left: ✅ xForTime() driven by 1s clock stream
- Countdown ticks: ✅ confirmed by tests + code review

### Minor Issue
- NowIndicator at 20% not ~33% ("left-third"). Low priority — raise with Drew/Cypher to decide if spec should change or impl should move.

### Notes
- video_link_extractor tests exist (S2-01 TDD done early) — good
- No polling timer stub in HappeningApp._HappeningAppState — task said "stub", comment says S2. Acceptable for Sprint 1.
