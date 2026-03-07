# ARCH: Happening — System Architecture

**Version**: 0.4
**Author**: Morpheus (Tech Lead) / Ora (Knowledge Officer)
**Date**: 2026-03-03
**Status**: Approved

## TLDR
A stateless-first Flutter desktop app using a tiered `StreamBuilder` architecture to drive real-time updates. Optimized for ultra-low CPU usage via isolated repaints and multi-frequency clock ticks. Uses a decoupled Service/Controller pattern for Google Calendar integration.

---

## 1. Overview

Happening is a Flutter desktop application that renders a persistent, always-on-top horizontal timeline strip. It reads events from Google Calendar and animates them in real time toward a fixed "Now" indicator.

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
│  │ transparent  │   │ SettingsPanel│   │ ClockService   │   │
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
│   ├── main.dart                    # Entry point, service injection
│   ├── app.dart                     # MaterialApp, AppSettings wiring
│   │
│   ├── core/
│   │   ├── window/
│   │   │   └── window_service.dart  # Direct OS proxy, transparency
│   │   ├── time/
│   │   │   └── clock_service.dart   # Tiered tickers (1s and 10s)
│   │   └── settings/
│   │       └── settings_service.dart # AppSettings, themes, persistence
│   │
│   ├── features/
│   │   ├── auth/
│   │   │   ├── auth_service.dart    # Google OAuth loopback flow
│   │   │   └── token_store.dart     # file-based token persistence
│   │   │
│   │   ├── calendar/
│   │   │   ├── calendar_service.dart      # googleapis REST fetchers
│   │   │   ├── calendar_controller.dart   # Polling + multi-cal sync
│   │   │   ├── calendar_event.dart        # Unified event + task model
│   │   │   └── video_link_extractor.dart  # meet/zoom/teams regex
│   │   │
│   │   └── timeline/
│   │       ├── timeline_strip.dart        # Root strip widget (Gated)
│   │       ├── timeline_painter.dart      # Isolated CustomPainter
│   │       ├── timeline_layout.dart       # Hit-testing, coordinates
│   │       ├── countdown_display.dart     # Precise 1Hz text display
│   │       ├── settings_panel.dart        # Multi-column settings UI
│   │       └── hover_detail_overlay.dart  # Latched event card
```

---

## 4. Key Packages

| Package | Purpose | Why |
|---|---|---|
| `window_manager` | Always-on-top, frameless, transparency | Best Flutter desktop window control |
| `googleapis_auth` | OAuth 2.0 flow (desktop loopback) | Native Linux support (direct flow) |
| `googleapis` | Google Calendar REST API v3 | Official client |
| `url_launcher` | Open event links + video call URLs | Standard package |
| `screen_retriever` | Screen dimensions for positioning | Companion to window_manager |

---

## 5. Performance Strategy (CPU Optimization)

### Tiered Clock Ticks
To minimize CPU usage while maintaining precision, the app uses multiple update frequencies:
- **10s Coarse Tick**: Drives the `TimelinePainter`. Static elements like the background, ticks, and event blocks only redraw once every 10 seconds.
- **1s Precise Tick**: Drives the `CountdownDisplay` text only.
- **5Hz Animation**: Only active when an event is in the "critical" (< 2m) window.

### Repaint Isolation
The `TimelinePainter` is wrapped in a `RepaintBoundary`. This ensures that updates to sibling widgets (like the ticking countdown text or the flashing icons) do not trigger an expensive repaint of the large timeline canvas.

### Latch-on-Expand Hit Testing
To provide stable interactions, hit-test bounds are context-aware:
- **Strip Zone**: Bounds match event column widths.
- **Card Zone**: Bounds expand to match the hover card width.
- **Priority**: The UI prioritizes the current hovered event, "latching" it open until the mouse leaves the expanded area.

---

## 6. Window Strategy

### Transparent Always-On-Top Shell
The window is initialized as a 250px tall transparent container.
- The **Strip** (35-50px) is painted at the top with a solid background.
- The **Hover Cards** expand into the transparent area below.
- This creates the illusion of a small strip that "grows" while maintaining a fixed OS window size to avoid expensive resizing.

---

## 7. OAuth Desktop Flow (PKCE + Proxy)

Google OAuth on desktop uses the **PKCE (Proof Key for Code Exchange)** flow to avoid shipping a client secret in the application.

1.  **Code Challenge:** The app generates a `code_verifier` and a `code_challenge` (SHA256 hash of the verifier).
2.  **Auth URL:** The app opens the system browser with the `code_challenge`.
3.  **Local Redirect:** The user authenticates and Google redirects to a local URL (`localhost:port`) with an auth `code`.
4.  **Token Exchange via Proxy:** The app sends the `code` and `code_verifier` to a local proxy server (`make proxy`). The proxy adds the `client_secret` (read from an environment variable) and forwards the request to Google to exchange the code for an access token.
5.  **Token Storage:** The proxy returns the tokens to the app, which stores them securely in `~/.config/happening/google_credentials.json`.


---

## 8. Architectural Decisions (Updated ✅)

| # | Question | Decision | Rationale |
|---|---|---|---|
| AOQ-1 | State management? | **Stateless-first** | Right-sized for simple top-down data. |
| AOQ-5 | CPU Bottlenecks? | **Tiered Frequency** | Repainting a 3000px canvas at 1Hz is too heavy for idle. |
| AOQ-6 | Resizing? | **KISS Protocol** | Asynchronous queues were prone to "stuck" windows. Use direct UI-gated calls. |
| AOQ-7 | Interaction? | **Contextual Latching** | Standard hit-testing makes action buttons hard to click. |

---

*Approved by Drew 2026-03-03. Documented by Ora (Knowledge Officer).*
