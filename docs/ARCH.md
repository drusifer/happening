# ARCH: Happening — System Architecture

**Version**: 0.3
**Author**: Morpheus (Tech Lead)
**Date**: 2026-03-01
**Status**: Approved

## TL;DR
A stateless-first Flutter desktop app using a 1fps `StreamBuilder` to drive a `CustomPainter` timeline. Refactored into a decoupled Service/Controller/Repository pattern. v0.1.0 shipped on Linux; v0.2.0 (Themes, Multi-Calendar) in progress.

---

## 1. Overview

Happening is a Flutter desktop application that renders a persistent, always-on-top horizontal timeline strip. It reads events from Google Calendar via OAuth and animates them in real time.

---

## 2. High-Level Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Flutter App (Desktop)                    │
│                                                             │
│  ┌──────────────┐   ┌──────────────┐   ┌────────────────┐   │
│  │  Window      │   │  UI Layer    │   │  Controller    │   │
│  │  Manager     │   │  (Widgets)   │   │     Layer      │   │
│  │              │   │              │   │                │   │
│  │ always-on-top│   │ TimelineStrip│   │ CalController  │   │
│  │ DPI-adaptive │   │ SettingsPanel│   │ ClockService   │   │
│  │ expand/coll. │   │ HoverOverlay │   │ WindowService  │   │
│  └──────────────┘   └──────────────┘   └────────────────┘   │
│                                               │             │
│  ┌────────────────────────────────────────────┼──────────┐  │
│  │                 Data Layer                 │          │  │
│  │                                            ▼          │  │
│  │  ┌──────────────┐   ┌──────────────────────────────┐  │  │
│  │  │ AuthService   │  │     CalendarService          │  │  │
│  │  │ TokenStore    │  │     EventRepository          │  │  │
│  │  └──────────────┘   └──────────────────────────────┘  │  │
│  └───────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

---

## 3. Project Structure

```
happening/
├── lib/
│   ├── main.dart                    # Entry point, window setup
│   ├── app.dart                     # MaterialApp, AppSettings wiring
│   │
│   ├── core/
│   │   ├── window/
│   │   │   └── window_service.dart  # always-on-top, expand/collapse
│   │   ├── time/
│   │   │   └── clock_service.dart   # Stream<DateTime> ticker (1s intervals)
│   │   └── settings/
│   │       └── settings_service.dart # AppSettings, themes, persistence
│   │
│   ├── features/
│   │   ├── auth/
│   │   │   ├── auth_service.dart    # Google OAuth loopback flow
│   │   │   └── token_store.dart     # file-based token persistence
│   │   │
│   │   ├── calendar/
│   │   │   ├── calendar_service.dart      # REST API v3 fetchers
│   │   │   ├── calendar_controller.dart   # Polling + multi-cal fan-out
│   │   │   ├── calendar_event.dart        # Unified event + task model
│   │   │   ├── event_repository.dart      # In-memory cache + dedup
│   │   │   └── video_link_extractor.dart  # meet/zoom/teams regex
│   │   │
│   │   └── timeline/
│   │       ├── timeline_strip.dart        # Root strip widget
│   │       ├── timeline_painter.dart      # High-perf CustomPainter
│   │       ├── timeline_layout.dart       # Hit-testing, DPR scaling
│   │       ├── countdown_display.dart     # untilEnd/untilNext countdown
│   │       ├── celebration_widget.dart    # "All done!" state
│   │       ├── settings_panel.dart        # Hover-revealed gear menu
│   │       └── hover_detail_overlay.dart  # Expanded event card
│   │
│   └── fixtures/ (test/)             # Real API JSON payloads
│
├── pubspec.yaml
└── ...platform folders (linux/, macos/)
```

---

## 4. Key Packages

| Package | Purpose | Why |
|---|---|---|
| `window_manager` | Always-on-top, frameless, screen positioning | Best Flutter desktop window control |
| `google_sign_in` | OAuth 2.0 flow (desktop loopback) | Official Google package |
| `extension_google_sign_in_as_googleapis_auth` | Bridge google_sign_in → googleapis auth | Seamless API auth |
| `googleapis` | Google Calendar REST API v3 | Official client |
| `flutter_secure_storage` | Secure token persistence | OS keychain/keystore |
| `StreamBuilder` (built-in) | Real-time clock updates | No package needed — stateless-first approach |
| `url_launcher` | Open calendar event links + video call URLs | Standard package |
| `intl` | DateTime formatting | Standard |
| `screen_retriever` | Get screen size for window positioning | Companion to window_manager |

---

## 5. Window Strategy

### Always-On-Top Floating Strip

```dart
// main.dart — before runApp
await windowManager.ensureInitialized();
final display = await screenRetriever.getPrimaryDisplay();

// DPR-aware logical sizing (Critical for Linux HiDPI)
final dpr = display.scaleFactor?.toDouble() ?? 1.0;
final logicalWidth = (display.visibleSize?.width ?? 1920.0) / dpr;
final logicalHeight = 30.0 / dpr; // 30.0 physical pixels
final size = Size(logicalWidth, logicalHeight);

await windowManager.waitUntilReadyToShow(
  WindowOptions(
    size: size,
    minimumSize: size,
    maximumSize: size,
    backgroundColor: const Color(0x00000000),
    skipTaskbar: true,
    titleBarStyle: TitleBarStyle.hidden,
    alwaysOnTop: true,
  ),
  () async {
    await windowManager.setResizable(false);
    await windowManager.setMinimumSize(size);
    await windowManager.setMaximumSize(size);
    await windowManager.show();
    await windowManager.setSize(size);
    await windowManager.setPosition(Offset.zero);
    await windowManager.setAlwaysOnTop(true);
  },
);
```

**Notes**:
- **DPR Scaling**: On Linux, `screen_retriever` returns physical pixels. We must divide by DPR to provide a valid logical `Size` to `window_manager`.
- **GTK Header Bar (Linux)**: Must be disabled in `my_application.cc` (`use_header_bar = FALSE`) to allow heights < 50px.
- **Wayland (Linux)**: `GDK_BACKEND=x11` is required to ensure `alwaysOnTop` and `setPosition` are respected by modern compositors.
- Platform-specific entitlements required on macOS (`com.apple.security.network.client`)

---

## 6. Real-Time Animation

### Approach: Computed Pixel Offset via Ticker

Rather than animating widgets, we compute each event's position as a pure function of `now`:

```
eventX = nowIndicatorX - (event.startTime - now).inSeconds * pixelsPerSecond
```

The strip redraws every second via a `ClockService` stream. This keeps all layout logic in one place and makes the system deterministic.

```dart
// clock_service.dart
Stream<DateTime> get tick => Stream.periodic(
  const Duration(seconds: 1), (_) => DateTime.now(),
);
```

The `TimelineStrip` widget is a `StatelessWidget` wrapping a `StreamBuilder<DateTime>`. No state management library needed — the clock stream drives rebuilds, and event data is passed in from above. Smooth enough at 1fps for a calendar strip (events don't move fast enough to need 60fps).

**Time Scale**: `pixelsPerSecond = stripWidth / windowDurationSeconds`
- Default window: 9 hours (1 hour past → 8 hours future)
- Configurable in V2 (F-11)

### State Architecture — Stateless-First

Happening uses a "top-down" state model driven by two long-lived streams. No external state management library (Riverpod, BLoC) is used.

```dart
// app.dart — Simplified
class HappeningApp extends StatefulWidget {
  // Holds SettingsService and AuthService
}

// ... in _HappeningAppState:
StreamBuilder<AppSettings>(
  stream: _settings.settings,
  builder: (context, settings) {
    return MaterialApp(
      theme: _resolveTheme(settings.data),
      home: StreamBuilder<List<CalendarEvent>>(
        stream: _calendarController.events,
        builder: (context, events) {
          return TimelineStrip(events: events.data);
        },
      ),
    );
  }
)
```

1. **Global Streams**: `SettingsService` and `CalendarController` expose broadcast streams that drive the UI rebuilds.
2. **MaterialApp Wiring**: `AppSettings` determines the `ThemeData` (Dark/Light/System) and the strip's logical height.
3. **Timeline Wiring**: The clock stream (1fps) drives the `CustomPainter` to redraw the timeline relative to `now`.
4. **Decoupled Logic**: Services are pure Dart; they are initialized in `main` or `HappeningApp` and passed via constructor injection.

---

## 7. Data Flow

```
Google Calendar API
        │ 
        ▼
 CalendarService.fetchEvents(calendarId)
        │ 
        ▼
 EventRepository (cache + dedup)
        │ 
        ▼
 CalendarController (polling timer + multi-cal wait)
        │ stream
        ▼
 TimelineStrip (StatelessWidget)
        │ + ClockService tick (1fps)
        ▼
 CustomPainter layout → rendered strip
```

### Event Data Model

```dart
@immutable
class CalendarEvent {
  final String id;
  final String title;
  final DateTime startTime;
  final DateTime endTime;
  final Color color;
  final String? calendarEventUrl;
  final String? videoCallUrl;
  final bool isTask;               # True for focusTime/tasks feed
  final String calendarId;         # Original calendar source
  final bool isCompleted;          # Render green if true
}
```

#### Video Call URL Extraction — Flexible Priority Chain

`videoCallUrl` is resolved by a `VideoLinkExtractor` utility that tries sources in order:

```
1. event.hangoutLink          → Google Meet (explicit API field)
2. event.conferenceData       → structured conference entry points (Meet, Zoom, Teams via API)
3. event.location             → scan for known URL patterns
4. event.description          → scan for known URL patterns

Patterns: meet.google.com, zoom.us/j/, teams.microsoft.com/l/meetup-join, webex.com
```

First match wins. This approach handles any new video platform without changing the model — just add a pattern to the extractor. Extensible without coupling.

---

## 8. OAuth Desktop Flow

Google OAuth on desktop uses the **loopback redirect** approach:

1. App starts a local HTTP server on a random port
2. Opens system browser to Google OAuth consent URL with `redirect_uri=http://127.0.0.1:{port}`
3. Browser redirects back to local server with auth code
4. App exchanges code for access + refresh tokens
5. Tokens stored in OS keychain via `flutter_secure_storage`

`google_sign_in` handles steps 1-4. Token refresh is automatic.

---

## 9. Platform-Specific Notes

| Platform | Notes |
|---|---|
| **macOS** | Add `NSAppTransportSecurity` + network entitlements; may need accessibility permission for always-on-top behavior above fullscreen apps |
| **Windows** | `window_manager` works out of box; no special permissions |
| **Linux** | Wayland: always-on-top may be compositor-dependent (works on X11/GNOME); test on Ubuntu |

---

## 10. Architectural Decisions (All Resolved ✅)

| # | Question | Decision | Rationale |
|---|---|---|---|
| AOQ-1 | State management approach? | **Stateless-first** — `StreamBuilder` + single root `StatefulWidget`, no library | Drew: "can it be stateless?" — Yes. Right-sized for this app. |
| AOQ-2 | Strip layout approach? | **CustomPainter** | Drew: "+1, richer interface" |
| AOQ-3 | Clock tick rate? | **1fps** (`Stream.periodic(1s)`) | Drew: speed not a concern |
| AOQ-4 | Single vs multi-calendar MVP? | **Single calendar** (multi in V2 F-09) | Drew: "ACK" |
| —  | Video call URL extraction? | **Flexible priority chain** — hangoutLink → conferenceData → location → description regex | Drew: "flexible way" — extensible without model changes |

---

---

*Approved by Drew 2026-02-26. Ready for: @Mouse *sm plan + @Neo *swe impl scaffold*
