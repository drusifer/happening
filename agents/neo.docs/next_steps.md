# Next Steps — Resume Here

## On new machine (Ubuntu desktop):
1. `sudo apt install libgtk-3-dev` — should install cleanly (no RPi pkg conflicts)
2. `make setup` — re-clones Flutter SDK to .flutter/ (or reuses if migrated)
3. `make test` — confirm 44/44 GREEN on new machine
4. `make run` — first visual smoke test of the strip with mock events

## Then Sprint 2:
- S2-03: AuthService (Google OAuth loopback redirect)
- S2-04: TokenStore (flutter_secure_storage)
- S2-05: CalendarService (Google Calendar API v3, skip all-day events)
- S2-06: EventRepository (cache + dedup)
- S2-07: Wire into HappeningApp, replace mock events
- S2-08: 5-min polling Timer
- S2-09: First-launch auth gate
