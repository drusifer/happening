# Trin Next Steps — 2026-06-11

## F-31 UAT DONE — Awaiting Morpheus review

UAT is complete. All quality gates passed:
- `make lint` PASS (exit 0)
- `make test` PASS (449/449)
- Handoff posted to Morpheus

If Morpheus review finds issues → Neo fixes → Trin re-UAT the failing items only.

## Files changed in F-31 (for Morpheus review scope)
- `app/lib/core/window/window_service.dart` — public hide/show API + protected hooks
- `app/lib/core/window/linux_window_service.dart` — onHideStrip/onShowStrip overrides
- `app/lib/core/window/windows_window_service.dart` — onHideStrip/onShowStrip overrides
- `app/lib/features/timeline/timeline_strip.dart` — state machine + UI
- `app/test/core/window/window_service_test.dart` — F-31 A tests (12 new)
- `app/test/features/timeline/timeline_strip_hide_test.dart` — NEW, 10 tests
- `app/test/goldens/goldens/hover_card_alignment.png` — updated golden
