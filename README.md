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

## Project Status: v0.2.1 (macOS)
- [x] **Sprint 1**: Foundation & Shell (Always-on-top window, mock timeline)
- [x] **Sprint 2**: Google Calendar Integration (OAuth flow, real event fetching, polling)
- [x] **Sprint 3**: Refactor & Polish (Hover details, settings, platform optimization)
- [x] **Sprint 4**: Linux Release + Test Pyramid (v0.1.0 shipped)
- [x] **Sprint 5**: v0.2.0 Features (Multi-Calendar, Themes, Visual Polish, PKCE auth)
- [x] **Sprint 6**: v0.2.1 macOS support

---

## Installing (End Users)

Download the latest release for your platform from the [releases page](https://github.com/drussell/happening/releases).

> **No extra setup required.** Authentication uses PKCE OAuth via a hosted proxy — no API keys or client secrets needed.

### Runtime Requirements

| Platform | Requirement |
|----------|-------------|
| macOS    | macOS 12 Monterey or later |
| Linux    | GTK 3 (`libgtk-3`) — pre-installed on most modern distros |
| Windows  | Windows 10 or later, Visual C++ Redistributable (usually already installed) |

### macOS
1. Download `happening-<version>-macos-arm64.dmg` (or `x64` for Intel Macs).
2. Open the `.dmg` and drag `happening.app` to your `/Applications` folder.
3. Eject the disk image.
4. On first launch, right-click → **Open** (to bypass Gatekeeper on unsigned builds).
5. Sign in with Google when prompted — a browser window will open automatically.

### Linux
1. Download `happening-<version>-linux-x64.tar.gz`.
2. Extract and run:
    ```bash
    tar -xzf happening-<version>-linux-x64.tar.gz
    ./bundle/happening
    ```
3. Sign in with Google when prompted.

### Windows
1. Download `happening-<version>-windows-x64.zip`.
2. Extract the zip to a folder of your choice.
3. Run `happening.exe` from the extracted `Release/` folder.
4. Sign in with Google when prompted — a browser window will open automatically.

---

## Building from Source (Developers)

### Build Requirements

These are only needed if you are building from source. End users do not need these.

#### macOS
- Flutter SDK (>= 3.19.0)
- Xcode (>= 14) with Command Line Tools (`xcode-select --install`)
- CocoaPods (`sudo gem install cocoapods`)

#### Linux
- Flutter SDK (>= 3.19.0)
- `clang`, `cmake`, `ninja-build`, `pkg-config`
- `libgtk-3-dev`
- `lld` (LLVM linker)

#### Windows
- Flutter SDK (>= 3.19.0)
- Visual Studio with "Desktop development with C++" workload

---

## Getting Started (Developers)

### 1. Setup
Verify your system dependencies and fetch Flutter packages:
```bash
# On Linux, this checks for required packages. On other OSes, it just runs pub get.
make setup
```

### 2. Run in Development
Run the app on your desktop.
```bash
make run-linux    # Linux (X11 backend)
make run-macos    # macOS
make run-windows  # Windows
make run          # Lists all options
```

---

## Building

### Release Builds
- **Linux**: `make build-linux` → `app/build/linux/x64/release/bundle/`
- **macOS**: `make build-macos` → `app/build/macos/Build/Products/Release/happening.app`
- **Windows**: `make build-windows` → `app/build/windows/x64/runner/Release/`

### Distribution Packages
- **Linux**: `make dist-linux` → `dist/happening-<ver>-linux-x64.tar.gz`
- **macOS**: `make dist-macos` → `dist/happening-<ver>-macos-<arch>.dmg`
- **Windows**: `make dist-windows` → `dist/happening-<ver>-windows-x64.zip`

---

## Testing & Quality
- **Run unit tests**: `make test`
- **Run integration tests**: `make integration-test-linux`, `make integration-test-macos`, or `make integration-test-windows`
- **Static analysis**: `make analyze`
- **Format code**: `make format`

---

## Architecture Overview
- **Framework**: Flutter (Desktop)
- **Window Management**: `window_manager` for frameless, always-on-top behavior.
- **Rendering**: `CustomPainter` for the proportional timeline (1 pixel = N seconds).
- **State Management**: `StreamBuilder` driven by a 1Hz clock tick for smooth real-time animation.
- **Data**: Google Calendar API v3 via `googleapis`.
