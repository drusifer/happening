// Countdown audio service for playing alternating 1980s Asteroids B1/B2 beats and bangLarge explosion.
//
// TLDR:
// Overview: Plays alternating beat1.wav and beat2.wav when countdown <= 60s, and bangLarge.wav at 0s.
// Problem: Need subtle time awareness cue ("nudge, not startle") with clean polyphonic sound layering.
// Solution: Uses an 8-player round-robin AudioPlayer pool so fast beats overlap smoothly without clipping, ending with bangLarge.wav at 0s.
// Breaking Changes: No.
// ---------------------------------------------------------------------------

import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// Pure math helpers for rhythm and volume curves.
class CountdownAudioMath {
  /// Calculate beat interval in seconds based on remaining seconds t in [0, 60].
  static double calculateIntervalSeconds(double t) {
    final remaining = t.clamp(0.0, 60.0);
    final progress = (60.0 - remaining) / 60.0; // 0.0 at 60s, 1.0 at 0s
    // Quadratic acceleration: starts at 1.5s interval, accelerates to 0.12s interval
    return 1.5 - 1.38 * (progress * progress);
  }

  /// Calculate volume in [0.0, 1.0] based on remaining seconds t in [0, 60].
  static double calculateVolume(double t) {
    final remaining = t.clamp(0.0, 60.0);
    final progress = (60.0 - remaining) / 60.0; // 0.0 at 60s, 1.0 at 0s
    // Linear volume ramp: starts soft at 0.15, rises to 1.0 at 0s
    return 0.15 + 0.85 * progress;
  }
}

/// Service that schedules alternating B1 / B2 audio beats during countdown and plays bangLarge at 0s.
class CountdownAudioService {
  CountdownAudioService({
    List<AudioPlayer>? playerPool,
    AudioPlayer? player,
    AudioPlayer? player2,
  }) : _playerPool = playerPool ??
            (player != null
                ? [player, if (player2 != null && player2 != player) player2]
                : List.generate(8, (_) => AudioPlayer()));

  final List<AudioPlayer> _playerPool;
  int _poolIndex = 0;
  Timer? _beatTimer;

  int _remainingSeconds = 60;
  bool _isPlaying = false;
  bool _hasPlayedBang = false;
  int _nextBeatIndex = 0; // 0 for beat1, 1 for beat2

  static const String assetBeat1 = 'audio/beat1.wav';
  static const String assetBeat2 = 'audio/beat2.wav';
  static const String assetBang = 'audio/bangLarge.wav';

  bool get isPlaying => _isPlaying;
  bool get hasPlayedBang => _hasPlayedBang;
  int get remainingSeconds => _remainingSeconds;
  int get nextBeatIndex => _nextBeatIndex;

  AudioPlayer _getNextPlayer() {
    final p = _playerPool[_poolIndex];
    _poolIndex = (_poolIndex + 1) % _playerPool.length;
    return p;
  }

  /// Update the remaining countdown duration and enabled state.
  void updateRemainingSeconds(int seconds, {bool enabled = true}) {
    if (!enabled || seconds > 60) {
      stop();
      return;
    }

    if (seconds <= 0) {
      if (_isPlaying || !_hasPlayedBang) {
        unawaited(_playBang());
      }
      stop();
      return;
    }

    _hasPlayedBang = false;
    _remainingSeconds = seconds;

    if (!_isPlaying) {
      _isPlaying = true;
      _nextBeatIndex = 0;
      _scheduleNextBeat();
    }
  }

  void _scheduleNextBeat() {
    _beatTimer?.cancel();
    if (!_isPlaying || _remainingSeconds <= 0 || _remainingSeconds > 60) {
      _isPlaying = false;
      return;
    }

    unawaited(_playCurrentBeat());

    final intervalSec = CountdownAudioMath.calculateIntervalSeconds(
      _remainingSeconds.toDouble(),
    );
    final intervalMs = (intervalSec * 1000).round();

    _beatTimer = Timer(Duration(milliseconds: intervalMs), () {
      if (_isPlaying) {
        _scheduleNextBeat();
      }
    });
  }

  Future<void> _playCurrentBeat() async {
    try {
      final vol = CountdownAudioMath.calculateVolume(
        _remainingSeconds.toDouble(),
      );
      final asset = _nextBeatIndex == 0 ? assetBeat1 : assetBeat2;
      _nextBeatIndex = (_nextBeatIndex + 1) % 2;

      final player = _getNextPlayer();
      await player.setVolume(vol);
      await player.play(AssetSource(asset));
    } catch (e) {
      debugPrint('CountdownAudioService play error: $e');
    }
  }

  Future<void> _playBang() async {
    _hasPlayedBang = true;
    try {
      final player = _getNextPlayer();
      await player.setVolume(1.0);
      await player.play(AssetSource(assetBang));
    } catch (e) {
      debugPrint('CountdownAudioService bang error: $e');
    }
  }

  /// Stop scheduled beat updates.
  void stop() {
    _beatTimer?.cancel();
    _beatTimer = null;
    _isPlaying = false;
  }

  /// Dispose audio player resources.
  void dispose() {
    stop();
    for (final p in _playerPool) {
      unawaited(p.dispose());
    }
  }
}
