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

import 'package:flutter/material.dart';
import 'package:happening/core/app_metadata.dart';
import 'package:happening/core/astro/astro_settings.dart';
import 'package:happening/core/astro/city_search.dart' as city_search;
import 'package:happening/core/display/display_info.dart';
import 'package:happening/core/display/display_service.dart';
import 'package:happening/core/display/persisted_display_choice.dart';
import 'package:happening/core/settings/settings_service.dart';
import 'package:happening/features/calendar/calendar_controller.dart';
import 'package:happening/features/calendar/calendar_service.dart';
import 'package:url_launcher/url_launcher.dart';

typedef AboutUrlLauncher = Future<bool> Function(Uri url);

/// Result of a city name resolution attempt.
typedef CityResult = ({double lat, double lng, String label});

/// Callback type for resolving a city name to a list of matching cities,
/// best match first.
typedef ResolveCityName = Future<List<CityResult>> Function(String query);

/// Popup panel for app settings (Font size, Logout).
class SettingsPanel extends StatefulWidget {
  const SettingsPanel({
    super.key,
    required this.settingsService,
    required this.calendarController,
    required this.onSignOut,
    this.launchAboutUrl = _launchAboutUrl,
    this.platformOverride,
    this.resolveCityName = _defaultResolveCityName,
    this.displayService,
    this.displaySectionKey,
  });

  final SettingsService settingsService;
  final CalendarController calendarController;
  final VoidCallback onSignOut;
  final AboutUrlLauncher launchAboutUrl;
  final TargetPlatform? platformOverride;
  final ResolveCityName resolveCityName;
  final DisplayService? displayService;

  /// Key attached to the Display section root so the on-strip fallback
  /// indicator can deep-link via `Scrollable.ensureVisible`.
  final Key? displaySectionKey;

  @override
  State<SettingsPanel> createState() => _SettingsPanelState();
}

class _SettingsPanelState extends State<SettingsPanel> {
  List<CalendarMeta>? _availableCalendars;
  bool _isLoadingCalendars = true;
  double? _pendingFontSize;

  /// The signed-in account's email — the primary calendar's id is the address.
  String? get _accountName {
    final cals = _availableCalendars;
    if (cals == null || cals.isEmpty) return null;
    final primary = cals.firstWhere((c) => c.isPrimary, orElse: () => cals.first);
    final id = primary.id;
    return id.contains('@') ? id : null;
  }

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = widget.settingsService.current;
    final baseSize = settings.fontSizePx;
    final scale = baseSize / 15.0;

    final divider = Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      width: 1,
      color: theme.dividerColor.withValues(alpha: 0.1),
    );

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
            _buildLeftColumn(theme, settings, baseSize, scale),
            divider,
            _buildMiddleColumn(theme, settings, baseSize, scale),
            divider,
            _buildRightColumn(theme, settings, baseSize, scale),
            if (settings.theme == AppTheme.astronomical) ...[
              divider,
              SizedBox(
                width: 200 * scale,
                child: _AstroLocationSection(
                  settingsService: widget.settingsService,
                  resolveCityName: widget.resolveCityName,
                  baseSize: baseSize,
                ),
              ),
            ],
            if (widget.displayService != null) ...[
              divider,
              SizedBox(
                width: 200 * scale,
                child: _DisplaySection(
                  key: widget.displaySectionKey,
                  settingsService: widget.settingsService,
                  displayService: widget.displayService!,
                  baseSize: baseSize,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLeftColumn(
      ThemeData theme, AppSettings settings, double baseSize, double scale) {
    return SizedBox(
      width: 240 * scale,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'SETTINGS  v. $appVersion',
            style: TextStyle(
              color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.5),
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
                widget.settingsService.update(settings.copyWith(theme: val)),
            labelBuilder: (v) => v.name[0].toUpperCase() + v.name.substring(1),
          ),
          const SizedBox(height: 10),
          _SectionHeader(
              theme: theme, title: 'Time Window', fontSize: baseSize * 0.7),
          const SizedBox(height: 6),
          _PickerRow<int>(
            values: const [8, 12, 24],
            current: settings.timeWindowHours,
            fontSize: baseSize * 0.65,
            onSelect: (val) => widget.settingsService
                .update(settings.copyWith(timeWindowHours: val)),
            labelBuilder: (v) => '${v}h',
          ),
          const Spacer(),
          Row(
            children: [
              _MiniButton(
                label: 'LOGOUT',
                onTap: widget.onSignOut,
                color: Colors.redAccent.withValues(alpha: 0.15),
                textColor: Colors.redAccent.withValues(alpha: 0.8),
                fontSize: baseSize * 0.55,
              ),
              if (_accountName != null) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _accountName!,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: theme.textTheme.bodySmall?.color
                          ?.withValues(alpha: 0.6),
                      fontSize: baseSize * 0.55,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiddleColumn(
      ThemeData theme, AppSettings settings, double baseSize, double scale) {
    return SizedBox(
      width: 190 * scale,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _SectionHeader(
              theme: theme, title: 'Font Size', fontSize: baseSize * 0.7),
          const SizedBox(height: 6),
          SizedBox(
            width: 190 * scale,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Slider(
                  value: _pendingFontSize ?? settings.fontSizePx,
                  min: kMinFontSizePx,
                  max: kMaxFontSizePx,
                  divisions: 11,
                  label:
                      '${(_pendingFontSize ?? settings.fontSizePx).round()} pt',
                  onChanged: (value) =>
                      setState(() => _pendingFontSize = value),
                  onChangeEnd: (value) {
                    setState(() => _pendingFontSize = null);
                    unawaited(widget.settingsService
                        .update(settings.copyWith(fontSizePx: value)));
                  },
                ),
                _buildSliderLabels(baseSize, 'Smaller', 'Default', 'Larger'),
              ],
            ),
          ),
          const SizedBox(height: 10),
          _SectionHeader(
              theme: theme, title: 'Transparency', fontSize: baseSize * 0.7),
          const SizedBox(height: 6),
          SizedBox(
            width: 190 * scale,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Slider(
                  value: settings.idleTimelineOpacity,
                  min: kMinIdleTimelineOpacity,
                  max: kMaxIdleTimelineOpacity,
                  divisions: 16,
                  label: '${(settings.idleTimelineOpacity * 100).round()}%',
                  onChanged: (value) => widget.settingsService
                      .update(settings.copyWith(idleTimelineOpacity: value)),
                ),
                _buildSliderLabels(
                    baseSize, 'See-through', 'Balanced', 'Opaque'),
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
    );
  }

  Widget _buildSliderLabels(
      double baseSize, String left, String center, String right) {
    return Row(
      children: [
        Expanded(
          child: Align(
            alignment: Alignment.centerLeft,
            child: _SliderLabel(
                label: left,
                fontSize: baseSize * 0.55,
                textAlign: TextAlign.left),
          ),
        ),
        Expanded(
          child: _SliderLabel(
              label: center,
              fontSize: baseSize * 0.55,
              textAlign: TextAlign.center),
        ),
        Expanded(
          child: Align(
            alignment: Alignment.centerRight,
            child: _SliderLabel(
                label: right,
                fontSize: baseSize * 0.55,
                textAlign: TextAlign.right),
          ),
        ),
      ],
    );
  }

  Widget _buildRightColumn(
      ThemeData theme, AppSettings settings, double baseSize, double scale) {
    return SizedBox(
      width: 150 * scale,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
              theme: theme, title: 'Calendars', fontSize: baseSize * 0.7),
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
                : _buildCalendarList(theme, settings, baseSize, scale),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarList(
      ThemeData theme, AppSettings settings, double baseSize, double scale) {
    return ListView.separated(
      itemCount: _availableCalendars?.length ?? 0,
      separatorBuilder: (_, __) => const SizedBox(height: 4),
      itemBuilder: (context, index) {
        final cal = _availableCalendars![index];
        final isSelected = settings.selectedCalendarIds.isEmpty
            ? cal.id == 'primary'
            : settings.selectedCalendarIds.contains(cal.id);
        return GestureDetector(
          onTap: () => _toggleCalendar(cal.id),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            decoration: BoxDecoration(
              color: isSelected
                  ? cal.color.withValues(alpha: 0.2)
                  : theme.dividerColor.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(4),
              border: isSelected
                  ? Border.all(color: cal.color.withValues(alpha: 0.4))
                  : null,
            ),
            child: Row(
              children: [
                Container(
                  width: 8 * scale,
                  height: 8 * scale,
                  decoration:
                      BoxDecoration(color: cal.color, shape: BoxShape.circle),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    cal.summary,
                    style: TextStyle(
                      color: theme.textTheme.bodyMedium?.color
                          ?.withValues(alpha: isSelected ? 1.0 : 0.6),
                      fontSize: baseSize * 0.65,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isSelected)
                  Icon(Icons.check,
                      size: baseSize * 0.65, color: theme.colorScheme.primary),
              ],
            ),
          ),
        );
      },
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

// ── Default location callbacks ─────────────────────────────────────────────────

Future<List<CityResult>> _defaultResolveCityName(String query) async {
  final matches = await city_search.searchCities(query);
  return matches
      .map((m) => (lat: m.lat, lng: m.lng, label: m.label))
      .toList();
}

// ── Astronomical location section ─────────────────────────────────────────────

class _AstroLocationSection extends StatefulWidget {
  const _AstroLocationSection({
    required this.settingsService,
    required this.resolveCityName,
    required this.baseSize,
  });

  final SettingsService settingsService;
  final ResolveCityName resolveCityName;
  final double baseSize;

  @override
  State<_AstroLocationSection> createState() => _AstroLocationSectionState();
}

class _AstroLocationSectionState extends State<_AstroLocationSection> {
  final _cityController = TextEditingController();

  String? _cityError;
  List<CityResult>? _cityResults;

  @override
  void dispose() {
    _cityController.dispose();
    super.dispose();
  }

  AstroSettings get _astro => widget.settingsService.current.astroSettings;

  void _saveLocation(double lat, double lng, {String? cityName}) {
    final settings = widget.settingsService.current;
    unawaited(widget.settingsService.update(settings.copyWith(
      astroSettings: _astro.copyWith(
        latitude: lat,
        longitude: lng,
        cityName: cityName,
      ),
    )));
  }

  Future<void> _searchCity() async {
    final query = _cityController.text.trim();
    if (query.isEmpty) return;

    setState(() => _cityError = null);
    final results = await widget.resolveCityName(query);
    if (!mounted) return;

    if (results.isEmpty) {
      setState(() {
        _cityError =
            "No results for '$query' — try a different or nearby city.";
        _cityResults = null;
      });
    } else {
      setState(() => _cityResults = results);
    }
  }

  void _selectCity(CityResult city) {
    _saveLocation(city.lat, city.lng, cityName: city.label);
    setState(() {
      _cityResults = null;
      _cityController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fs = widget.baseSize;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _SectionHeader(theme: theme, title: 'Location', fontSize: fs * 0.7),
        const SizedBox(height: 6),
        ..._buildLocationDisplay(theme, fs),
        const SizedBox(height: 8),
        ..._buildCitySearch(theme, fs),
      ],
    );
  }

  List<Widget> _buildLocationDisplay(ThemeData theme, double fs) {
    final astro = _astro;
    return [
      if (astro.hasLocation)
        Text(
          astro.cityName != null
              ? '${astro.cityName} · ${_formatCoord(astro.latitude!, astro.longitude!)}'
              : _formatCoord(astro.latitude!, astro.longitude!),
          style:
              TextStyle(color: theme.colorScheme.primary, fontSize: fs * 0.6),
        )
      else
        Text(
          'Set location to see sunrise & moon times',
          style: TextStyle(
            color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6),
            fontSize: fs * 0.6,
            fontStyle: FontStyle.italic,
          ),
        ),
    ];
  }

  List<Widget> _buildCitySearch(ThemeData theme, double fs) {
    return [
      Row(
        children: [
          Expanded(
            child: TextField(
              key: const Key('city_search_field'),
              controller: _cityController,
              style: TextStyle(
                  fontSize: fs * 0.6, color: theme.textTheme.bodyMedium?.color),
              decoration: InputDecoration(
                hintText: 'City name...',
                hintStyle: TextStyle(fontSize: fs * 0.6),
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
              ),
              onSubmitted: (_) => _searchCity(),
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            key: const Key('city_search_button'),
            icon: const Icon(Icons.search, size: 16),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: _searchCity,
          ),
        ],
      ),
      if (_cityError != null) ...[
        const SizedBox(height: 4),
        Text(
          _cityError!,
          style: TextStyle(color: Colors.orangeAccent, fontSize: fs * 0.55),
        ),
      ],
      if (_cityResults != null) ...[
        const SizedBox(height: 4),
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 140),
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(
                color: theme.dividerColor.withValues(alpha: 0.5),
              ),
              borderRadius: BorderRadius.circular(4),
            ),
            child: ListView.builder(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: _cityResults!.length,
              itemBuilder: (context, i) {
                final city = _cityResults![i];
                return InkWell(
                  key: Key('city_result_$i'),
                  onTap: () => _selectCity(city),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 5),
                    child: Text(
                      '${city.label} · ${_formatCoord(city.lat, city.lng)}',
                      style: TextStyle(
                        fontSize: fs * 0.6,
                        color: theme.textTheme.bodyMedium?.color,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    ];
  }
}

String _formatCoord(double lat, double lng) {
  final latDir = lat >= 0 ? 'N' : 'S';
  final lngDir = lng >= 0 ? 'E' : 'W';
  return '${lat.abs().toStringAsFixed(2)}°$latDir ${lng.abs().toStringAsFixed(2)}°$lngDir';
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

/// Display picker section (F-30 D1 + D2): radio list of available displays
/// plus an unavailable-fallback row when the user's persisted choice has
/// disconnected.
class _DisplaySection extends StatefulWidget {
  const _DisplaySection({
    super.key,
    required this.settingsService,
    required this.displayService,
    required this.baseSize,
  });

  final SettingsService settingsService;
  final DisplayService displayService;
  final double baseSize;

  @override
  State<_DisplaySection> createState() => _DisplaySectionState();
}

class _DisplaySectionState extends State<_DisplaySection> {
  Future<void> _chooseDisplay(DisplayInfo d) async {
    final choice = PersistedDisplayChoice.fromDisplay(d);
    await widget.displayService.setPersistedChoice(choice);
    await widget.settingsService.update(
      widget.settingsService.current.copyWith(chosenDisplay: choice),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListenableBuilder(
      listenable: widget.displayService,
      builder: (context, _) {
        final available = widget.displayService.availableDisplays;
        final activeDisplay = widget.displayService.activeDisplay;
        final inFallback = widget.displayService.isInFallback;
        final persisted = widget.settingsService.current.chosenDisplay;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _SectionHeader(
              theme: theme,
              title: 'Display',
              fontSize: widget.baseSize * 0.7,
            ),
            const SizedBox(height: 6),
            for (final d in available)
              _DisplayRadioRow(
                label: d.labelFor(available),
                selected: d == activeDisplay && !inFallback,
                fontSize: widget.baseSize * 0.65,
                onTap: () => unawaited(_chooseDisplay(d)),
              ),
            if (inFallback && persisted != null) ...[
              const SizedBox(height: 8),
              _FallbackRow(
                persisted: persisted,
                fontSize: widget.baseSize * 0.55,
              ),
            ],
          ],
        );
      },
    );
  }
}

class _DisplayRadioRow extends StatelessWidget {
  const _DisplayRadioRow({
    required this.label,
    required this.selected,
    required this.fontSize,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final double fontSize;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              size: fontSize + 2,
              color: selected
                  ? theme.colorScheme.primary
                  : theme.textTheme.bodySmall?.color?.withValues(alpha: 0.5),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: theme.textTheme.bodyMedium?.color
                      ?.withValues(alpha: selected ? 1.0 : 0.7),
                  fontSize: fontSize,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FallbackRow extends StatelessWidget {
  const _FallbackRow({
    required this.persisted,
    required this.fontSize,
  });

  final PersistedDisplayChoice persisted;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = _persistedLabel(persisted);
    return Text(
      'Currently set: $label — unavailable. Showing on primary until it reconnects.',
      style: TextStyle(
        color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.65),
        fontSize: fontSize,
        fontStyle: FontStyle.italic,
      ),
    );
  }

  static String _persistedLabel(PersistedDisplayChoice c) {
    final name = c.osName.trim();
    final w = c.widthLogical.toInt();
    final h = c.heightLogical.toInt();
    return name.isNotEmpty ? '$name ($w×$h)' : 'Display ($w×$h)';
  }
}
