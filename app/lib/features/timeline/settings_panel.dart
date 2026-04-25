// Settings panel popup.
//
// TLDR:
// Overview: A card that shows font size options and a logout button.
// Problem: Need a place for persistent user configuration.
// Solution: Displays a shadow-boxed card with FontSize picker and Logout.
// Breaking Changes: No.
//
// ---------------------------------------------------------------------------

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:happening/core/app_metadata.dart';
import 'package:happening/core/settings/settings_service.dart';
import 'package:happening/features/calendar/calendar_controller.dart';
import 'package:happening/features/calendar/calendar_service.dart';
import 'package:url_launcher/url_launcher.dart';

typedef AboutUrlLauncher = Future<bool> Function(Uri url);

/// Popup panel for app settings (Font size, Logout).
class SettingsPanel extends StatefulWidget {
  const SettingsPanel({
    super.key,
    required this.settingsService,
    required this.calendarController,
    required this.onSignOut,
    this.launchAboutUrl = _launchAboutUrl,
    this.platformOverride,
  });

  final SettingsService settingsService;
  final CalendarController calendarController;
  final VoidCallback onSignOut;
  final AboutUrlLauncher launchAboutUrl;
  final TargetPlatform? platformOverride;

  @override
  State<SettingsPanel> createState() => _SettingsPanelState();
}

class _SettingsPanelState extends State<SettingsPanel> {
  List<CalendarMeta>? _availableCalendars;
  bool _isLoadingCalendars = true;

  @override
  void initState() {
    super.initState();
    unawaited(_loadCalendars());
  }

  Future<void> _loadCalendars() async {
    try {
      final list = await widget.calendarController.service.fetchCalendarList();
      if (!mounted) return;

      // Auto-select the primary calendar the first time (empty selection).
      if (widget.settingsService.current.selectedCalendarIds.isEmpty) {
        final primary = list.firstWhere(
          (c) => c.isPrimary,
          orElse: () => list.first,
        );
        final settings = widget.settingsService.current;
        unawaited(widget.settingsService.update(
          settings.copyWith(selectedCalendarIds: [primary.id]),
        ));
        unawaited(widget.calendarController.refresh());
      }

      setState(() {
        _availableCalendars = list;
        _isLoadingCalendars = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoadingCalendars = false);
    }
  }

  void _toggleCalendar(String id) {
    final settings = widget.settingsService.current;
    final current = List<String>.from(settings.selectedCalendarIds);

    // If list is empty, treat 'primary' as the only selected item.
    if (current.isEmpty) current.add('primary');

    if (current.contains(id)) {
      if (current.length > 1) current.remove(id);
    } else {
      current.add(id);
    }

    unawaited(widget.settingsService.update(
      settings.copyWith(selectedCalendarIds: current),
    ));
    unawaited(widget.calendarController.refresh());
  }

  Future<void> _openAbout() async {
    await widget.launchAboutUrl(Uri.parse(appAboutUrl));
  }

  TargetPlatform get _platform {
    if (widget.platformOverride != null) return widget.platformOverride!;
    if (Platform.isMacOS) return TargetPlatform.macOS;
    if (Platform.isWindows) return TargetPlatform.windows;
    if (Platform.isLinux) return TargetPlatform.linux;
    return TargetPlatform.linux;
  }

  List<WindowMode> get _supportedWindowModes {
    switch (_platform) {
      case TargetPlatform.macOS:
        return const [WindowMode.transparent];
      case TargetPlatform.linux:
        return const [WindowMode.reserved];
      case TargetPlatform.windows:
        return WindowMode.values;
      default:
        return const [WindowMode.reserved];
    }
  }

  String _windowModeLabel(WindowMode mode) {
    switch (mode) {
      case WindowMode.transparent:
        return 'Let clicks pass through';
      case WindowMode.reserved:
        return 'Reserve space at top';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = widget.settingsService.current;
    final baseSize = settings.fontSize.px;
    final scale = baseSize / 15.0; // Normalized to medium=15

    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.brightness == Brightness.dark
              ? const Color(0xFF1A1A2E)
              : Colors.white,
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(8),
            bottomRight: Radius.circular(8),
          ),
          border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
          boxShadow: const [
            BoxShadow(
                color: Colors.black26, blurRadius: 10, offset: Offset(0, 4)),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Left: controls + LOGOUT ──────────────────────────────────
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'SETTINGS  v. $appVersion',
                  style: TextStyle(
                    color: theme.textTheme.bodySmall?.color
                        ?.withValues(alpha: 0.5),
                    fontSize: baseSize * 0.6,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 10),
                _SectionHeader(
                    theme: theme, title: 'Theme', fontSize: baseSize * 0.7),
                const SizedBox(height: 6),
                _PickerRow<AppTheme>(
                  values: AppTheme.values,
                  current: settings.theme,
                  fontSize: baseSize * 0.65,
                  onSelect: (val) =>
                      widget.settingsService.update(settings.copyWith(
                    theme: val,
                  )),
                  labelBuilder: (v) =>
                      v.name[0].toUpperCase() + v.name.substring(1),
                ),
                const SizedBox(height: 10),
                _SectionHeader(
                    theme: theme,
                    title: 'Time Window',
                    fontSize: baseSize * 0.7),
                const SizedBox(height: 6),
                _PickerRow<int>(
                  values: const [8, 12, 24],
                  current: settings.timeWindowHours,
                  fontSize: baseSize * 0.65,
                  onSelect: (val) =>
                      widget.settingsService.update(settings.copyWith(
                    timeWindowHours: val,
                  )),
                  labelBuilder: (v) => '${v}h',
                ),
                const SizedBox(height: 10),
                _SectionHeader(
                    theme: theme,
                    title: 'Window behavior',
                    fontSize: baseSize * 0.7),
                const SizedBox(height: 6),
                _PickerRow<WindowMode>(
                  values: _supportedWindowModes,
                  current: settings.effectiveWindowMode(_platform),
                  fontSize: baseSize * 0.65,
                  onSelect: (val) =>
                      widget.settingsService.update(settings.copyWith(
                    windowMode: val,
                  )),
                  labelBuilder: _windowModeLabel,
                ),
                const Spacer(),
                _MiniButton(
                  label: 'LOGOUT',
                  onTap: widget.onSignOut,
                  color: Colors.redAccent.withValues(alpha: 0.15),
                  textColor: Colors.redAccent.withValues(alpha: 0.8),
                  fontSize: baseSize * 0.55,
                ),
              ],
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 12),
              width: 1,
              color: theme.dividerColor.withValues(alpha: 0.1),
            ),
            // ── Middle: Font Size ────────────────────────────────────────
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _SectionHeader(
                    theme: theme, title: 'Font Size', fontSize: baseSize * 0.7),
                const SizedBox(height: 6),
                _PickerRow<FontSize>(
                  values: FontSize.values,
                  current: settings.fontSize,
                  fontSize: baseSize * 0.65,
                  onSelect: (val) =>
                      widget.settingsService.update(settings.copyWith(
                    fontSize: val,
                  )),
                  labelBuilder: (v) =>
                      v.name[0].toUpperCase() + v.name.substring(1),
                ),
                const SizedBox(height: 10),
                _SectionHeader(
                    theme: theme,
                    title: 'Transparency',
                    fontSize: baseSize * 0.7),
                const SizedBox(height: 6),
                SizedBox(
                  width: 220 * scale,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Slider(
                        value: settings.idleTimelineOpacity,
                        min: kMinIdleTimelineOpacity,
                        max: kMaxIdleTimelineOpacity,
                        divisions: 8,
                        label:
                            '${(settings.idleTimelineOpacity * 100).round()}%',
                        onChanged: (value) => widget.settingsService.update(
                          settings.copyWith(idleTimelineOpacity: value),
                        ),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: _SliderLabel(
                                label: 'More visible',
                                fontSize: baseSize * 0.55,
                                textAlign: TextAlign.left,
                              ),
                            ),
                          ),
                          Expanded(
                            child: _SliderLabel(
                              label: 'Balanced',
                              fontSize: baseSize * 0.55,
                              textAlign: TextAlign.center,
                            ),
                          ),
                          Expanded(
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: _SliderLabel(
                                label: 'More transparent',
                                fontSize: baseSize * 0.55,
                                textAlign: TextAlign.right,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                _TextLink(
                  label: 'ABOUT',
                  onTap: () => unawaited(_openAbout()),
                  fontSize: baseSize * 0.55,
                ),
              ],
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 12),
              width: 1,
              color: theme.dividerColor.withValues(alpha: 0.1),
            ),
            // ── Right: Calendars spanning full height ────────────────────
            SizedBox(
              width: 180 * scale,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionHeader(
                      theme: theme,
                      title: 'Calendars',
                      fontSize: baseSize * 0.7),
                  const SizedBox(height: 8),
                  Expanded(
                    child: _isLoadingCalendars
                        ? const Center(
                            child: SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : ListView.separated(
                            itemCount: _availableCalendars?.length ?? 0,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 4),
                            itemBuilder: (context, index) {
                              final cal = _availableCalendars![index];
                              final isSelected =
                                  settings.selectedCalendarIds.isEmpty
                                      ? cal.id == 'primary'
                                      : settings.selectedCalendarIds
                                          .contains(cal.id);
                              return GestureDetector(
                                onTap: () => _toggleCalendar(cal.id),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? cal.color.withValues(alpha: 0.2)
                                        : theme.dividerColor
                                            .withValues(alpha: 0.05),
                                    borderRadius: BorderRadius.circular(4),
                                    border: isSelected
                                        ? Border.all(
                                            color: cal.color
                                                .withValues(alpha: 0.4))
                                        : null,
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 8 * scale,
                                        height: 8 * scale,
                                        decoration: BoxDecoration(
                                            color: cal.color,
                                            shape: BoxShape.circle),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          cal.summary,
                                          style: TextStyle(
                                            color: theme
                                                .textTheme.bodyMedium?.color
                                                ?.withValues(
                                                    alpha:
                                                        isSelected ? 1.0 : 0.6),
                                            fontSize: baseSize * 0.65,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (isSelected)
                                        Icon(Icons.check,
                                            size: baseSize * 0.65,
                                            color: theme.colorScheme.primary),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SliderLabel extends StatelessWidget {
  const _SliderLabel({
    required this.label,
    required this.fontSize,
    required this.textAlign,
  });

  final String label;
  final double fontSize;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      label,
      textAlign: textAlign,
      style: TextStyle(
        color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
        fontSize: fontSize,
      ),
    );
  }
}

Future<bool> _launchAboutUrl(Uri url) {
  return launchUrl(url, mode: LaunchMode.externalApplication);
}

class _TextLink extends StatelessWidget {
  const _TextLink({
    required this.label,
    required this.onTap,
    required this.fontSize,
  });

  final String label;
  final VoidCallback onTap;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 3),
        child: Text(
          label,
          style: TextStyle(
            color: theme.colorScheme.primary,
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            decoration: TextDecoration.underline,
            decorationColor: theme.colorScheme.primary,
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(
      {required this.theme, required this.title, required this.fontSize});
  final ThemeData theme;
  final String title;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        color: theme.textTheme.bodyMedium?.color,
        fontSize: fontSize,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

class _PickerRow<T> extends StatelessWidget {
  const _PickerRow({
    required this.values,
    required this.current,
    required this.onSelect,
    required this.labelBuilder,
    required this.fontSize,
  });

  final List<T> values;
  final T current;
  final ValueChanged<T> onSelect;
  final String Function(T) labelBuilder;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: values.map((val) {
        final isSelected = current == val;
        return GestureDetector(
          onTap: () => onSelect(val),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.dividerColor.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              labelBuilder(val),
              style: TextStyle(
                color: isSelected
                    ? theme.colorScheme.onPrimary
                    : theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                fontSize: fontSize,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _MiniButton extends StatelessWidget {
  const _MiniButton({
    required this.label,
    required this.onTap,
    required this.color,
    required this.textColor,
    required this.fontSize,
  });

  final String label;
  final VoidCallback onTap;
  final Color color;
  final Color? textColor;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: textColor,
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
