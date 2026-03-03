# Async Architecture: Flutter Window Expand/Collapse

## Correct Pattern: Service Owns State

- `WindowService` is the single source of truth for window geometry
- Widget expresses **desired state** (expand/collapse intent), not OS state
- GTK platform channel is serialized: the **last call sent wins**
- Multiple rapid calls don't stack — the final call determines outcome
- Widget must not mirror OS state in its own bool; that mirror is always stale

## What Neo Over-Engineered

- `_isExpanded` in the widget: wrong layer — belongs in the service
  - Can diverge from OS reality during any async transition
  - Races: expand call in-flight, exit fires, `_isExpanded` still true → collapse skipped
- `_debounceTimer` with 150ms cancel logic: symptom fix, not root fix
  - Adds a second state variable (`_debounceTimer`) that can also be stale
- `if (_isSettingsOpen) return` inside debounce callback: introduces stuck states
  - If settings close while timer is pending, the collapse never fires
- Net result: 3 independent state variables (`_isExpanded`, `_debounceTimer`, `_isSettingsOpen`) that must all agree with OS reality — they won't

## Correct Minimal Architecture

**WindowService (service layer):**
```dart
void expand() {
  if (_currentHeight == _expandedHeight) return; // idempotency here
  _currentHeight = _expandedHeight;
  setSize(width, _expandedHeight);
}
void collapse() {
  if (_currentHeight == _collapsedHeight) return; // idempotency here
  _currentHeight = _collapsedHeight;
  setSize(width, _collapsedHeight);
}
```

**Widget (presentation layer):**
```dart
// _onMouseEnter:
windowService.expand();

// _onMouseExit (with brief delay):
Future.delayed(const Duration(milliseconds: 100), () {
  if (!mounted) return;
  if (!_isSettingsOpen) windowService.collapse();
});

// Settings close callback:
setState(() => _isSettingsOpen = false);
windowService.collapse();
```

- No `_isExpanded` in widget
- `_isSettingsOpen` is UI-only: controls whether collapse fires, nothing more
- No debounce timers, no cancel logic, no early-return guards in callbacks

## Deadlock / Stuck-State Rules

- Never gate a collapse call on the same flag the collapse should clear
- Never return early from a state-clearing callback using potentially-stale state
- Keep timer callbacks to: (1) check `mounted`, (2) check single condition, (3) call service
- If a guard is needed, it belongs in the service — not replicated across widgets
