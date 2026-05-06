// Global application settings and persistence.
//
// TLDR:
// Overview: Manages font size, themes, and persistence in settings.json.
// Problem: User needs a way to customize the UI and have it persist.
// Solution: Implements SettingsService using File-based storage.
// Breaking Changes: No.
//
// ---------------------------------------------------------------------------

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';

/// Supported font sizes for event labels.
enum FontSize {
  small(13),
  medium(15),
  large(17);

  const FontSize(this.px);
  final double px;

  static FontSize fromString(String val) => FontSize.values
      .firstWhere((e) => e.name == val, orElse: () => FontSize.medium);
}

/// Supported application themes.
enum AppTheme {
  dark,
  light,
  system;

  static AppTheme fromString(String val) => AppTheme.values
      .firstWhere((e) => e.name == val, orElse: () => AppTheme.dark);
}

/// Persisted window interaction mode preference.
enum WindowMode {
  transparent,
  reserved;

  static WindowMode fromString(String val) => WindowMode.values
      .firstWhere((e) => e.name == val, orElse: () => WindowMode.reserved);
}

const double kMinIdleTimelineOpacity = 0.35;
const double kMaxIdleTimelineOpacity = 0.75;

double _clampIdleTimelineOpacity(double value) {
  return value.clamp(kMinIdleTimelineOpacity, kMaxIdleTimelineOpacity);
}

/// App-wide settings model.
class AppSettings {
  const AppSettings({
    this.fontSize = FontSize.medium,
    this.theme = AppTheme.dark,
    this.timeWindowHours = 8,
    this.selectedCalendarIds = const [],
    this.windowMode = WindowMode.reserved,
    this.idleTimelineOpacity = 0.55,
  });

  final FontSize fontSize;
  final AppTheme theme;
  final int timeWindowHours;
  final List<String> selectedCalendarIds;
  final WindowMode windowMode;
  final double idleTimelineOpacity;

  /// Effective mode after platform reliability rules are applied.
  WindowMode effectiveWindowMode(
    TargetPlatform platform, {
    bool linuxTransparentSupported = false,
  }) {
    return WindowMode.reserved;
  }

  AppSettings copyWith({
    FontSize? fontSize,
    AppTheme? theme,
    int? timeWindowHours,
    List<String>? selectedCalendarIds,
    WindowMode? windowMode,
    double? idleTimelineOpacity,
  }) {
    return AppSettings(
      fontSize: fontSize ?? this.fontSize,
      theme: theme ?? this.theme,
      timeWindowHours: timeWindowHours ?? this.timeWindowHours,
      selectedCalendarIds: selectedCalendarIds ?? this.selectedCalendarIds,
      windowMode: windowMode ?? this.windowMode,
      idleTimelineOpacity: idleTimelineOpacity ?? this.idleTimelineOpacity,
    );
  }

  Map<String, dynamic> toJson() => {
        'fontSize': fontSize.name,
        'theme': theme.name,
        'timeWindowHours': timeWindowHours,
        'selectedCalendarIds': selectedCalendarIds,
        'windowMode': windowMode.name,
        'idleTimelineOpacity': idleTimelineOpacity,
      };

  factory AppSettings.fromJson(Map<String, dynamic> json) => AppSettings(
        fontSize: FontSize.fromString(json['fontSize'] as String? ?? 'medium'),
        theme: AppTheme.fromString(json['theme'] as String? ?? 'dark'),
        timeWindowHours: (json['timeWindowHours'] as num? ?? 8).toInt(),
        selectedCalendarIds: (json['selectedCalendarIds'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
        windowMode:
            WindowMode.fromString(json['windowMode'] as String? ?? 'reserved'),
        idleTimelineOpacity: _clampIdleTimelineOpacity(
          (json['idleTimelineOpacity'] as num? ?? 0.55).toDouble(),
        ),
      );
}

/// Manages the loading, saving, and notification of application settings.
class SettingsService extends ChangeNotifier {
  SettingsService({required Directory directory})
      : _file = File('${directory.path}/settings.json'),
        _controller = StreamController<AppSettings>.broadcast();

  final File _file;
  final StreamController<AppSettings> _controller;
  AppSettings _current = const AppSettings();

  /// Stream of setting updates.
  Stream<AppSettings> get settings => _controller.stream;

  /// Current cached settings.
  AppSettings get current => _current;

  /// Loads settings from disk. If no file exists, uses defaults.
  Future<void> load() async {
    try {
      if (_file.existsSync()) {
        final raw = await _file.readAsString();
        _current =
            AppSettings.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      }
    } catch (_) {
      // Fallback to defaults on error.
      _current = const AppSettings();
    }
    notifyListeners();
    _controller.add(_current);
  }

  /// Updates settings and saves to disk.
  Future<void> update(AppSettings newSettings) async {
    _current = newSettings.copyWith(
      idleTimelineOpacity: _clampIdleTimelineOpacity(
        newSettings.idleTimelineOpacity,
      ),
    );
    _controller.add(_current);
    notifyListeners();
    try {
      if (!_file.parent.existsSync()) {
        await _file.parent.create(recursive: true);
      }
      await _file.writeAsString(jsonEncode(_current.toJson()));
    } catch (_) {
      // Error saving settings — not fatal, current session stays updated.
    }
  }

  @override
  void dispose() {
    unawaited(_controller.close());
    super.dispose();
  }
}
