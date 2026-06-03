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
import 'package:happening/core/astro/astro_settings.dart';
import 'package:happening/core/display/persisted_display_choice.dart';

const double kMinFontSizePx = 11.0;
const double kMaxFontSizePx = 22.0;
const double kDefaultFontSizePx = 15.0;

double _clampFontSizePx(double v) => v.clamp(kMinFontSizePx, kMaxFontSizePx);

// Maps legacy enum names to their pixel values for backward-compat migration.
double _legacyFontSizeFromName(String name) => switch (name) {
      'small' => 13.0,
      'large' => 17.0,
      _ => kDefaultFontSizePx,
    };

/// Supported application themes.
enum AppTheme {
  dark,
  light,
  system,
  astronomical;

  static AppTheme fromString(String val) => AppTheme.values
      .firstWhere((e) => e.name == val, orElse: () => AppTheme.dark);
}

/// Persisted window interaction mode preference.
enum WindowMode {
  overlay,
  reserved;

  static WindowMode fromString(String val) {
    if (val == 'transparent') return WindowMode.overlay;
    return WindowMode.values
        .firstWhere((e) => e.name == val, orElse: () => WindowMode.reserved);
  }
}

const double kMinIdleTimelineOpacity = 0.2;
const double kMaxIdleTimelineOpacity = 1.0;

double _clampIdleTimelineOpacity(double value) {
  return value.clamp(kMinIdleTimelineOpacity, kMaxIdleTimelineOpacity);
}

/// App-wide settings model.
class AppSettings {
  const AppSettings({
    this.fontSizePx = kDefaultFontSizePx,
    this.theme = AppTheme.dark,
    this.timeWindowHours = 8,
    this.selectedCalendarIds = const [],
    this.windowMode = WindowMode.reserved,
    this.idleTimelineOpacity = 1.0,
    this.astroSettings = const AstroSettings(),
    this.chosenDisplay,
  });

  final double fontSizePx;
  final AppTheme theme;
  final int timeWindowHours;
  final List<String> selectedCalendarIds;
  final WindowMode windowMode;
  final double idleTimelineOpacity;
  final AstroSettings astroSettings;
  final PersistedDisplayChoice? chosenDisplay;

  /// Effective mode after platform reliability rules are applied.
  WindowMode get effectiveWindowMode => WindowMode.reserved;

  AppSettings copyWith({
    double? fontSizePx,
    AppTheme? theme,
    int? timeWindowHours,
    List<String>? selectedCalendarIds,
    WindowMode? windowMode,
    double? idleTimelineOpacity,
    AstroSettings? astroSettings,
    PersistedDisplayChoice? chosenDisplay,
    bool clearChosenDisplay = false,
  }) {
    return AppSettings(
      fontSizePx: fontSizePx ?? this.fontSizePx,
      theme: theme ?? this.theme,
      timeWindowHours: timeWindowHours ?? this.timeWindowHours,
      selectedCalendarIds: selectedCalendarIds ?? this.selectedCalendarIds,
      windowMode: windowMode ?? this.windowMode,
      idleTimelineOpacity: idleTimelineOpacity ?? this.idleTimelineOpacity,
      astroSettings: astroSettings ?? this.astroSettings,
      chosenDisplay:
          clearChosenDisplay ? null : (chosenDisplay ?? this.chosenDisplay),
    );
  }

  Map<String, dynamic> toJson() => {
        'fontSizePx': fontSizePx,
        'theme': theme.name,
        'timeWindowHours': timeWindowHours,
        'selectedCalendarIds': selectedCalendarIds,
        'windowMode': windowMode.name,
        'idleTimelineOpacity': idleTimelineOpacity,
        'astroSettings': astroSettings.toJson(),
        if (chosenDisplay != null) 'chosenDisplay': chosenDisplay!.toJson(),
      };

  factory AppSettings.fromJson(Map<String, dynamic> json) => AppSettings(
        fontSizePx: _clampFontSizePx(
          json['fontSizePx'] is num
              ? (json['fontSizePx'] as num).toDouble()
              : _legacyFontSizeFromName(json['fontSize'] as String? ?? ''),
        ),
        theme: AppTheme.fromString(json['theme'] as String? ?? 'dark'),
        timeWindowHours: (json['timeWindowHours'] as num? ?? 8).toInt(),
        selectedCalendarIds: (json['selectedCalendarIds'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
        windowMode:
            WindowMode.fromString(json['windowMode'] as String? ?? 'reserved'),
        idleTimelineOpacity: _clampIdleTimelineOpacity(
          (json['idleTimelineOpacity'] as num? ?? 1.0).toDouble(),
        ),
        astroSettings: json['astroSettings'] is Map<String, dynamic>
            ? AstroSettings.fromJson(
                json['astroSettings'] as Map<String, dynamic>)
            : const AstroSettings(),
        chosenDisplay: json['chosenDisplay'] is Map<String, dynamic>
            ? PersistedDisplayChoice.fromJson(
                json['chosenDisplay'] as Map<String, dynamic>)
            : null,
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
