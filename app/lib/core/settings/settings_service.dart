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

/// Supported font sizes for event labels.
enum FontSize {
  small(9),
  medium(11),
  large(13);

  const FontSize(this.px);
  final double px;

  static FontSize fromString(String val) => FontSize.values
      .firstWhere((e) => e.name == val, orElse: () => FontSize.medium);
}

/// App-wide settings model.
class AppSettings {
  const AppSettings({this.fontSize = FontSize.medium});

  final FontSize fontSize;

  Map<String, dynamic> toJson() => {'fontSize': fontSize.name};

  factory AppSettings.fromJson(Map<String, dynamic> json) => AppSettings(
        fontSize: FontSize.fromString(json['fontSize'] as String? ?? 'medium'),
      );
}

/// Manages the loading, saving, and notification of application settings.
class SettingsService {
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
    _controller.add(_current);
  }

  /// Updates settings and saves to disk.
  Future<void> update(AppSettings newSettings) async {
    _current = newSettings;
    _controller.add(_current);
    try {
      if (!_file.parent.existsSync()) {
        await _file.parent.create(recursive: true);
      }
      // ignore: discarded_futures
      unawaited(_file.writeAsString(jsonEncode(_current.toJson())));
    } catch (_) {
      // Error saving settings — not fatal, current session stays updated.
    }
  }

  void dispose() {
    unawaited(_controller.close());
  }
}
