# ARCH: What's Happening? — System Architecture

**Version**: 0.8
**Author**: Morpheus (Tech Lead) / Ora (Knowledge Officer)
**Date**: 2026-06-21
**Status**: Approved — §6 updated for the window-transition convergence (DEC-009)

## TLDR
A stateless-first Flutter desktop app using a tiered `StreamBuilder` architecture to drive real-time updates. Optimized for ultra-low CPU usage via isolated repaints and multi-frequency clock ticks. Uses a decoupled Service/Controller pattern for Google Calendar integration.

---

## 1. Overview

"What's Happening?" is a Flutter desktop application that renders a persistent, always-on-top horizontal timeline strip. It reads events from Google Calendar and animates them in real time toward a fixed "Now" indicator.

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
│   │   │   ├── auth_service.dart          # Google OAuth PKCE flow
│   │   │   ├── oauth_redirect_handler.dart # Platform-split redirect capture
│   │   │   └── token_store.dart           # file-based token persistence
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
| `googleapis_auth` | 2.0.0 | OAuth 2.0 PKCE token exchange (all platforms) | Native Linux support (direct flow) |
| `flutter_web_auth_2` | 5.0.3 | `ASWebAuthenticationSession` redirect capture (macOS only) | Apple App Review requires this API over a plain browser launch |
| `googleapis` | — | Google Calendar REST API v3 | Official client |
| `url_launcher` | — | Open event links + video call URLs (Windows/Linux OAuth browser launch) | Standard package |

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

### Unified Window-State Machine (`StripController` → `applyState`)
Every window transition — init, hover expand/collapse, hide/show, settings, display
change, font change, AppBar reassert — routes through **one applier**:
`WindowService.applyState(StripState)`, the single source of OS geometry. `StripState`
has three values: `collapsedShown`, `expandedShown`, `hidden`.

- **`StripController`** (a `ChangeNotifier`) owns the logical `StripState` and is the
  serialized gate for user-driven transitions (`collapse / expand / hide / show /
  reapply`). It funnels concurrent requests through an `AsyncGate` (one-slot,
  last-wins) so a hide racing an in-flight expand always settles on the latest
  intent. The widget observes the controller for `isExpanded`.
- **`applyState`** is idempotent: it reserves the platform work-area band FIRST
  (`applyReservation` — Windows AppBar register + reserve; macOS no-op), then applies
  size + position AT the returned reserved origin via the active `WindowResizeStrategy`.
  Reserve-before-position is what keeps the strip inside its own strut.
- **Transition dispatch:** `→ hidden` releases the strut and shrinks to the mini pill;
  `hidden → shown` re-registers + reserves + forces a first-frame present (the one
  path that composites a frameless reserved window); `shown → shown` (expand/collapse)
  re-applies in place, re-pinning to the reserved origin.

This convergence (sprint 2026-06) replaced a set of divergent per-transition paths
(`ExpansionController`, `resizeToMini/FullStrip`, `_doExpand/_doCollapse`,
`performResize`) that each re-implemented reservation/positioning slightly
differently — the root cause of the recurring "strip lands below its own strut" bug
class. See [DECISIONS.md](DECISIONS.md) DEC-009.

### Dynamic Resize with Solid Background
The window resizes between two heights (driven by `StripState`):
- **Collapsed** (~55px): only the strip is visible. Background covers full window height (solid color, no transparency dependency).
- **Expanded** (~250px): the strip + hover card area. Background uses `WindowService.getExpandedHeight()` (not `constraints.maxHeight`) to cover the full area even during the async OS resize transition.


### Linux Platform Layer (`my_application.cc`)
On Linux, the runner stays close to the standard Flutter GTK startup path. It sets
the app title/icon, creates the Flutter view, gives the view a transparent
background before first frame, and defers showing the window until Flutter has
content.

Linux no longer uses "What's Happening?"-owned shell-reservation code. The runner does not
set X11 `_NET_WM_STRUT_PARTIAL`, does not mark the window as an X11 DOCK, and
does not use Wayland `gtk-layer-shell`.

Current Linux development runs prefer X11/XWayland (`GDK_BACKEND=x11`) because
standard native Wayland clients cannot reliably request absolute top-of-screen
placement through Flutter/GTK window APIs. Native Wayland is treated as
unsupported for the strip behavior until "What's Happening?" either adopts a compositor
protocol such as layer-shell or implements a separate conservative Wayland mode.

### Display/DPI Metric Refresh
`WindowService` implements `WidgetsBindingObserver.didChangeMetrics()` to keep the strip's sizing contract synchronized with live display state. When Flutter reports a metrics change, the service refreshes:
- `_dpr` from `window_manager.getDevicePixelRatio()`
- `_screenWidth` from `screen_retriever.getPrimaryDisplay().size.width`

If either value changes, `WindowService` re-applies the *current* `StripState` through `applyState` — the logical state is unchanged, only the computed geometry (width, origin, band height) is recomputed.

Because `applyState` reserves before positioning, that one call also refreshes the Windows AppBar band (`ABM_QUERYPOS`/`ABM_SETPOS` with updated physical-pixel values — the rect is expressed in physical pixels and DPI/resolution changes stale it) and repositions the Flutter window at the trusted `rcTop / dpr`. This covers DPI scaling, resolution, and primary-display size changes without Win32 message subclassing.

### Always-Visible Controls
Four icon buttons are always painted on the strip (visible once authenticated):
- **Refresh** — re-fetches calendar events and reasserts the Windows AppBar reservation
- **Send to Back** (`flip_to_back` icon) — lowers the strip behind all other windows for 10 seconds, then auto-restores always-on-top. Re-pressing resets the timer. Implemented via `setAlwaysOnTop(false)` + `blur()` on press; `setAlwaysOnTop(true)` on restore. `wm.lower()` is not available in `window_manager`; the window drops behind newly-focused windows naturally after losing always-on-top.
- **Settings** — opens the settings panel
- **Quit** (power icon, right side) — `exit(0)`

---

## 7. OAuth Desktop Flow (PKCE + Proxy)

Google OAuth on desktop uses the **PKCE (Proof Key for Code Exchange)** flow to avoid shipping a client secret in the application. The redirect-capture mechanism (how the app gets the auth `code` back from Google) is platform-specific; everything else is shared. This split lives behind the `OAuthRedirectHandler` interface (`oauth_redirect_handler.dart`), which `AuthService.signIn()` calls without needing to know which platform it's on.

1.  **Code Challenge:** The app generates a `code_verifier` and a `code_challenge` (SHA256 hash of the verifier).
2.  **Auth Request + Redirect Capture (platform-specific):**
    - **Windows/Linux:** `_LoopbackRedirectHandler` binds an ephemeral `localhost` HTTP server, opens the auth URL in the system browser via `url_launcher`, and waits for Google's browser redirect to hit that loopback server with the `code`. This is the RFC 8252 §7.3 desktop-app flow — no registry entries, no privileges.
    - **macOS:** `_ASWebAuthRedirectHandler` calls `FlutterWebAuth2.authenticate(url:, callbackUrlScheme:)`, which presents Google's login inside a native `ASWebAuthenticationSession` system sheet and captures the redirect itself — no loopback server, no separate browser launch. Two reasons this differs from Windows/Linux:
      - The Mac App Store sandbox ships without the `com.apple.security.network.server` entitlement a loopback server needs.
      - Apple App Review requires OAuth to use `ASWebAuthenticationSession` specifically (flagged in review feedback on the v0.5.3 submission) rather than a plain external browser launch.
      - The redirect URI is Google's reverse-client-ID custom URL scheme (`com.googleusercontent.apps.{CLIENT_ID}:/oauth2redirect`), registered in `macos/Runner/Info.plist` under `CFBundleURLTypes`. Desktop-type OAuth clients in Google Cloud Console accept this scheme automatically — no second (iOS-type) client registration was needed; this was proven empirically before the `ASWebAuthenticationSession` migration, when the same scheme was already in use with a plain browser launch.
      - If the user cancels/dismisses the system sheet, the native plugin surfaces `PlatformException(code: 'CANCELED')`, which the handler catches and treats the same as any other cancelled sign-in.
3.  **Token Exchange via Proxy (shared):** The app sends the `code` and `code_verifier` to a local proxy server (`make proxy`). The proxy adds the `client_secret` (read from an environment variable) and forwards the request to Google to exchange the code for an access token. This step doesn't care how the code was captured, so it's identical across all three platforms.
4.  **Token Storage (shared):** The proxy returns the tokens to the app, which stores them securely in `~/.config/happening/google_credentials.json`.

---

## 8. Architectural Decisions (Updated ✅)

| # | Question | Decision | Rationale |
|---|---|---|---|
| AOQ-1 | State management? | **Stateless-first** | Right-sized for simple top-down data. |
| AOQ-5 | CPU Bottlenecks? | **Tiered Frequency** | Repainting a 3000px canvas at 1Hz is too heavy for idle. |
| AOQ-6 | Resizing? | **KISS Protocol** | Asynchronous queues were prone to "stuck" windows. Use direct UI-gated calls. |
| AOQ-7 | Interaction? | **Contextual Latching** | Standard hit-testing makes action buttons hard to click. |
| AOQ-8 | Linux display server? | **No shell reservation** | Linux uses the standard Flutter GTK runner plus Dart window APIs. X11 struts and Wayland layer-shell reservation were removed. Transparent/click-through was also removed — Send-to-Back achieves the same user goal (temporarily move the strip out of the way) with zero platform-specific code. |
| AOQ-11 | Interaction model for moving strip out of the way? | **Send-to-Back** | Click-through required native C++/Dart platform code that was unreliable or unavailable. Send-to-Back (`setAlwaysOnTop(false)` + `blur()`) achieves the same user goal cross-platform with no platform-specific code. Auto-restores after 10s. |
| AOQ-9 | Background transparency? | **Solid color always** | Transparent windows render black without a compositor. Solid background eliminates the dependency. |
| AOQ-10 | Display/DPI changes after launch? | **Refresh live metrics in `WindowService.didChangeMetrics()`** | DPR and primary-display width can change after launch; the window and Windows AppBar reservation must be recalculated from current display state. |
| AOQ-12 | OAuth redirect capture on macOS? | **`ASWebAuthenticationSession` (macOS-only), loopback stays on Windows/Linux** | Apple App Review requires this API over a plain browser launch, and the Mac App Store sandbox lacks the `network.server` entitlement a loopback server needs. `flutter_web_auth_2`'s Windows/Linux backend is an embedded webview, which Google's OAuth policy blocks — adopting it everywhere would fix nothing and risk breaking a compliant, working flow. |

---

*Approved by Drew 2026-03-03. Documented by Ora (Knowledge Officer).*
