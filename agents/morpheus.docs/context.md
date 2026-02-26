# Morpheus Context

## Project: Happening
- PRD v0.2 approved (docs/PRD.md)
- ARCH v0.1 drafted (docs/ARCH.md)

## Key Architectural Decisions (ALL APPROVED 2026-02-26)
- Flutter desktop (macOS, Windows, Linux)
- window_manager package for always-on-top frameless window
- Flutter logical pixels = DPI-adaptive automatically (no manual DPI math)
- Strip height: 52px logical
- STATELESS-FIRST: StreamBuilder<DateTime> + single root StatefulWidget, NO Riverpod/BLoC
- CustomPainter for proportional timeline layout (richer interface)
- Real-time: 1fps clock tick (Stream.periodic 1s)
- Pixel offset formula: eventX = nowIndicatorX - (event.startTime - now).inSeconds * pixelsPerSecond
- Default time window: 1hr past, 8hr future (9hr total)
- OAuth: loopback redirect via google_sign_in package
- Video call URL: flexible priority chain — hangoutLink → conferenceData → location regex → description regex

## Key Packages
- window_manager, screen_retriever, google_sign_in, googleapis,
  extension_google_sign_in_as_googleapis_auth, flutter_secure_storage,
  url_launcher, intl (no Riverpod needed)
