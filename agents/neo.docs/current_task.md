# Current Task

## TEST_UPDATE — 2026-04-02
**Status**: COMPLETE ✅

### Delivered
- [x] `auth_service_test.dart` — added `cancelSignIn()` to `_FakeAuthService`, new contract test
- [x] `calendar_controller_test.dart` — updated 'service error on refresh' for new per-calendar catchError behavior; added `_PerCalendarFakeService` + isolation test
- [x] `timeline_strip_test.dart` — 4 new sign-in mode tests (hides icons, onSignIn tap, onCancelSignIn tap, null calendarController)
- [x] `hover_card_alignment.png` golden regenerated (stale from settings panel refactor)
- [x] 228/228 green, 0 regressions

### Awaiting
- [ ] Trin QA verify
