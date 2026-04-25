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

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:googleapis/calendar/v3.dart' as gcal;
import 'package:googleapis_auth/auth_io.dart';

import 'core/settings/settings_service.dart';
import 'core/time/clock_service.dart';
import 'core/util/logger.dart';
import 'core/window/window_service.dart';
import 'features/auth/auth_service.dart';
import 'features/auth/token_store.dart';
import 'features/calendar/calendar_controller.dart';
import 'features/calendar/calendar_event.dart';
import 'features/calendar/calendar_service.dart';
import 'features/timeline/timeline_strip.dart';

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
    @visibleForTesting this.authServiceOverride,
    @visibleForTesting this.calendarControllerOverride,
    @visibleForTesting this.clockServiceOverride,
    @visibleForTesting this.enableAnimations = true,
  });

  final SettingsService settingsService;
  final WindowService windowService;

  /// Injected auth service, used only in tests.
  final AuthService? authServiceOverride;

  /// Injected calendar controller, used only in tests (avoids real API calls).
  final CalendarController? calendarControllerOverride;

  /// Injected clock service, used only in tests (avoids real periodic timers).
  final ClockService? clockServiceOverride;

  /// Disable repeating animations so tests can pumpAndSettle.
  final bool enableAnimations;

  @override
  State<HappeningApp> createState() => _HappeningAppState();
}

class _HappeningAppState extends State<HappeningApp> {
  late final ClockService _clock;
  late final AuthService _auth;
  CalendarController? _calendar;

  _AuthState _authState = _AuthState.loading;
  bool _isSigningIn = false;

  // ── Lifecycle ────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _clock = widget.clockServiceOverride ?? ClockService();
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
      if (widget.authServiceOverride != null) {
        _auth = widget.authServiceOverride!;
      } else {
        final tokenStore = FlutterSecureTokenStore();
        await AppLogger.debug('OAuth Client ID loaded.');
        _auth = GoogleAuthService(
          clientId: ClientId(_kGoogleClientId, ''),
          scopes: _scopes,
          tokenStore: tokenStore,
        );
      }

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
    if (mounted) setState(() => _isSigningIn = true);
    try {
      if (await _auth.signIn()) {
        await _startCalendar();
      }
    } catch (e) {
      unawaited(AppLogger.debug('Sign-in error: $e'));
    } finally {
      if (mounted) setState(() => _isSigningIn = false);
    }
  }

  void _cancelSignIn() {
    _auth.cancelSignIn();
    // _isSigningIn is cleared in _signIn()'s finally block once server.first throws.
  }

  Future<void> _startCalendar() async {
    await AppLogger.debug('HappeningApp._startCalendar called.');
    if (widget.calendarControllerOverride == null) {
      _calendar?.dispose();
      _calendar = CalendarController(
        GoogleCalendarService(gcal.CalendarApi(_auth.client!)),
        settingsService: widget.settingsService,
      );
    } else {
      _calendar = widget.calendarControllerOverride;
    }
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
    // Clear persisted calendar selections so they don't bleed into the next account.
    final s = widget.settingsService.current;
    widget.settingsService
        .update(s.copyWith(selectedCalendarIds: const <String>[]));
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
      dialogTheme: const DialogThemeData(backgroundColor: Colors.transparent),
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
                  onSignIn: _isSigningIn ? null : _signIn,
                  onCancelSignIn: _isSigningIn ? _cancelSignIn : null,
                  enableAnimations: widget.enableAnimations,
                ),
              _AuthState.authenticated => StreamBuilder<List<CalendarEvent>>(
                  stream: _calendar!.events,
                  initialData: _calendar!.lastEvents,
                  builder: (context, eventSnapshot) {
                    // [DBG] Trace StreamBuilder state to diagnose stuck-Fetching.
                    unawaited(AppLogger.debug(
                        'app StreamBuilder: state=${eventSnapshot.connectionState} '
                        'hasData=${eventSnapshot.hasData} '
                        'dataLen=${eventSnapshot.data?.length} '
                        'lastEvents=${_calendar?.lastEvents?.length}'));
                    return TimelineStrip(
                      events: eventSnapshot.data ?? const [],
                      isLoading: eventSnapshot.data == null,
                      clockService: _clock,
                      calendarController: _calendar!,
                      settingsService: widget.settingsService,
                      windowService: widget.windowService,
                      onSignOut: _signOut,
                      enableAnimations: widget.enableAnimations,
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
