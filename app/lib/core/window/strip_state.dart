// The three — and only three — states of the timeline strip window.
//
// TLDR:
// Overview: Single source of truth for the strip's logical state. Geometry,
//           position, and platform reservation are a pure function of this.
// Problem: Visibility/sizing was established by several overlapping,
//          order-dependent paths (init focus-dance, hide/show, expand/collapse)
//          each special-casing geometry — the "1px sliver" bug class.
// Solution: Collapse every path onto one enum. `WindowService.applyState(s)`
//           maps a state to geometry + reservation, idempotently.
// Breaking Changes: No.
//
// There is intentionally no "expanded + hidden" — hiding always collapses first.

/// The logical state of the timeline strip window. Model state (owned by
/// `StripController`); the widget renders it, the OS layer applies it.
enum StripState {
  /// Full-width strip, collapsed height, visible. The correct initial state.
  collapsedShown,

  /// Full-width strip, expanded height (hover card / settings), visible.
  expandedShown,

  /// Mini pill, collapsed height. Reservation released.
  hidden;

  /// Whether the strip is visible (full-width) in this state.
  bool get isShown => this != StripState.hidden;

  /// Whether the strip is at expanded height in this state.
  bool get isExpanded => this == StripState.expandedShown;
}
