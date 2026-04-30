# Mouse Context

## Transparent Timestrip Sprint — 2026-04-24
- Sprint planning loop reached Mouse after:
  - Cypher stories
  - Smith Gate 1 approval
  - Morpheus architecture
  - Smith Gate 2 approval
- Root `task.md` now tracks Transparent Timestrip Sprint.
- Sprint has 7 short phases: capability spike, settings foundation, interaction strategy, focus model, visual transparency, settings UI, QA/release gate.
- 2026-04-25 status report: `task.md` shows Phases A-C complete and 8/14 tasks done. Phase C has Trin UAT pass and Morpheus approval in chat. Morpheus handed off Phase D to Neo.
- Direct repository check shows Phase D/F-looking implementation artifacts (`TimelineFocusController`, hotkey file, settings window behavior/opacity controls), but persona state and chat have not formally closed Phase D. Treat as implementation drift until Neo reconciles and Trin verifies.
- Last logged build status is `make build-linux` failure from 2026-04-24 21:28 because `app/pubspec.lock` was missing for `app/.dart_tool/package_config.json`; current filesystem contains both files, so rerun is needed before calling this an active blocker.

## Linux Click-Through Sprint — 2026-04-26
- Planning complete: Cypher stories → Smith Gate 1 → Morpheus arch → Smith Gate 2 → Mouse plan → Morpheus plan approval.
- Arch v1.1 added: `ClickThroughChannel` (abstract) + `NullClickThroughChannel` + `LinuxClickThroughChannel` + `ClickThroughCapability.detect()`. Sprint plan and task.md updated to match.
- 3 phases, 9 tasks. Phase A gated to Neo. No implementation started yet.
- Key Smith notes carried through: `exclusive_zone=0` (not 1) in CT-B2; CT-03 focus-release must be verified in CT-C3 UAT.
- New Dart files for Phase A: `click_through_channel.dart`, `linux_click_through_channel.dart`, `click_through_capability.dart` (all in `app/lib/core/linux/`).

## Linux Wayland Simplification Sprint — 2026-04-25
- Root `task.md` now tracks Linux Wayland Simplification as the active board, preserving Transparent Timestrip as previous board below it.
- Sprint has 4 phases: capability/guardrails, remove native reservation path, product surface/docs, verification gate.
- Morpheus approved the phase breakdown and handed Phase A to Neo.
- Implementation/docs complete through Phase C; Phase D is blocked only for full support claim due Flutter analyzer crash and missing real-session X11/Wayland smoke.

## Sprint 5: Fresh Start — 2026-03-01
- All Groups A through F are COMPLETE and VERIFIED.
- Logic tests: 78 GREEN.
- Golden tests: 5 GREEN (updated for +2pt font and visuals).
- Multi-calendar, Themes, Collision red-outlines, Rainbow countdown flash, and Click-to-Expand are all implemented.
- macOS support scaffolded and configured.
- Ready for v0.2.0 RELEASE.

## SM Protocol
- Keep the board (`task.md`) updated.
- Monitor test coverage and stability.
- Ensure all persona hand-offs are documented in CHAT.md.
