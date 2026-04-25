import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:happening/core/settings/settings_service.dart';
import 'package:happening/core/window/window_service.dart';

class TimelineFocusController extends ChangeNotifier {
  TimelineFocusController({
    required WindowService windowService,
    required WindowMode initialWindowMode,
    this.inactivityTimeout = const Duration(seconds: 8),
  })  : _windowService = windowService,
        _windowMode = initialWindowMode,
        _isFocused = initialWindowMode != WindowMode.transparent {
    isFocusedNotifier.value = _isFocused;
  }

  final WindowService _windowService;
  final Duration inactivityTimeout;

  final ValueNotifier<bool> isFocusedNotifier = ValueNotifier<bool>(false);

  WindowMode _windowMode;
  Timer? _inactivityTimer;
  bool _isFocused;
  bool _isInteractionHeld = false;

  bool get isFocused => _isFocused;
  WindowMode get windowMode => _windowMode;
  bool get usesTransparentFocusModel => _windowMode == WindowMode.transparent;

  Future<void> initialize() async {
    if (usesTransparentFocusModel) {
      await _enterIdleTransparentState();
      return;
    }
    await _enterInteractiveState(startTimer: false);
  }

  Future<void> setWindowMode(WindowMode mode) async {
    if (_windowMode == mode) return;
    _windowMode = mode;
    await _windowService.setWindowMode(mode);

    if (usesTransparentFocusModel) {
      await _enterIdleTransparentState();
    } else {
      await _enterInteractiveState(startTimer: false);
    }
  }

  Future<void> focus() async {
    if (!usesTransparentFocusModel) {
      await _enterInteractiveState(startTimer: false);
      return;
    }
    await _enterInteractiveState(startTimer: true);
  }

  Future<void> unfocus() async {
    if (!usesTransparentFocusModel) return;
    await _enterIdleTransparentState();
  }

  Future<void> handleEscape() async {
    if (!_isFocused || !usesTransparentFocusModel) return;
    await unfocus();
  }

  Future<void> handleWindowFocusLost() async {
    if (!usesTransparentFocusModel) return;
    await unfocus();
  }

  void registerUserActivity() {
    if (!_isFocused || !usesTransparentFocusModel || _isInteractionHeld) return;
    _restartInactivityTimer();
  }

  void setInteractionHold(bool held) {
    _isInteractionHeld = held;
    if (!_isFocused || !usesTransparentFocusModel) return;

    if (held) {
      _cancelInactivityTimer();
    } else {
      _restartInactivityTimer();
    }
  }

  Future<void> _enterInteractiveState({required bool startTimer}) async {
    _setFocused(true);
    await _windowService.setInteractionFocused(true);
    await _windowService.setPassThroughEnabled(false);
    if (startTimer && !_isInteractionHeld) {
      _restartInactivityTimer();
    } else {
      _cancelInactivityTimer();
    }
  }

  Future<void> _enterIdleTransparentState() async {
    _cancelInactivityTimer();
    _setFocused(false);
    await _windowService.setInteractionFocused(false);
    await _windowService.setPassThroughEnabled(true);
  }

  void _restartInactivityTimer() {
    _cancelInactivityTimer();
    _inactivityTimer = Timer(inactivityTimeout, () {
      unawaited(unfocus());
    });
  }

  void _cancelInactivityTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = null;
  }

  void _setFocused(bool focused) {
    if (_isFocused == focused && isFocusedNotifier.value == focused) return;
    _isFocused = focused;
    isFocusedNotifier.value = focused;
    notifyListeners();
  }

  @override
  void dispose() {
    _cancelInactivityTimer();
    isFocusedNotifier.dispose();
    super.dispose();
  }
}
