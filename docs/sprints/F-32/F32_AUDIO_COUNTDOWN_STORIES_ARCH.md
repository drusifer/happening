# F-32 Audio Countdown Timer — Stories & Architecture

**Created**: 2026-09-30 | **Authors**: @Cypher & @Morpheus | **Target Version**: 1.5.5

---

## 1. Product Stories & Acceptance Criteria

### Story F32-1: Audio Assets & Player Package Registration
- **User Story**: As a user, I want the Asteroids 1980s B1 and B2 beat audio assets available in the app package so that retro heartbeat-style countdown sounds can play.
- **Acceptance Criteria**:
  - `beat1.wav` and `beat2.wav` are bundled into `app/assets/audio/`.
  - Assets are registered in `app/pubspec.yaml` under `flutter.assets`.
  - `audioplayers` package (or clean platform audio service) is added to `app/pubspec.yaml` dependencies.

### Story F32-2: Countdown Audio Ramping Service
- **User Story**: As a user with time-awareness needs (ADHD nudge), I want the countdown timer audio to start playing at 1 minute remaining, alternating B1/B2 beats, with a soft initial volume and a gradually accelerating rhythm until 0 seconds.
- **Acceptance Criteria**:
  - Audio starts playing when remaining countdown time $T \le 60$ seconds.
  - Beats alternate strictly between `beat1.wav` (B1) and `beat2.wav` (B2).
  - **Rhythm Curve**:
    - $T = 60\text{s}$: interval between beats is $\approx 1.5$ seconds (40 BPM).
    - $T \to 0\text{s}$: interval accelerates smoothly to $\approx 120\text{ms}$ (500 BPM).
  - **Volume Curve**:
    - Starts soft at $T = 60\text{s}$ ($\text{volume} \approx 0.15$) to "nudge, not startle".
    - Gradually increases to $\text{volume} = 1.0$ at $T = 0\text{s}$.
  - Audio immediately stops when the timer reaches 0, is paused, hidden, or reset.
  - An opt-out toggle `enableAudioCountdown` is available in Settings (default: true).

---

## 2. Technical Architecture & Design

### Architecture Overview
1. **`CountdownAudioService`** (`app/lib/core/audio/countdown_audio_service.dart`):
   - Encapsulates `AudioPlayer` instances (pre-loaded source buffers for low-latency playback of B1 and B2).
   - Manages beat timer, volume calculation, and alternating B1/B2 trigger logic.
   - Formula for interval at $t \in [0, 60]$ remaining seconds:
     $$\text{interval}(t) = 0.12 + (1.50 - 0.12) \times \left(\frac{t}{60}\right)^2$$
   - Formula for volume at $t \in [0, 60]$ remaining seconds:
     $$\text{volume}(t) = 0.15 + (1.0 - 0.15) \times \left(1 - \frac{t}{60}\right)$$

2. **Integration Point**:
   - `_TimelineStripState` / `CountdownState`: listens to remaining countdown duration.
   - When remaining seconds $\le 60$, updates `CountdownAudioService.updateCountdown(remainingSeconds)`.
   - When countdown stops or resets, calls `CountdownAudioService.stop()`.

3. **Testing Strategy**:
   - Unit tests for `CountdownAudioService` interval and volume curve math.
   - Mocked audio player tests for alternating B1/B2 beat sequence and start/stop state machine.
