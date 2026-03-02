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

const _scopes = ['https://www.googleapis.com/auth/calendar.readonly'];

// ---------------------------------------------------------------------------
// Root app widget
// ---------------------------------------------------------------------------

class HappeningApp extends StatefulWidget {
  const HappeningApp({super.key});

  @override
  State<HappeningApp> createState() => _HappeningAppState();
}

class _HappeningAppState extends State<HappeningApp> {
  final _clock = ClockService();
  late final SettingsService _settings;

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
    _settings.dispose();
    super.dispose();
  }

  // ── Initialization ───────────────────────────────────────────────────────

  Future<void> _initServices() async {
    final home = Platform.environment['HOME'] ?? '';
    final dir = Directory('$home/.config/happening');

    _settings = SettingsService(directory: dir);
    await _settings.load();

    final tokenStore = FileTokenStore(directory: dir);

    final clientId = await _loadClientId();
    _auth = GoogleAuthService(
      clientId: clientId,
      scopes: _scopes,
      tokenStore: tokenStore,
    );

    if (await _auth.tryRestore()) {
      _startCalendar();
    } else {
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
      _startCalendar();
    }
  }

  void _startCalendar() {
    _calendar?.dispose();
    _calendar = CalendarController(
      GoogleCalendarService(gcal.CalendarApi(_auth.client!)),
      settingsService: _settings,
    );
    _calendar!.start();

    if (mounted) setState(() => _authState = _AuthState.authenticated);
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
      scaffoldBackgroundColor:
          brightness == Brightness.dark ? const Color(0xFF1A1A2E) : Colors.white,
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AppSettings>(
      stream: _settings.settings,
      initialData: _settings.current,
      builder: (context, settingsSnapshot) {
        final settings = settingsSnapshot.data!;
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: _resolveTheme(settings),
          home: Scaffold(
            backgroundColor: Colors.transparent,
            body: switch (_authState) {
              _AuthState.loading => const SizedBox.shrink(),
              _AuthState.unauthenticated => _SignInStrip(
                  onTap: _signIn,
                  settings: settings,
                ),
              _AuthState.authenticated => StreamBuilder<List<CalendarEvent>>(
                  stream: _calendar!.events,
                  initialData: const [],
                  builder: (context, eventSnapshot) {
                    return TimelineStrip(
                      events: eventSnapshot.data!,
                      clockService: _clock,
                      calendarController: _calendar!,
                      settingsService: _settings,
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
// S2-09: First-launch auth gate — fits inside the 30 px strip
// ---------------------------------------------------------------------------

class _SignInStrip extends StatelessWidget {
  const _SignInStrip({required this.onTap, required this.settings});
  final VoidCallback onTap;
  final AppSettings settings;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        alignment: Alignment.center,
        child: Text(
          'Tap to sign in with Google →',
          style: TextStyle(
            color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
            fontSize: settings.fontSize.px,
          ),
        ),
      ),
    );
  }
}
