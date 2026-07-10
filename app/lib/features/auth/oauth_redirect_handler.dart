import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:logging/logging.dart';
import 'package:url_launcher/url_launcher.dart';

// Custom URL scheme — macOS only. Must match CFBundleURLSchemes (macOS
// Info.plist) and the redirect URI registered in Google Cloud Console.
const _kScheme =
    'com.googleusercontent.apps.732125393297-j5m383u2fdek7j24olmn2vnmjmf49cqn';
const _kCustomSchemeRedirect = '$_kScheme:/oauth2redirect';

/// Receives the OAuth 2.0 PKCE callback delivered to the app after the user
/// approves access in the system browser.
///
/// Two transports, split by platform constraint:
///  - **macOS** uses `ASWebAuthenticationSession` (via `flutter_web_auth_2`),
///    Apple's required system-trust auth sheet. The Mac App Store sandbox
///    intentionally ships without the `com.apple.security.network.server`
///    entitlement a loopback server needs, and App Review requires this API
///    specifically over a plain browser launch.
///  - **Windows/Linux** use an ephemeral loopback HTTP server — the recommended
///    desktop flow (RFC 8252 §7.3, Google "Desktop app" client). No registry,
///    no privileges, no native runner wiring, and no sandbox to satisfy.
///
/// [start] begins listening and returns the redirect URI for the auth request.
/// [authenticate] launches the auth URL and resolves with the full callback
/// URI (carrying `code=` and `state=`), or null if the user cancels. Callers
/// validate `state`.
abstract class OAuthRedirectHandler {
  factory OAuthRedirectHandler.create() => Platform.isMacOS
      ? _ASWebAuthRedirectHandler()
      : _LoopbackRedirectHandler();

  /// Starts listening (if needed) and returns the redirect URI for the auth
  /// request.
  Future<String> start();

  /// Launches [authUrl] and resolves with the callback URI, or null if
  /// cancelled.
  Future<Uri?> authenticate(Uri authUrl);

  /// Cancels a pending [authenticate] call (resolves it with null).
  void cancel();
}

/// macOS: `ASWebAuthenticationSession` via `flutter_web_auth_2`. The plugin
/// owns both the browser-launch and the callback-capture in one call — no
/// separate listener to set up.
class _ASWebAuthRedirectHandler implements OAuthRedirectHandler {
  static final _log = Logger('OAuthASWebAuth');

  @override
  Future<String> start() async => _kCustomSchemeRedirect;

  @override
  Future<Uri?> authenticate(Uri authUrl) async {
    try {
      final result = await FlutterWebAuth2.authenticate(
        url: authUrl.toString(),
        callbackUrlScheme: _kScheme,
      );
      return Uri.parse(result);
    } on PlatformException catch (e) {
      // ASWebAuthenticationSessionError.canceledLogin surfaces as this code —
      // see FlutterWebAuth2Plugin.swift. Any other code is a real failure,
      // but callers only distinguish "cancelled" from "failed" via null today.
      if (e.code == 'CANCELED') {
        _log.fine('ASWebAuth: user cancelled');
      } else {
        _log.fine('ASWebAuth: failed — ${e.code}: ${e.message}');
      }
      return null;
    }
  }

  @override
  void cancel() {
    // flutter_web_auth_2 exposes no programmatic dismiss for an in-flight
    // ASWebAuthenticationSession; only the user's own tap on the sheet's
    // Cancel button ends it (AC-6). Our own "tap to cancel" affordance
    // (GoogleAuthService.cancelSignIn) has no in-flight session to interrupt
    // on macOS — it's a no-op here by design.
    _log.fine('cancel(): no-op on macOS, no in-flight session to interrupt');
  }
}

/// Windows/Linux: ephemeral loopback HTTP server. Binds an OS-assigned free
/// port on localhost; Google's Desktop client accepts any loopback port, so
/// nothing has to be registered.
class _LoopbackRedirectHandler implements OAuthRedirectHandler {
  static final _log = Logger('OAuthLoopback');

  HttpServer? _server;

  @override
  Future<String> start() async {
    // Port 0 → the OS picks a free port. 'localhost' (not a fixed IP) matches
    // the proven pre-macOS desktop flow.
    final server = await HttpServer.bind('localhost', 0);
    _server = server;
    final redirectUri = 'http://localhost:${server.port}';
    _log.fine('loopback bound: $redirectUri');
    return redirectUri;
  }

  @override
  Future<Uri?> authenticate(Uri authUrl) async {
    final server = _server;
    if (server == null) return null;
    await launchUrl(authUrl, mode: LaunchMode.externalApplication);
    try {
      // Completes when the browser redirects back, OR throws when cancel()
      // force-closes the server.
      final request = await server.first;
      final uri = request.uri;
      request.response
        ..statusCode = HttpStatus.ok
        ..headers.contentType = ContentType.html
        ..write('<html><body><p>Sign-in complete. '
            'You may close this window.</p></body></html>');
      await request.response.close();
      return uri;
    } catch (_) {
      _log.fine('loopback closed before a callback arrived (cancelled)');
      return null;
    } finally {
      await server.close(force: true);
      _server = null;
    }
  }

  @override
  void cancel() {
    unawaited(_server?.close(force: true));
    _server = null;
  }
}
