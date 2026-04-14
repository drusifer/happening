# ARCH: Happening — System Architecture

**Version**: 0.6
**Author**: Morpheus (Tech Lead) / Ora (Knowledge Officer)
**Date**: 2026-04-14
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

| Package | Version | Purpose | Why |
|---|---|---|---|
| `window_manager` | 0.5.1 | Always-on-top, frameless, resize | Best Flutter desktop window control |
| `screen_retriever` | 0.2.0 | Screen dimensions for positioning | Companion to window_manager |
| `googleapis_auth` | 2.0.0 | OAuth 2.0 PKCE flow (desktop loopback) | Native Linux support (direct flow) |
| `googleapis` | — | Google Calendar REST API v3 | Official client |
| `url_launcher` | — | Open event links + video call URLs | Standard package |

---

## 5. Performance Strategy (CPU Optimization)

### Tiered Clock Ticks
To minimize CPU usage while maintaining precision, the app uses multiple update frequencies:
- **10s Coarse Tick**: Drives the `TimelinePainter`. Static elements like the background, ticks, and event blocks only redraw once every 10 seconds.
- **1s Precise Tick**: Drives the `CountdownDisplay` text only.
- **5Hz Animation**: Only active when an event is in the "critical" (< 2m) window.

### Repaint Isolation
The `TimelinePainter` is wrapped in a `RepaintBoundary`. This ensures that updates to sibling widgets (like the ticking countdown text or the flashing icons) do not trigger an expensive repaint of the large timeline canvas.

### Countdown Clock Precision
`active`, `countdownTarget`, `mode`, and `baseColor` are recomputed inside the `tick1s` StreamBuilder (not just the outer `tick10s` builder). This ensures color transitions (flash → amber → idle) happen within 1s of an event boundary, not up to 10s later.

### Latch-on-Expand Hit Testing
To provide stable interactions, hit-test bounds are context-aware:
- **Strip Zone**: Bounds match event column widths.
- **Card Zone**: Bounds expand to match the hover card width.
- **Priority**: The UI prioritizes the current hovered event, "latching" it open until the mouse leaves the expanded area.

---

## 6. Window Strategy

### Dynamic Resize with Solid Background
The window resizes between two heights driven by hover state:
- **Collapsed** (~55px): only the strip is visible. Background covers full window height (solid color, no transparency dependency).
- **Expanded** (~250px): the strip + hover card area. Background uses `WindowService.getExpandedHeight()` (not `constraints.maxHeight`) to cover the full area even during the async OS resize transition.

The background is always a solid color — no compositor transparency required. This avoids the common GTK/Wayland black-area bug where transparent pixels render as black when the compositor does not composite the window.

### Linux Platform Layer (`my_application.cc`)
On Linux, the runner sets up the window as a top-of-screen panel before it is mapped:
- **X11**: `_NET_WM_WINDOW_TYPE_DOCK` and `_NET_WM_STRUT_PARTIAL` are set via Xlib **before** `gtk_widget_show` to prevent the WM from placing the window in the wrong position on first map.
- **Wayland**: `gtk-layer-shell` (`libgtk-layer-shell`) anchors the window to the top edge with `GTK_LAYER_SHELL_LAYER_TOP` and reserves exclusive screen space via `gtk_layer_set_exclusive_zone`. Requires `libgtk-layer-shell-dev` at build time (optional — gracefully skipped if absent).

### Display/DPI Metric Refresh
`WindowService` implements `WidgetsBindingObserver.didChangeMetrics()` to keep the strip's sizing contract synchronized with live display state. When Flutter reports a metrics change, the service refreshes:
- `_dpr` from `window_manager.getDevicePixelRatio()`
- `_screenWidth` from `screen_retriever.getPrimaryDisplay().size.width`

If either value changes, `WindowService` resizes the window through the active `WindowResizeStrategy`. Expanded windows are re-expanded to the new width/height, and collapsed windows are re-collapsed to the new width/height.

On Windows, display/DPI changes can also stale the shell AppBar work-area reservation because the AppBar rect is expressed in physical pixels. After refreshing DPR and width, Windows calls `_reserveCollapsedSpace()` so `ABM_QUERYPOS`/`ABM_SETPOS` reassert the reserved band with updated physical-pixel values, then repositions the Flutter window using the trusted `rcTop / dpr`. This covers DPI scaling changes, resolution changes, and primary-display size changes without Win32 message subclassing.

### Always-Visible Controls
Three icon buttons are always painted on the strip regardless of auth state:
- **Refresh** (left) — re-fetches calendar events and reasserts the Windows AppBar reservation
- **Settings** (left) — opens the settings panel
- **Quit** (right, power icon) — `exit(0)`, visible in loading, sign-in, and authenticated states

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
| AOQ-8 | Linux display server? | **Dual X11+Wayland** | X11 strut via Xlib; Wayland strut via gtk-layer-shell. Both in `my_application.cc`, guarded at compile and runtime. |
| AOQ-9 | Background transparency? | **Solid color always** | Transparent windows render black without a compositor. Solid background eliminates the dependency. |
| AOQ-10 | Display/DPI changes after launch? | **Refresh live metrics in `WindowService.didChangeMetrics()`** | DPR and primary-display width can change after launch; the window and Windows AppBar reservation must be recalculated from current display state. |

---

*Approved by Drew 2026-03-03. Documented by Ora (Knowledge Officer).*
