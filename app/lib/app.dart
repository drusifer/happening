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

import 'package:flutter/material.dart';
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

const _kGoogleClientId =
    '732125393297-j5m383u2fdek7j24olmn2vnmjmf49cqn.apps.googleusercontent.com';
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
    await AppLogger.debug('HappeningApp._initServices starting...');
    try {
      final tokenStore = FlutterSecureTokenStore();
      await AppLogger.debug('OAuth Client ID loaded.');

      _auth = GoogleAuthService(
        clientId: ClientId(_kGoogleClientId, ''),
        scopes: _scopes,
        tokenStore: tokenStore,
      );

      await AppLogger.debug('AuthService initialized. Attempting restore...');
      if (await _auth.tryRestore()) {
        await AppLogger.debug('Auth restored successfully.');
        await _startCalendar();
      } else {
        await AppLogger.debug(
            'Auth restore failed. Moving to unauthenticated state.');
        if (mounted) setState(() => _authState = _AuthState.unauthenticated);
      }
    } catch (e) {
      await AppLogger.debug('Service initialization FAILED: $e');
      if (mounted) setState(() => _authState = _AuthState.unauthenticated);
    }
  }

  // ── Actions ──────────────────────────────────────────────────────────────

  Future<void> _signIn() async {
    setState(() => _authState = _AuthState.loading);
    try {
      if (await _auth.signIn()) {
        await _startCalendar();
      } else {
        if (mounted) setState(() => _authState = _AuthState.unauthenticated);
      }
    } catch (e) {
      unawaited(AppLogger.debug('Sign-in error: $e'));
      if (mounted) setState(() => _authState = _AuthState.unauthenticated);
    }
  }

  Future<void> _startCalendar() async {
    await AppLogger.debug('HappeningApp._startCalendar called.');
    _calendar?.dispose();
    _calendar = CalendarController(
      GoogleCalendarService(gcal.CalendarApi(_auth.client!)),
      settingsService: widget.settingsService,
    );
    unawaited(_calendar!.start());
    await AppLogger.debug('CalendarController started.');

    if (mounted) {
      setState(() {
        _authState = _AuthState.authenticated;
        unawaited(AppLogger.debug('AuthState changed to: authenticated'));
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
                  width: double.infinity,
                  height: settings.fontSize.px + 20,
                ),
              _AuthState.unauthenticated => TimelineStrip(
                  events: const [],
                  clockService: _clock,
                  settingsService: widget.settingsService,
                  windowService: widget.windowService,
                  onSignOut: _signOut,
                  onSignIn: _signIn,
                ),
              _AuthState.authenticated => StreamBuilder<List<CalendarEvent>>(
                  stream: _calendar!.events,
                  initialData: _calendar!.lastEvents,
                  builder: (context, eventSnapshot) {
                    return TimelineStrip(
                      events: eventSnapshot.data ?? const [],
                      isLoading: eventSnapshot.data == null,
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

