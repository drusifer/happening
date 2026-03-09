# Happening Project Memory

## Project Overview
Flutter desktop app (Linux/macOS/Windows) — a top-of-screen calendar strip that shows hovercards and a settings panel when expanded.

## Key Files
- `app/lib/core/window/window_service.dart` — window resize logic (expand/collapse)
- `app/lib/features/timeline/timeline_strip.dart` — main UI, hover/mouse logic
- `app/linux/runner/my_application.cc` — GTK native setup (X11 strut, dock type)
- `app/lib/main.dart` — entry point
- `~/.config/happening/debug.log` — runtime log file

## Linux GTK Window Resize Behavior (CRITICAL)
`setResizable(false)` is called during init. This means:
- `setSize()` is **silently ignored** by GTK — never changes the actual window size
- `setMaximumSize(x)` causes GTK to snap to its "natural height" (~200px) if x > natural
- `setMinimumSize(x)` is the **actual resize mechanism** — forces the window to x

### Correct Linux expand order (setSize first):
```dart
if (Platform.isLinux) {
  await _wm.setSize(size);        // no-op but harmless — avoids 200px intermediate
  await _wm.setMinimumSize(size); // actual resize: direct 50→240, clean Flutter notification
  await _wm.setMaximumSize(size); // lock
}
```
Using Windows order (setMaximumSize first) causes a two-step resize (50→200→240).
The 200→240 step does NOT reliably notify Flutter's viewport on 2nd+ expand,
leaving maxHeight stuck at 200 and the hovercard/settings area blank.

### Correct Linux collapse order (current, works):
```dart
setSize(size);        // ignored
setMinimumSize(size); // lowers min
setMaximumSize(size); // forces shrink — only call that actually collapses
```

## Multi-Agent Protocol
Uses BOB_SYSTEM_PROTOCOL — see `agents/bob.docs/BOB_SYSTEM_PROTOCOL.md`.
Chat log: `agents/CHAT.md`. Post via `./agents/tools/chat.py`.
