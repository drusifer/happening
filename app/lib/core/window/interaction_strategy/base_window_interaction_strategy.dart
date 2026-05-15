import 'dart:io';

import 'package:happening/core/settings/settings_service.dart';
import 'package:logging/logging.dart';
import 'package:window_manager/window_manager.dart';

import 'window_interaction_strategy.dart';

abstract class BaseWindowInteractionStrategy extends WindowInteractionStrategy {
  BaseWindowInteractionStrategy({required WindowManager wm}) : _wm = wm;

  final WindowManager _wm;
  static final _log = Logger('WindowInteractionStrategy');

  @override
  Future<void> initialize(WindowMode mode) async {}

  @override
  Future<void> sendToBack() async {
    // Capture focused window ID before blur transfers focus away.
    String? xWid;
    if (Platform.isLinux) {
      try {
        final r = await Process.run('xdotool', ['getactivewindow']);
        xWid = r.stdout.toString().trim();
        _log.fine('sendToBack: active wid=$xWid exit=${r.exitCode}');
      } catch (e) {
        _log.fine('sendToBack: xdotool getactivewindow failed: $e');
      }
    }

    await _wm.setAlwaysOnTop(false);
    await _wm.blur();

    if (xWid != null && xWid.isNotEmpty) {
      try {
        // XLowerWindow via ctypes — no external tool dependency, libX11 always present.
        const script =
            "import ctypes,sys;"
            "l=ctypes.CDLL('libX11.so.6');"
            "l.XOpenDisplay.restype=ctypes.c_void_p;"
            "d=l.XOpenDisplay(None);"
            "l.XLowerWindow(d,ctypes.c_ulong(int(sys.argv[1])));"
            "l.XFlush(d);"
            "l.XCloseDisplay(d)";
        final r = await Process.run('python3', ['-c', script, xWid]);
        _log.fine('sendToBack: XLowerWindow wid=$xWid exit=${r.exitCode} err=${r.stderr}');
      } catch (e) {
        _log.fine('sendToBack: XLowerWindow failed: $e');
      }
    }
  }

  @override
  Future<void> restoreToFront() async {
    await _wm.setAlwaysOnTop(true);
  }
}
