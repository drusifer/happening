# Screen/DPI Refresh Docs Summary 2026-04-14T18:50

## Request
Drew asked Oracle to update docs with new information for refreshing screen size and DPI.

## Sources Checked
- `app/lib/core/window/window_service.dart`
- `app/lib/features/timeline/timeline_strip.dart`
- `agents/morpheus.docs/APPBAR_REASSERT_PLAN.md`
- `agents/morpheus.docs/OVERLAP_DIAGNOSIS.md`
- Existing `docs/ARCH.md`, `docs/DECISIONS.md`, and `agents/oracle.docs/LESSONS.md`

## Updates Made
- `docs/ARCH.md`: bumped to v0.6 and added Display/DPI Metric Refresh under Window Strategy.
- `docs/DECISIONS.md`: added DEC-004 for `didChangeMetrics()` refresh of DPR and primary display width.
- `agents/oracle.docs/LESSONS.md`: added 2026-04-14 lesson and rule.
- `agents/morpheus.docs/APPBAR_REASSERT_PLAN.md`: marked shipped; corrected periodic timer as removed; documented the shipped metrics-driven path.

## Core Fact Recorded
`WindowService` must not treat DPR or screen width as launch-only constants. It observes `WidgetsBindingObserver.didChangeMetrics()`, refreshes `_dpr` and `_screenWidth`, reasserts the Windows AppBar reservation with updated physical-pixel values, then re-runs the current expand/collapse size path.
