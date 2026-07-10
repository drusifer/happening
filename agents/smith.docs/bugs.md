# Judge Bugs — session tool/skill usage — 2026-07-08

Cataloged from `agents/trin.docs/judge_bob-protocol_trace.log` (scope broadened to full-session
tool/skill usage per Drew's direction).

## BUG-1 (code): `agents/tools/session_trace.py` false negative — FIXED 2026-07-08
Neo added Claude Code harness support (`~/.claude/projects/<cwd>/*.jsonl`, tool_use/tool_result
schema matched by `tool_use_id`) alongside the existing Antigravity path, with explicit
per-harness "Found N \<harness\> transcript file(s)" reporting instead of a silent single count.
Verified: `python3 agents/tools/session_trace.py --conv-id e49961cd-...` now correctly reports
all 10 real `via` queries from this session (previously: 0, false negative).

- **COMMAND**: `python3 agents/tools/session_trace.py`
- **EXPECTED**: Report on `via` queries made in the current session, or clearly report "not
  applicable to this harness."
- **ACTUAL**: Silently reports "No via queries found" — while having found 16 transcript files
  under a hardcoded `~/.gemini/antigravity-cli` path (a different AI harness, "Antigravity"/Gemini
  CLI). It never looks at Claude Code's session data at all. This session made several real
  `via_query`/`via_ask` calls today, so the true count is nonzero.
- **VERDICT**: Fail. This is a false negative, worse than an error — a future judge run trusting
  this tool's output would wrongly conclude `via` is unused in a Claude-Code-run session and
  deprioritize investment in it.
- **ROUTE**: Neo (code bug — `locate_transcripts()` needs harness detection or a
  `--transcript-dir` override; also worth widening scope beyond `via`-only if this is meant to be
  the judge loop's general trace tool, since Trin's Step 1 instructions ask for "session history,
  commands run, output size" broadly, not `via` alone).

## BUG-2 (prompt/skill): `agents/neo.docs/SKILL.md` is a stale Python/pytest template
- **EXPECTED**: Neo's persona doc reflects the project's actual stack (Dart/Flutter — confirmed
  100% of this repo's app code) so a cold-started agent knows to run `flutter test`/`dart
  format`/`dart_code_linter` rather than guessing.
- **ACTUAL**: SKILL.md says "Languages: Python (Primary)", documents `*swe test` via `pytest`,
  references `make coverage` — none of which exist/apply in this repo. Today's session only
  avoided failure because of context accumulated earlier in the same conversation, not because
  the persona doc said the right thing.
- **VERDICT**: Fail (latent) — a genuinely cold Neo start following this doc literally would try
  `pytest` against a Flutter project.
- **ROUTE**: Bob (prompt/skill update — rewrite the Technical Profile /Running Tests / Code
  Quality sections to the Dart/Flutter toolchain actually documented in `feedback_make_skill.md`
  auto-memory and used throughout this session: `make test`, `make lint`, `dart format`).

## BUG-3 (prompt/skill): bob-protocol ENTRY has no relevance-scoping for state files
- **EXPECTED**: A persona switch loads only the state relevant to the incoming task, or at least
  flags "this file is dominated by an unrelated prior workstream, skim/skip."
- **ACTUAL**: `neo.docs/current_task.md` (360 lines) and `context.md` (80 lines) are almost
  entirely F-31 window-subsystem history with zero bearing on a lint-fixing task. The ENTRY
  protocol has no mechanism to signal "this doc is stale/off-topic for what you're about to do."
- **VERDICT**: Concern (not a hard failure — task still succeeded) — but a real, recurring token
  cost every time a persona's most recent prior work differs from the incoming task.
- **ROUTE**: Bob (prompt/skill update — either add a "trim/archive completed workstreams" step to
  the EXIT hard gate so `current_task.md` doesn't grow unbounded, or add explicit ENTRY guidance:
  "skim for a status header matching the incoming task before reading the full file").

## BUG-4 (prompt/skill): `make chat`'s 256-char limit has no proactive guard
- **EXPECTED**: Either the skill/tool warns before drafting a long message, or `make chat` offers
  a clear one-step recovery (e.g. auto-suggest the docs-file pattern) rather than a hard fail
  requiring a second manual attempt.
- **ACTUAL**: Hit twice this session. The correct workaround ("draft ≤230, count first, or write
  to `.docs/*.md` + short pointer") already exists as a *lesson learned* buried in
  `neo.docs/context.md`, not in `agents/skills/chat/SKILL.md` where every persona would see it
  regardless of whose state they're reading.
- **VERDICT**: Concern — avoidable friction, minor token cost (one failed call each time), but
  purely a documentation-placement issue, not a code bug.
- **ROUTE**: Bob (move/duplicate the char-limit guidance into `agents/skills/chat/SKILL.md`
  itself).

## Follow-up (addressed after loop closure, 2026-07-08)
- **Agent/Explore duplication** — not a BobProtocol persona defect (it happened before any
  persona switch, in direct tool usage), so the fix doesn't belong in `agents/*.docs/`. Instead
  recorded as a feedback memory in Claude's own persistent memory system:
  `feedback_agent_dispatch_duplication.md` — wait for a dispatched agent's result before
  independently re-reading the same files; spot-check specific claims for verification rather
  than a full re-derivation.

## Not scored (informational only, outside this judge loop's target)
- **Git auto-commit mid-session** (commit `6b09cd9` appeared without this session running `git
  commit`) forced a `git stash`/conflict-resolve/`pop` recovery. Handled correctly, no data lost —
  but flags a possible external hook race condition. Infra concern for Morpheus, not a
  prompt/skill/tool-usage defect to score here.
