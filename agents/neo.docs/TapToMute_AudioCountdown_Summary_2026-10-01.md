# Tap-to-Mute Audio Countdown Summary — 2026-10-01

## Problem
The user requested that clicking/tapping the countdown timer widget (`CountdownDisplay`) should immediately stop audio countdown beats, and keep audio muted until the *next* meeting start countdown begins.

## Solution
1. **`_TimelineStripState` Mute Tracking**:
   - Added `DateTime? _mutedMeetingStartTime;` field in `_TimelineStripState`.
   - In `_buildCountdownPositioned` and `_buildMiniWidget`, derived:
     `isMutedForCurrentTarget = isTargetingMeetingStart && _mutedMeetingStartTime != null && _mutedMeetingStartTime == tickTarget;`
   - Passed `enabled: settings.enableAudioCountdown && isTargetingMeetingStart && !isMutedForCurrentTarget` to `_audioService.updateRemainingSeconds()`.
2. **Interactive Tap Handler**:
   - Wrapped `CountdownDisplay` in `GestureDetector` with `MouseRegion(cursor: SystemMouseCursors.click)`.
   - When tapped while targeting a meeting start:
     Sets `_mutedMeetingStartTime = tickTarget` and immediately calls `_audioService.stop()`.
   - In mini mode (`_buildMiniWidget`), the tap ALSO invokes `unawaited(_showStrip())` to restore/expand the strip (satisfying `AC-F31-3-2`).
3. **Automatic Unmute on Next Meeting Countdown**:
   - Once the meeting starts or `tickTarget` shifts to the next meeting's start time (`_mutedMeetingStartTime != tickTarget`), `isMutedForCurrentTarget` becomes `false`, so audio countdown automatically resumes for the next meeting.

## Verification
- **Unit & Widget Tests**: Added tap-to-mute test in `timeline_strip_test.dart` asserting that tapping `CountdownDisplay` silences audio for the current meeting start target.
- **Suite**: 519 unit/widget/integration tests green (`+519 ~5 -0`).
- **Analyzer**: 0 issues found across `lib` and `test`.
