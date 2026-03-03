import 'dart:io';
import 'package:flutter/foundation.dart';

/// Simple file-based logger for debugging startup and race conditions.
class AppLogger {
  static File? _logFile;

  /// Initializes the logger with a file in the given directory.
  static Future<void> initialize(Directory directory) async {
    if (!directory.existsSync()) {
      await directory.create(recursive: true);
    }
    _logFile = File('${directory.path}/debug.log');

    // Clear log on fresh startup to keep it readable,
    // or keep it if you want persistence across multiple runs.
    // For now, let's append but add a clear marker.
    await log('--- APP STARTUP ---');
  }

  /// Logs a message with a timestamp to the debug log file and console.
  static Future<void> log(String message) async {
    final timestamp = DateTime.now().toIso8601String();
    final logLine = '[$timestamp] $message';

    // Console output
    debugPrint(logLine);

    // File output
    try {
      if (_logFile != null) {
        await _logFile!
            .writeAsString('$logLine\n', mode: FileMode.append, flush: true);
      }
    } catch (e) {
      // Don't let logging failures crash the app
      debugPrint('Logging to file failed: $e');
    }
  }
}
