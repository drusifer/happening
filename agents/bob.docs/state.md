# Bob Agent State — Protocol Initialization

## Context
- Initialized Bob Protocol on Linux (`/var/home/drusifer/Projects/happening`).
- Ran `bobp setup-agent-links`: 9 personas, 15 shared skills, `via` index and MCP integration verified (`via: enabled` in `agents/PROJECT.md`).
- Reviewed `agents/CHAT.md`, `agents/neo.docs/state.md`, and `task.md`:
  - **Linux Send-to-Back & Hide/Show (`*fix` loop, Neo)**:
    - Linux reservation strut fix (`(baseTop + collapsedHeight) * dpr`) confirmed working by Drew.
    - Send-to-back is **blocked** awaiting Drew's decision: `xdotool getactivewindow` picks the wrong X11 window under Wayland+XWayland. Neo recommends replacing `xdotool` with `windowManager.setAlwaysOnBottom(true/false)` (requires amending DEC-011) or using `xdotool search --pid`.
    - Hide/show two-step visual band on Linux diagnosed (window shrinks/releases strut after 300ms animation); awaiting Drew's OK before changing sequence.
  - **Sprint F-33 (Countdown Swing)**:
    - Planned and approved in [task.md](task.md); Phase A (`F33-A1: CountdownSwing` TDD) is `⏳ TODO` for `@Neo`.
  - **Git working tree**:
    - Uncommitted modifications in `app/pubspec.yaml` (`window_manager: ^0.7.0`, `screen_retriever: ^0.4.0`) and `app/pubspec.lock`, plus untracked `dist/`.

## Current Task
**Status:** Initialized / Standby
**Assigned to:** Bob (Coordinator)
**Started:** 2026-11-12T11:14:00-05:00

### Task Description
Cold-start initialization of Bob Protocol and state reconciliation across personas.

### Progress
- [x] Logged user `/bob-protocol init` request to `agents/CHAT.md`
- [x] Read recent `agents/CHAT.md` history and persona state files
- [x] Synced agent links and verified `via` MCP setup via `bobp setup-agent-links`
- [x] Posted initialization status to `agents/CHAT.md`

## Next Steps
### Immediate Next Action
Await user direction on which task/persona to resume:
1. Resolve `@Neo`'s Linux send-to-back blocker (`windowManager.setAlwaysOnBottom` vs `xdotool search --pid`) and Linux hide/show ordering.
2. Start Sprint F-33 Phase A (`@Neo *swe impl F33-A1`).
3. Or pick up another command.

---
*Last updated: 2026-11-12T11:15:00-05:00*
