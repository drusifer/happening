# Task Board — Audio Countdown Timer Sprint (F-32)
**Updated**: 2026-09-30 | **Owner**: @Neo | **QA**: @Trin | **Arch**: @Morpheus | **UX**: @Smith

---

## Sprint Goal
Add audio to the countdown timer using 1980s Asteroid B1 & B2 WAV files (`beat1.wav`, `beat2.wav`).
Start playing alternating beats at 1 minute remaining ($T \le 60\text{s}$), slowly ramping up the rhythm and volume towards zero ("nudge, not startle").

## Source Artifacts
- Stories & Architecture: `docs/sprints/F-32/F32_AUDIO_COUNTDOWN_STORIES_ARCH.md`
- Smith UX Gate Review: `docs/sprints/F-32/gate1_gate2_review_2026-09-30.md`

---

## Phase Board

| Phase | Status | Tasks | Owner |
|-------|--------|-------|-------|
| A — Audio Assets & Package Setup | ✅ COMPLETED | F32-A1, F32-A2 | Neo + Trin |
| B — Audio Service & Ramping Engine | ✅ COMPLETED | F32-B1, F32-B2 | Neo + Trin |
| C — Strip Integration & UAT | ✅ COMPLETED | F32-C1, F32-C2 | Trin + Smith |

---

## Phase A — Audio Assets & Package Setup
**Gate**: Assets copied to `app/assets/audio/`, `audioplayers` registered in `pubspec.yaml`, `make test` green.

### F32-A1: Copy assets and update pubspec.yaml  ✅ DONE
- **Goal**:
  - Copy `beat1.wav` and `beat2.wav` into `app/assets/audio/`.
  - Add `assets/audio/` to `flutter.assets` section in `app/pubspec.yaml`.
  - Add `audioplayers: ^6.1.0` dependency to `app/pubspec.yaml`.
- **Files**: `beat1.wav`, `beat2.wav`, `app/assets/audio/`, `app/pubspec.yaml`
- **Tests**: `flutter pub get` succeeds, assets present in build output.

### F32-A2: AppSettings audio toggle  ✅ DONE
- **Goal**:
  - Add `bool enableAudioCountdown = true` setting to `AppSettings`.
  - Add toggle switch in Settings UI.
- **Files**: `app/lib/core/settings/settings_service.dart`, `app/lib/features/timeline/settings_panel.dart`
- **Tests**: setting persists, toggle updates state.

---

## Phase B — Audio Service & Ramping Engine
**Gate**: Unit tests pass for `CountdownAudioService` volume/rhythm curves and beat alternating logic.

### F32-B1: CountdownAudioService implementation  ✅ DONE
- **Goal**:
  - Create `CountdownAudioService` in `app/lib/core/audio/countdown_audio_service.dart`.
  - Implement beat alternation (`beat1.wav` / `beat2.wav`).
  - Implement volume ramp formula ($0.15 \to 1.0$) and interval acceleration formula ($1.5\text{s} \to 0.12\text{s}$).
  - Implement `start(remainingSeconds)`, `update(remainingSeconds)`, and `stop()`.
- **Files**: `app/lib/core/audio/countdown_audio_service.dart`
- **Tests**: unit tests for volume formula, interval calculation, sequence alternation, and start/stop behavior.

### F32-B2: Timeline Strip integration  ✅ DONE
- **Goal**:
  - Wire `CountdownAudioService` into `_TimelineStripState` / countdown tick listener.
  - Trigger audio update on 1s tick when $T \le 60\text{s}$.
  - Stop audio when $T = 0$, countdown canceled, or strip hidden/closed.
- **Files**: `app/lib/features/timeline/timeline_strip.dart`
- **Tests**: integration test checking service calls during countdown ticks.

---

## Phase C — Strip Integration & UAT
**Gate**: Trin UAT pass, Smith UX pass, all tests green.

### F32-C1: UAT & Edge Cases  ✅ DONE (Trin)
- Verify audio starts smoothly at 60s, ramps up without stutter, stops at 0s.
- Verify opt-out setting silences audio immediately.

### F32-C2: Smith UX Verification  ✅ DONE (Smith)
- Verify "nudge, not startle" audio feel on actual audio output.

### F32-C3: Tap-to-Mute Countdown Audio  ✅ DONE (Neo + Trin + Smith)
- Tap on `CountdownDisplay` silences audio countdown for current meeting target until next meeting start.

