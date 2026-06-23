import 'dart:async';
import 'dart:io';

import 'package:app_links/app_links.dart';
import 'package:logging/logging.dart';

// Custom URL scheme — macOS only. Must match CFBundleURLSchemes (macOS
// Info.plist) and the redirect URI registered in Google Cloud Console.
const _kScheme =
    'com.googleusercontent.apps.732125393297-j5m383u2fdek7j24olmn2vnmjmf49cqn';
const _kCustomSchemeRedirect = '$_kScheme:/oauth2redirect';

/// Receives the OAuth 2.0 PKCE callback delivered to the app after the user
/// approves access in the system browser.
///
/// Two transports, split by platform constraint:
///  - **macOS** uses a custom URL scheme via `app_links`. The Mac App Store
///    sandbox intentionally ships without the `com.apple.security.network.server`
///    entitlement a loopback server needs, so the custom scheme (no listening
///    socket) is the only sandbox-clean option.
///  - **Windows/Linux** use an ephemeral loopback HTTP server — the recommended
///    desktop flow (RFC 8252 §7.3, Google "Desktop app" client). No registry,
///    no privileges, no native runner wiring, and no sandbox to satisfy.
///
/// [start] begins listening and returns the redirect URI to send the browser
/// to; it MUST be called (and awaited) before launching the auth URL so the
/// loopback socket is bound / the deep-link subscription is live. The same URI
/// must be replayed in the token exchange. [waitForCallback] resolves with the
/// full callback URI (carrying `code=` and `state=`), or null if [cancel] fires
/// first. Callers validate `state`.
abstract class OAuthRedirectHandler {
  factory OAuthRedirectHandler.create() => Platform.isMacOS
      ? _AppLinksRedirectHandler()
      : _LoopbackRedirectHandler();

  /// Starts listening and returns the redirect URI for the auth request.
  Future<String> start();

  /// Completes when the callback arrives, or with null if cancelled.
  Future<Uri?> waitForCallback();

  /// Cancels a pending [waitForCallback] (resolves it with null).
  void cancel();
}

/// macOS: custom URL scheme delivered by `app_links`.
class _AppLinksRedirectHandler implements OAuthRedirectHandler {
  final _appLinks = AppLinks();
  Completer<Uri?>? _completer;
  StreamSubscription<Uri>? _sub;

  @override
  Future<String> start() async {
    final completer = Completer<Uri?>();
    _completer = completer;
    // Subscribe BEFORE returning so the auth-URL launch can't out-race the
    // callback (a tight loop on macOS could otherwise deliver before we listen).
    _sub = _appLinks.uriLinkStream.listen(
      (uri) {
        if (uri.scheme == _kScheme) {
          unawaited(_sub?.cancel());
          _sub = null;
          if (!completer.isCompleted) completer.complete(uri);
        }
      },
      onError: (_) {
        if (!completer.isCompleted) completer.complete(null);
      },
    );
    return _kCustomSchemeRedirect;
  }

  @override
  Future<Uri?> waitForCallback() => _completer?.future ?? Future.value(null);

  @override
  void cancel() {
    unawaited(_sub?.cancel());
    _sub = null;
    final c = _completer;
    _completer = null;
    if (c != null && !c.isCompleted) c.complete(null);
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
  Future<Uri?> waitForCallback() async {
    final server = _server;
    if (server == null) return null;
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
