# Morpheus Context

## Sprint 5: fresh start — 2026-03-02
- Sprint 5 v0.2.0 shipped (Multi-cal, Themes, Collision, macOS).
- HOVER_FIX_PLAN.md active: Stabilizing window expansion on Linux.
- DECISION: Extracted `ExpansionBehavior` pure-logic interface to decouple hover state determination from the widget layer.
- Pattern: Stateless calculation based on coordinates and simple flags. No dependencies on Flutter or domain classes.
