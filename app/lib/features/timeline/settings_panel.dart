// Settings panel popup.
//
// TLDR:
// Overview: A card that shows font size options and a logout button.
// Problem: Need a place for persistent user configuration.
// Solution: Displays a shadow-boxed card with FontSize picker and Logout.
// Breaking Changes: No.
//
// ---------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:happening/core/settings/settings_service.dart';
import 'package:happening/features/calendar/calendar_controller.dart';
import 'package:happening/features/calendar/calendar_service.dart';

/// Popup panel for app settings (Font size, Logout).
class SettingsPanel extends StatefulWidget {
  const SettingsPanel({
    super.key,
    required this.settingsService,
    required this.calendarController,
    required this.onSignOut,
  });

  final SettingsService settingsService;
  final CalendarController calendarController;
  final VoidCallback onSignOut;

  @override
  State<SettingsPanel> createState() => _SettingsPanelState();
}

class _SettingsPanelState extends State<SettingsPanel> {
  List<CalendarMeta>? _availableCalendars;
  bool _isLoadingCalendars = true;

  @override
  void initState() {
    super.initState();
    _loadCalendars();
  }

  Future<void> _loadCalendars() async {
    try {
      final list = await widget.calendarController.service.fetchCalendarList();
      if (mounted) {
        setState(() {
          _availableCalendars = list;
          _isLoadingCalendars = false;
        });
      }
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

    widget.settingsService.update(AppSettings(
      fontSize: settings.fontSize,
      theme: settings.theme,
      timeWindowHours: settings.timeWindowHours,
      selectedCalendarIds: current,
    ));
    widget.calendarController.refresh();
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'SETTINGS',
                  style: TextStyle(
                    color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.5),
                    fontSize: baseSize * 0.6,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
                GestureDetector(
                  onTap: widget.onSignOut,
                  child: Text(
                    'LOGOUT',
                    style: TextStyle(
                      color: Colors.redAccent.withValues(alpha: 0.7),
                      fontSize: baseSize * 0.6,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Theme & Time Window Column
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionHeader(
                        theme: theme, title: 'Theme', fontSize: baseSize * 0.7),
                    const SizedBox(height: 8),
                    _PickerRow<AppTheme>(
                      values: AppTheme.values,
                      current: settings.theme,
                      fontSize: baseSize * 0.65,
                      onSelect: (val) =>
                          widget.settingsService.update(AppSettings(
                        fontSize: settings.fontSize,
                        theme: val,
                        timeWindowHours: settings.timeWindowHours,
                        selectedCalendarIds: settings.selectedCalendarIds,
                      )),
                      labelBuilder: (v) =>
                          v.name[0].toUpperCase() + v.name.substring(1),
                    ),
                    const SizedBox(height: 16),
                    _SectionHeader(
                        theme: theme,
                        title: 'Time Window',
                        fontSize: baseSize * 0.7),
                    const SizedBox(height: 8),
                    _PickerRow<int>(
                      values: const [8, 12, 24],
                      current: settings.timeWindowHours,
                      fontSize: baseSize * 0.65,
                      onSelect: (val) =>
                          widget.settingsService.update(AppSettings(
                        fontSize: settings.fontSize,
                        theme: settings.theme,
                        timeWindowHours: val,
                        selectedCalendarIds: settings.selectedCalendarIds,
                      )),
                      labelBuilder: (v) => '${v}h',
                    ),
                  ],
                ),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  width: 1,
                  height: 120 * scale,
                  color: theme.dividerColor.withValues(alpha: 0.1),
                ),
                // Calendars Column
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
                      if (_isLoadingCalendars)
                        const Center(
                            child: Padding(
                          padding: EdgeInsets.all(8.0),
                          child: SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(strokeWidth: 2)),
                        ))
                      else if (_availableCalendars != null)
                        ConstrainedBox(
                          constraints: BoxConstraints(maxHeight: 100 * scale),
                          child: ListView.separated(
                            shrinkWrap: true,
                            itemCount: _availableCalendars!.length,
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
                                        : theme.dividerColor.withValues(alpha: 0.05),
                                    borderRadius: BorderRadius.circular(4),
                                    border: isSelected
                                        ? Border.all(
                                            color: cal.color.withValues(alpha: 0.4))
                                        : null,
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                          width: 8 * scale,
                                          height: 8 * scale,
                                          decoration: BoxDecoration(
                                              color: cal.color,
                                              shape: BoxShape.circle)),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          cal.summary,
                                          style: TextStyle(
                                            color: theme
                                                .textTheme.bodyMedium?.color
                                                ?.withOpacity(
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
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  width: 1,
                  height: 120 * scale,
                  color: theme.dividerColor.withValues(alpha: 0.1),
                ),
                // Font Size Column
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionHeader(
                        theme: theme,
                        title: 'Font Size',
                        fontSize: baseSize * 0.7),
                    const SizedBox(height: 8),
                    _PickerRow<FontSize>(
                      values: FontSize.values,
                      current: settings.fontSize,
                      fontSize: baseSize * 0.65,
                      onSelect: (val) =>
                          widget.settingsService.update(AppSettings(
                        fontSize: val,
                        theme: settings.theme,
                        timeWindowHours: settings.timeWindowHours,
                        selectedCalendarIds: settings.selectedCalendarIds,
                      )),
                      labelBuilder: (v) =>
                          v.name[0].toUpperCase() + v.name.substring(1),
                    ),
                  ],
                ),
              ],
            ),
          ],
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
