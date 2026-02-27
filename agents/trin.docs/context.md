# Trin QA Context

## Sprint 1 UAT — 2026-02-26
- Automated: 44/44 GREEN ✅
- Key finding: NowIndicator discrepancy (20% vs 33%). Resolved: Drew wants 15%.

## Sprint 2 UAT — 2026-02-27
- Automated: 83/83 GREEN ✅
- Key finding: Refactor needed for God Objects (HappeningApp, TimelineStrip).
- Key finding: Window placement on Wayland requires X11 backend.

## Sprint 3 Refactor UAT — 2026-02-27
- Automated: 97/97 GREEN ✅
- S3-R01 (Auth): FileTokenStore and GoogleAuthService extracted.
- S3-R02 (Hit Testing): Moved to TimelineLayout.
- S3-R03 (Window): Semantic expand/collapse added to WindowService.
- S3-R04 (Polling): CalendarController manages stream.

### Regression Check:
- OAuth flow: ✅ (unit tests for GoogleAuthService + TokenStore)
- Window sizing: ✅ (unit tests for WindowService)
- Timeline math: ✅ (unit tests for TimelineLayout)
- Clock ticks: ✅ (ClockService tests)
- Calendar parsing: ✅ (GoogleCalendarService regression tests)

### Overall Status: GREEN ✅
The codebase is in excellent shape for Sprint 3 feature implementation.
