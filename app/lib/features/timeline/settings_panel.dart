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
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:happening/core/app_metadata.dart';
import 'package:happening/core/astro/astro_settings.dart';
import 'package:happening/core/settings/settings_service.dart';
import 'package:happening/features/calendar/calendar_controller.dart';
import 'package:happening/features/calendar/calendar_service.dart';
import 'package:url_launcher/url_launcher.dart';

typedef AboutUrlLauncher = Future<bool> Function(Uri url);

/// Result of a city name resolution attempt.
typedef CityResult = ({double lat, double lng, String label});

/// Callback type for resolving a city name to coordinates.
typedef ResolveCityName = Future<CityResult?> Function(String query);

/// Callback type for getting the device's current position.
typedef GetDevicePosition = Future<({double lat, double lng})?> Function();

/// Popup panel for app settings (Font size, Logout).
class SettingsPanel extends StatefulWidget {
  const SettingsPanel({
    super.key,
    required this.settingsService,
    required this.calendarController,
    required this.onSignOut,
    this.launchAboutUrl = _launchAboutUrl,
    this.platformOverride,
    this.getDevicePosition = _defaultGetDevicePosition,
    this.resolveCityName = _defaultResolveCityName,
  });

  final SettingsService settingsService;
  final CalendarController calendarController;
  final VoidCallback onSignOut;
  final AboutUrlLauncher launchAboutUrl;
  final TargetPlatform? platformOverride;
  final GetDevicePosition getDevicePosition;
  final ResolveCityName resolveCityName;

  @override
  State<SettingsPanel> createState() => _SettingsPanelState();
}

class _SettingsPanelState extends State<SettingsPanel> {
  List<CalendarMeta>? _availableCalendars;
  bool _isLoadingCalendars = true;
  double? _pendingFontSize;

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
            SizedBox(
              width: 240 * scale,
              child: Column(
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
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              width: 1,
              color: theme.dividerColor.withValues(alpha: 0.1),
            ),
            // ── Middle: Font Size ────────────────────────────────────────
            SizedBox(
              width: 190 * scale,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _SectionHeader(
                      theme: theme,
                      title: 'Font Size',
                      fontSize: baseSize * 0.7),
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
                            unawaited(widget.settingsService.update(
                              settings.copyWith(fontSizePx: value),
                            ));
                          },
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: _SliderLabel(
                                  label: 'Smaller',
                                  fontSize: baseSize * 0.55,
                                  textAlign: TextAlign.left,
                                ),
                              ),
                            ),
                            Expanded(
                              child: _SliderLabel(
                                label: 'Default',
                                fontSize: baseSize * 0.55,
                                textAlign: TextAlign.center,
                              ),
                            ),
                            Expanded(
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: _SliderLabel(
                                  label: 'Larger',
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
                  const SizedBox(height: 10),
                  _SectionHeader(
                      theme: theme,
                      title: 'Transparency',
                      fontSize: baseSize * 0.7),
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
                                  label: 'See-through',
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
                                  label: 'Opaque',
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
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              width: 1,
              color: theme.dividerColor.withValues(alpha: 0.1),
            ),
            // ── Right: Calendars spanning full height ────────────────────
            SizedBox(
              width: 150 * scale,
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
            // ── Location (only when Astronomical theme active) ────────────
            if (settings.theme == AppTheme.astronomical) ...[
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 8),
                width: 1,
                color: theme.dividerColor.withValues(alpha: 0.1),
              ),
              SizedBox(
                width: 200 * scale,
                child: _AstroLocationSection(
                  settingsService: widget.settingsService,
                  getDevicePosition: widget.getDevicePosition,
                  resolveCityName: widget.resolveCityName,
                  baseSize: baseSize,
                ),
              ),
            ],
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

// ── Default location callbacks ─────────────────────────────────────────────────

Future<({double lat, double lng})?> _defaultGetDevicePosition() async {
  try {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return null;
    }
    final pos = await Geolocator.getCurrentPosition();
    return (lat: pos.latitude, lng: pos.longitude);
  } catch (_) {
    return null;
  }
}

Future<CityResult?> _defaultResolveCityName(String query) async {
  // City geocoding is not bundled. On supported platforms, this could be
  // extended with a geocoding package. For now, returns null (no match).
  return null;
}

// ── Astronomical location section ─────────────────────────────────────────────

class _AstroLocationSection extends StatefulWidget {
  const _AstroLocationSection({
    required this.settingsService,
    required this.getDevicePosition,
    required this.resolveCityName,
    required this.baseSize,
  });

  final SettingsService settingsService;
  final GetDevicePosition getDevicePosition;
  final ResolveCityName resolveCityName;
  final double baseSize;

  @override
  State<_AstroLocationSection> createState() => _AstroLocationSectionState();
}

class _AstroLocationSectionState extends State<_AstroLocationSection> {
  final _cityController = TextEditingController();
  final _latController = TextEditingController();
  final _lngController = TextEditingController();

  bool _loadingPosition = false;
  String? _positionError;
  String? _cityError;
  CityResult? _cityPreview;
  bool _showAdvanced = false;
  String? _coordError;

  @override
  void initState() {
    super.initState();
    final astro = widget.settingsService.current.astroSettings;
    if (astro.latitude != null) {
      _latController.text = astro.latitude!.toStringAsFixed(4);
    }
    if (astro.longitude != null) {
      _lngController.text = astro.longitude!.toStringAsFixed(4);
    }
  }

  @override
  void dispose() {
    _cityController.dispose();
    _latController.dispose();
    _lngController.dispose();
    super.dispose();
  }

  AstroSettings get _astro => widget.settingsService.current.astroSettings;

  void _saveLocation(double lat, double lng, {String? cityName}) {
    final settings = widget.settingsService.current;
    widget.settingsService.update(settings.copyWith(
      astroSettings: _astro.copyWith(
        latitude: lat,
        longitude: lng,
        cityName: cityName,
      ),
    ));
  }

  Future<void> _useDeviceLocation() async {
    setState(() {
      _loadingPosition = true;
      _positionError = null;
    });

    final result = await widget.getDevicePosition();
    if (!mounted) return;

    if (result == null) {
      final perm = await Geolocator.checkPermission().catchError((_) =>
          LocationPermission.denied);
      setState(() {
        _loadingPosition = false;
        _positionError = perm == LocationPermission.deniedForever
            ? 'Location access denied. Grant permission in System Settings, or enter your location below.'
            : 'Location access denied. Grant permission in System Settings, or enter your location below.';
      });
    } else {
      _saveLocation(result.lat, result.lng,
          cityName: _astro.cityName);
      setState(() {
        _loadingPosition = false;
        _positionError = null;
      });
    }
  }

  Future<void> _searchCity() async {
    final query = _cityController.text.trim();
    if (query.isEmpty) return;

    setState(() => _cityError = null);
    final result = await widget.resolveCityName(query);
    if (!mounted) return;

    if (result == null) {
      setState(() {
        _cityError =
            "No results for '$query' — try a larger nearby city, or use Advanced coordinates.";
        _cityPreview = null;
      });
    } else {
      setState(() => _cityPreview = result);
    }
  }

  void _confirmCityPreview() {
    if (_cityPreview == null) return;
    _saveLocation(_cityPreview!.lat, _cityPreview!.lng,
        cityName: _cityPreview!.label);
    setState(() {
      _cityPreview = null;
      _cityController.clear();
    });
  }

  void _applyCoords() {
    final lat = double.tryParse(_latController.text.trim());
    final lng = double.tryParse(_lngController.text.trim());
    if (lat == null || lng == null || lat < -90 || lat > 90 || lng < -180 || lng > 180) {
      setState(() => _coordError = 'Invalid coordinates. Lat: -90–90, Lng: -180–180.');
      return;
    }
    _saveLocation(lat, lng, cityName: _astro.cityName);
    setState(() => _coordError = null);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fs = widget.baseSize;
    final astro = _astro;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _SectionHeader(theme: theme, title: 'Location', fontSize: fs * 0.7),
        const SizedBox(height: 6),

        // Location preview / prompt.
        if (astro.hasLocation)
          Text(
            astro.cityName != null
                ? '${astro.cityName} · ${_formatCoord(astro.latitude!, astro.longitude!)}'
                : _formatCoord(astro.latitude!, astro.longitude!),
            style: TextStyle(
              color: theme.colorScheme.primary,
              fontSize: fs * 0.6,
            ),
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

        const SizedBox(height: 8),

        // Use Current Location button.
        _loadingPosition
            ? const SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(strokeWidth: 1.5),
              )
            : _MiniButton(
                label: 'Use Current Location',
                onTap: _useDeviceLocation,
                color: theme.colorScheme.primary.withValues(alpha: 0.15),
                textColor: theme.colorScheme.primary,
                fontSize: fs * 0.55,
              ),

        if (_positionError != null) ...[
          const SizedBox(height: 4),
          Text(
            _positionError!,
            style: TextStyle(
              color: Colors.orangeAccent,
              fontSize: fs * 0.55,
            ),
          ),
        ],

        const SizedBox(height: 8),

        // City search field (primary manual fallback).
        Row(
          children: [
            Expanded(
              child: TextField(
                key: const Key('city_search_field'),
                controller: _cityController,
                style: TextStyle(fontSize: fs * 0.6, color: theme.textTheme.bodyMedium?.color),
                decoration: InputDecoration(
                  hintText: 'City name...',
                  hintStyle: TextStyle(fontSize: fs * 0.6),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
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

        if (_cityPreview != null) ...[
          const SizedBox(height: 4),
          Text(
            '${_cityPreview!.label} → ${_formatCoord(_cityPreview!.lat, _cityPreview!.lng)}',
            style: TextStyle(fontSize: fs * 0.6, color: theme.textTheme.bodyMedium?.color),
          ),
          const SizedBox(height: 4),
          _MiniButton(
            label: 'Confirm',
            onTap: _confirmCityPreview,
            color: theme.colorScheme.primary.withValues(alpha: 0.15),
            textColor: theme.colorScheme.primary,
            fontSize: fs * 0.55,
          ),
        ],

        const SizedBox(height: 8),

        // Advanced section (collapsed by default).
        GestureDetector(
          onTap: () => setState(() => _showAdvanced = !_showAdvanced),
          child: Row(
            children: [
              Text(
                'Advanced',
                style: TextStyle(
                  fontSize: fs * 0.6,
                  color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                _showAdvanced ? Icons.expand_less : Icons.expand_more,
                size: fs * 0.8,
                color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
              ),
            ],
          ),
        ),

        if (_showAdvanced) ...[
          const SizedBox(height: 6),
          _CoordField(
            key: const Key('lat_field'),
            label: 'Lat',
            controller: _latController,
            fontSize: fs,
          ),
          const SizedBox(height: 4),
          _CoordField(
            key: const Key('lng_field'),
            label: 'Lng',
            controller: _lngController,
            fontSize: fs,
          ),
          if (_coordError != null) ...[
            const SizedBox(height: 4),
            Text(
              _coordError!,
              style: TextStyle(color: Colors.redAccent, fontSize: fs * 0.55),
            ),
          ],
          const SizedBox(height: 6),
          _MiniButton(
            key: const Key('apply_coords_button'),
            label: 'Apply',
            onTap: _applyCoords,
            color: theme.colorScheme.primary.withValues(alpha: 0.15),
            textColor: theme.colorScheme.primary,
            fontSize: fs * 0.55,
          ),
        ],
      ],
    );
  }
}

String _formatCoord(double lat, double lng) {
  final latDir = lat >= 0 ? 'N' : 'S';
  final lngDir = lng >= 0 ? 'E' : 'W';
  return '${lat.abs().toStringAsFixed(2)}°$latDir ${lng.abs().toStringAsFixed(2)}°$lngDir';
}

class _CoordField extends StatelessWidget {
  const _CoordField({
    super.key,
    required this.label,
    required this.controller,
    required this.fontSize,
  });

  final String label;
  final TextEditingController controller;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        SizedBox(
          width: 24,
          child: Text(
            label,
            style: TextStyle(
              fontSize: fontSize * 0.6,
              color: theme.textTheme.bodySmall?.color,
            ),
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: TextField(
            controller: controller,
            style: TextStyle(
                fontSize: fontSize * 0.6,
                color: theme.textTheme.bodyMedium?.color),
            keyboardType:
                const TextInputType.numberWithOptions(signed: true, decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[-0-9.]')),
            ],
            decoration: InputDecoration(
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
            ),
          ),
        ),
      ],
    );
  }
}

class _MiniButton extends StatelessWidget {
  const _MiniButton({
    super.key,
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
