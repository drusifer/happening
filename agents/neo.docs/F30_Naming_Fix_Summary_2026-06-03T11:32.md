# F-30 Naming Fix Summary — 2026-06-03T11:32

## Overview
Addressed two user-reported bugs regarding multi-monitor display naming:
1. **Fallback Name Duplication**: Under generic/duplicate OS display ID reporting (common in Linux X11/Wayland where `screen_retriever` returns duplicate ID values like `"0"`), both displays were being labeled with the same fallback index (e.g., both named `"Display 1"`).
2. **Non-contiguous Fallback Indexing**: When a system has a mix of named/usable monitors and unnamed monitors, the unnamed monitors were assigned indices based on their global position (e.g., leaving a gap: `"Dell..."` -> `"Display 2"`), instead of numbering the fallback displays contiguously.

## Implementation Details
- **Unique Stable Fallback Indexing**: Modified `DisplayInfo._stableIndex` within `app/lib/core/display/display_info.dart` to use structural equality comparison (`d == this`) instead of ID comparison (`d.id == id`). Since value equality on `DisplayInfo` compares bounds and sizes (which are physically unique), this ensures that monitors with overlapping OS display IDs resolve to separate stable indices in the sorted monitor list.
- **Contiguous Fallback Numbering**: Updated `DisplayInfo.labelFor()` to build fallback labels (e.g. `"Display N"`) by indexing only within the list of displays that *actually* fall back (i.e. those with generic, connector, or empty OS names, or duplicate OS names), rather than indexing across all connected displays globally.
- **Verification Tests**:
  - Added unit test to `display_info_test.dart` confirming that monitors with duplicate OS-reported IDs (e.g. both ID `"0"`) successfully get assigned distinct numeric labels (`Display 1` and `Display 2`).
  - Added unit test to `display_info_test.dart` asserting that a mixed list of usable monitors (e.g. `"Dell U2723QE"`) and fallback port/generic monitors (e.g. null name, and `"HDMI-1"`) correctly filters and contiguously labels the fallback monitors as `"Display 1"` and `"Display 2"`.
  - Full test suite: **426 passing**, 1 pre-existing failing golden (`hover_card_alignment` golden).
  - Codebase analysis and metrics checks: **Clean (exit 0)**.

## Handoff & Next Steps
- Handed off to **Trin** for final verification and UAT signature.
- Handoff to **Oracle** for F-30 doc updates (USER_GUIDE.md and Release Notes).
