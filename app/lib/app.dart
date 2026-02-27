/// Root application widget and auth coordinator.
///
/// TLDR:
/// Overview: Manages authentication state, token persistence, and the polling loop.
/// Problem: Need a central place to coordinate OAuth, GCal fetching, and the UI strip.
/// Solution: Implements HappeningApp StatefulWidget with file-based token storage and 5-min polling.
/// Breaking Changes: No.
///
/// ---------------------------------------------------------------------------

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:googleapis/calendar/v3.dart' as gcal;
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import 'core/time/clock_service.dart';
import 'features/calendar/calendar_event.dart';
import 'features/calendar/calendar_service.dart';
import 'features/calendar/event_repository.dart';
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

  _AuthState _authState = _AuthState.loading;
  List<CalendarEvent> _events = const [];
  EventRepository? _repo;
  Timer? _pollTimer;

  // ── Lifecycle ────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _tryRestoreAuth();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  // ── Token persistence ─────────────────────────────────────────────────────

  Future<File> _tokensFile() async {
    final home = Platform.environment['HOME'] ?? '';
    final dir = Directory('$home/.config/happening');
    if (!await dir.exists()) await dir.create(recursive: true);
    return File('${dir.path}/tokens.json');
  }

  Future<AccessCredentials?> _loadCredentials() async {
    try {
      final file = await _tokensFile();
      if (!await file.exists()) return null;
      final json = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      final at = json['accessToken'] as Map<String, dynamic>;
      return AccessCredentials(
        AccessToken(
          at['type'] as String,
          at['data'] as String,
          DateTime.parse(at['expiry'] as String).toUtc(),
        ),
        json['refreshToken'] as String?,
        List<String>.from(json['scopes'] as List),
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _saveCredentials(AccessCredentials creds) async {
    try {
      final file = await _tokensFile();
      await file.writeAsString(jsonEncode({
        'accessToken': {
          'type': creds.accessToken.type,
          'data': creds.accessToken.data,
          'expiry': creds.accessToken.expiry.toIso8601String(),
        },
        'refreshToken': creds.refreshToken,
        'scopes': creds.scopes,
      }));
    } catch (_) {}
  }

  // ── Auth flow ────────────────────────────────────────────────────────────

  /// On startup: try to restore saved credentials before showing the sign-in prompt.
  Future<void> _tryRestoreAuth() async {
    final saved = await _loadCredentials();
    if (saved != null) {
      try {
        final clientId = await _loadClientId();
        final client = autoRefreshingClient(clientId, saved, http.Client());
        client.credentialUpdates.listen(_saveCredentials);
        await _startCalendar(client);
        return;
      } catch (_) {
        // Saved credentials invalid or expired — fall through to sign-in.
      }
    }
    if (mounted) setState(() => _authState = _AuthState.unauthenticated);
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

  /// Opens the system browser for Google OAuth, captures the loopback redirect,
  /// and bootstraps the calendar service.
  Future<void> _signIn() async {
    try {
      final clientId = await _loadClientId();
      final client = await clientViaUserConsent(
        clientId,
        _scopes,
        (url) => launchUrl(
          Uri.parse(url),
          mode: LaunchMode.externalApplication,
        ),
      );
      await _saveCredentials(client.credentials);
      client.credentialUpdates.listen(_saveCredentials);
      await _startCalendar(client);
    } catch (e) {
      // Sign-in cancelled or failed — stay on auth gate.
      if (mounted) setState(() => _authState = _AuthState.unauthenticated);
    }
  }

  // ── Calendar bootstrap ───────────────────────────────────────────────────

  Future<void> _startCalendar(AutoRefreshingAuthClient client) async {
    _repo = EventRepository(
      GoogleCalendarService(gcal.CalendarApi(client)),
    );

    if (mounted) setState(() => _authState = _AuthState.authenticated);

    await _fetchEvents();

    _pollTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) => _fetchEvents(),
    );
  }

  Future<void> _fetchEvents() async {
    try {
      final events = await _repo!.getEvents();
      if (mounted) setState(() => _events = events);
    } catch (_) {
      // Keep stale cache on transient network errors.
    }
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: Scaffold(
        backgroundColor: Colors.transparent,
        body: switch (_authState) {
          _AuthState.loading => const SizedBox.shrink(),
          _AuthState.unauthenticated => _SignInStrip(onTap: _signIn),
          _AuthState.authenticated => TimelineStrip(
              events: _events,
              clockService: _clock,
            ),
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// S2-09: First-launch auth gate — fits inside the 30 px strip
// ---------------------------------------------------------------------------

class _SignInStrip extends StatelessWidget {
  const _SignInStrip({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        color: const Color(0xFF1A1A2E),
        alignment: Alignment.center,
        child: const Text(
          'Tap to sign in with Google →',
          style: TextStyle(color: Colors.white70, fontSize: 11),
        ),
      ),
    );
  }
}
