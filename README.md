# happening
A sliding calendar strip that always shows you what's happening next. Optimized for those with "event-based time keeping" brains.

## Table of Contents
- [START_HERE.md](START_HERE.md) — Onboarding and setup
- [USER_GUIDE.md](USER_GUIDE.md) — How to use Happening (End-user docs)
- [Docs](docs/) — Architecture, Decisions, PRD, and Task Board
- [Agents](agents/) — Persona documentation and CHAT.md
- [App](app/) — Flutter application source code

## TL;DR
Happening is a persistent, always-on-top horizontal timeline strip that reads your Google Calendar events and animates them in real time toward a fixed "Now" indicator. It's designed specifically for event-based thinkers (including those with ADHD) to provide immediate, glanceable awareness of their day without the cognitive load of a full calendar grid.

---

## Project Status: Sprint 5 (Completed)
- [x] **Sprint 1**: Foundation & Shell (Always-on-top window, mock timeline)
- [x] **Sprint 2**: Google Calendar Integration (OAuth flow, real event fetching, polling)
- [x] **Sprint 3**: Refactor & Polish (Hover details, settings, platform optimization)
- [x] **Sprint 4**: Linux Release + Test Pyramid (v0.1.0 shipped 🚀)
- [x] **Sprint 5**: v0.2.0 Features (Multi-Calendar, Themes, Visual Polish, macOS)

---

## Prerequisites

### System Dependencies (Linux)
- Flutter SDK (>= 3.19.0)
- `clang`, `cmake`, `ninja-build`, `pkg-config` (C++ build tools)
- `libgtk-3-dev` (GTK 3 headers)
- `lld` (LLVM linker)

### Google Cloud Setup
You need a Google Cloud Project with the **Google Calendar API** enabled and an **OAuth 2.0 Client ID** (Desktop type).
1. Download your `client_secret.json` from the Google Cloud Console.
2. Place it in `app/assets/client_secret.json`.

---

## Getting Started

### 1. Setup
Verify your system dependencies and fetch Flutter packages:
```bash
make setup
```

### 2. Run in Development
Run the app on your Linux desktop (forces X11 backend for window positioning):
```bash
make run
```

---

## Building

### Release Build (Linux)
```bash
make build-linux
```
The executable will be located in `app/build/linux/x64/release/bundle/happening`.

### Other Platforms
- **macOS**: `make build-macos`
- **Windows**: `make build-windows`

---

## Testing & Quality
- **Run tests**: `make test`
- **Static analysis**: `make analyze`
- **Format code**: `make format`

---

## Architecture Overview
- **Framework**: Flutter (Desktop)
- **Window Management**: `window_manager` for frameless, always-on-top behavior.
- **Rendering**: `CustomPainter` for the proportional timeline (1 pixel = N seconds).
- **State Management**: `StreamBuilder` driven by a 1Hz clock tick for smooth real-time animation.
- **Data**: Google Calendar API v3 via `googleapis`.
