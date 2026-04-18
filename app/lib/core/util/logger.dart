import 'dart:io';
import 'package:flutter/foundation.dart';

enum LogLevel { debug, info, warn }

/// Simple file-based logger for debugging startup and race conditions.
class AppLogger {
  static File? _logFile;

  /// Minimum level to emit. Set to [LogLevel.debug] for verbose output,
  /// [LogLevel.info] for normal operation.
  static LogLevel level = kDebugMode ? LogLevel.debug : LogLevel.info;

  /// Initializes the logger with a file in the given directory.
  static Future<void> initialize(Directory directory) async {
    if (!directory.existsSync()) {
      await directory.create(recursive: true);
    }
    _logFile = File('${directory.path}/debug.log');
    await _write('--- APP STARTUP ---');
  }

  static Future<void> debug(String message) => _emit(LogLevel.debug, message);
  static Future<void> log(String message) => _emit(LogLevel.info, message);
  static Future<void> warn(String message) => _emit(LogLevel.warn, message);

  static Future<void> _emit(LogLevel msgLevel, String message) async {
    if (msgLevel.index < level.index) return;
    final prefix = msgLevel == LogLevel.debug
        ? '[DBG]'
        : msgLevel == LogLevel.warn
            ? '[WRN]'
            : '';
    await _write(prefix.isEmpty ? message : '$prefix $message');
  }

  static Future<void> _write(String message) async {
    final line = '[${DateTime.now().toIso8601String()}] $message';
    debugPrint(line);
    try {
      await _logFile?.writeAsString('$line\n',
          mode: FileMode.append, flush: true);
    } catch (e) {
      debugPrint('Logging to file failed: $e');
    }
  }
}
