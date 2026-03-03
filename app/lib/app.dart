// Root application widget and auth coordinator.
//
// TLDR:
// Overview: Manages high-level app state (Auth, Calendar) and root UI switching.
// Problem: Root widget was handling too many responsibilities (OAuth, file IO, polling).
// Solution: Refactored to delegate to AuthService and CalendarController.
// Breaking Changes: No.
//
// ---------------------------------------------------------------------------

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:googleapis/calendar/v3.dart' as gcal;
import 'package:googleapis_auth/auth_io.dart';

import 'core/settings/settings_service.dart';
import 'core/time/clock_service.dart';
import 'core/util/logger.dart';
import 'features/auth/auth_service.dart';
import 'features/auth/token_store.dart';
import 'features/calendar/calendar_controller.dart';
import 'features/calendar/calendar_event.dart';
import 'features/calendar/calendar_service.dart';
import 'features/timeline/timeline_strip.dart';
import 'core/window/window_service.dart';

// ---------------------------------------------------------------------------
// Auth state
// ---------------------------------------------------------------------------

enum _AuthState { loading, unauthenticated, authenticated }

const _scopes = ['https://www.googleapis.com/auth/calendar.readonly'];

// ---------------------------------------------------------------------------
// Root app widget
// ---------------------------------------------------------------------------

class HappeningApp extends StatefulWidget {
  const HappeningApp({
    super.key,
    required this.settingsService,
    required this.windowService,
  });

  final SettingsService settingsService;
  final WindowService windowService;

  @override
  State<HappeningApp> createState() => _HappeningAppState();
}

class _HappeningAppState extends State<HappeningApp> {
  final _clock = ClockService();
  late final AuthService _auth;
  CalendarController? _calendar;

  _AuthState _authState = _AuthState.loading;

  // ── Lifecycle ────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    unawaited(_initServices());
  }

  @override
  void dispose() {
    _calendar?.dispose();
    super.dispose();
  }

  // ── Initialization ───────────────────────────────────────────────────────

  Future<void> _initServices() async {
    await AppLogger.log('HappeningApp._initServices starting...');
    try {
      final home = Platform.environment['HOME'] ?? '';
      final dir = Directory('$home/.config/happening');

      final tokenStore = FileTokenStore(directory: dir);
      final clientId = await _loadClientId();
      await AppLogger.log('OAuth Client ID loaded.');

      _auth = GoogleAuthService(
        clientId: clientId,
        scopes: _scopes,
        tokenStore: tokenStore,
      );

      await AppLogger.log('AuthService initialized. Attempting restore...');
      if (await _auth.tryRestore()) {
        await AppLogger.log('Auth restored successfully.');
        unawaited(_startCalendar());
      } else {
        await AppLogger.log(
            'Auth restore failed. Moving to unauthenticated state.');
        if (mounted) setState(() => _authState = _AuthState.unauthenticated);
      }
    } catch (e) {
      await AppLogger.log('Service initialization FAILED: $e');
      if (mounted) setState(() => _authState = _AuthState.unauthenticated);
    }
  }

  /// Loads OAuth client credentials from the bundled asset file.
  Future<ClientId> _loadClientId() async {
    final raw = await rootBundle.loadString('assets/client_secret.json');
    final data = (jsonDecode(raw) as Map<String, dynamic>)['installed']
        as Map<String, dynamic>;
    return ClientId(
      data['client_id'] as String,
      data['client_secret'] as String,
    );
  }

  // ── Actions ──────────────────────────────────────────────────────────────

  Future<void> _signIn() async {
    if (await _auth.signIn()) {
      unawaited(_startCalendar());
    }
  }

  Future<void> _startCalendar() async {
    await AppLogger.log('HappeningApp._startCalendar called.');
    _calendar?.dispose();
    _calendar = CalendarController(
      GoogleCalendarService(gcal.CalendarApi(_auth.client!)),
      settingsService: widget.settingsService,
    );
    unawaited(_calendar!.start());
    await AppLogger.log('CalendarController started.');

    if (mounted) {
      setState(() {
        _authState = _AuthState.authenticated;
        unawaited(AppLogger.log('AuthState changed to: authenticated'));
      });
    }
  }

  Future<void> _signOut() async {
    await _auth.signOut();
    _calendar?.dispose();
    _calendar = null;
    if (mounted) setState(() => _authState = _AuthState.unauthenticated);
  }

  // ── Build ────────────────────────────────────────────────────────────────

  ThemeData _resolveTheme(AppSettings settings) {
    final brightness = switch (settings.theme) {
      AppTheme.dark => Brightness.dark,
      AppTheme.light => Brightness.light,
      AppTheme.system =>
        WidgetsBinding.instance.platformDispatcher.platformBrightness,
    };

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorSchemeSeed: Colors.blue,
      scaffoldBackgroundColor: Colors.transparent,
      canvasColor: Colors.transparent,
      cardColor: Colors.transparent,
      dialogBackgroundColor: Colors.transparent,
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AppSettings>(
      stream: widget.settingsService.settings,
      initialData: widget.settingsService.current,
      builder: (context, settingsSnapshot) {
        final settings = settingsSnapshot.data!;
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: _resolveTheme(settings),
          builder: (context, child) => Material(
            type: MaterialType.transparency,
            child: child,
          ),
          home: Scaffold(
            backgroundColor: Colors.transparent,
            body: switch (_authState) {
              _AuthState.loading => SizedBox(
                  height: settings.fontSize.px + 20,
                ),
              _AuthState.unauthenticated => _SignInStrip(
                  onTap: _signIn,
                  settings: settings,
                ),
              _AuthState.authenticated => StreamBuilder<List<CalendarEvent>>(
                  stream: _calendar!.events,
                  initialData: _calendar!.lastEvents,
                  builder: (context, eventSnapshot) {
                    final events = eventSnapshot.data;
                    if (events == null) {
                      return _LoadingStrip(settings: settings);
                    }
                    return TimelineStrip(
                      events: events,
                      clockService: _clock,
                      calendarController: _calendar!,
                      settingsService: widget.settingsService,
                      windowService: widget.windowService,
                      onSignOut: _signOut,
                    );
                  },
                ),
            },
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// S5-FIX: Loading state strip
// ---------------------------------------------------------------------------

class _LoadingStrip extends StatelessWidget {
  const _LoadingStrip({required this.settings});
  final AppSettings settings;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
      alignment: Alignment.center,
      child: Text(
        'Fetching calendar...',
        style: TextStyle(
          color: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.color
              ?.withValues(alpha: 0.5),
          fontSize: settings.fontSize.px,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// S2-09: First-launch auth gate — fits inside the 30 px strip
// ---------------------------------------------------------------------------

class _SignInStrip extends StatelessWidget {
  const _SignInStrip({required this.onTap, required this.settings});
  final VoidCallback onTap;
  final AppSettings settings;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
        alignment: Alignment.center,
        child: Text(
          'Tap to sign in with Google →',
          style: TextStyle(
            color: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.color
                ?.withValues(alpha: 0.7),
            fontSize: settings.fontSize.px,
          ),
        ),
      ),
    );
  }
}
