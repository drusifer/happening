import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:happening/core/settings/settings_service.dart';
import 'package:happening/core/window/window_service.dart';

class TimelineFocusController extends ChangeNotifier {
  TimelineFocusController({
    required WindowService windowService,
    this.restoreTimeout = const Duration(seconds: 10),
  }) : _windowService = windowService;

  final WindowService _windowService;
  final Duration restoreTimeout;

  final ValueNotifier<bool> isSentToBackNotifier = ValueNotifier(false);
  Timer? _restoreTimer;

  bool get isSentToBack => isSentToBackNotifier.value;

  Future<void> initialize() async {
    return;
  }

  Future<void> setWindowMode(WindowMode mode) async {
    await _windowService.setWindowMode(mode);
  }

  Future<void> sendToBack() async {
    _restoreTimer?.cancel();
    _restoreTimer = Timer(restoreTimeout, () => unawaited(restoreToFront()));
    isSentToBackNotifier.value = true;
    notifyListeners();
    await _windowService.sendToBack();
  }

  Future<void> restoreToFront() async {
    _restoreTimer?.cancel();
    _restoreTimer = null;
    isSentToBackNotifier.value = false;
    notifyListeners();
    await _windowService.restoreToFront();
  }

  @override
  void dispose() {
    _restoreTimer?.cancel();
    isSentToBackNotifier.dispose();
    super.dispose();
  }
}
