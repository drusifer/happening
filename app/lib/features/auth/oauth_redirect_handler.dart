import 'dart:async';

import 'package:app_links/app_links.dart';

// The custom URL scheme registered in each platform's manifest.
// Must match CFBundleURLSchemes (macOS Info.plist), the Windows registry entry,
// and the Linux .desktop file, as well as the redirect URI registered in
// Google Cloud Console.
const _kScheme = 'com.googleusercontent.apps.732125393297-j5m383u2fdek7j24olmn2vnmjmf49cqn';
const _kRedirectUri = '$_kScheme:/oauth2redirect';

/// Receives the OAuth 2.0 PKCE callback delivered by the OS after the user
/// approves access in the system browser.
///
/// The browser is sent to Google with [redirectUri] as the redirect target.
/// When Google redirects back, the OS routes the custom-scheme URL to this app
/// and [waitForCallback] resolves with the full URI (containing `code=` and
/// `state=` query parameters). Callers are responsible for validating `state`.
///
/// [cancel] closes a pending [waitForCallback] cleanly (returns null).
///
/// All platforms share one implementation backed by `app_links`; derive a
/// platform subclass here if OS-specific behaviour is ever needed.
abstract class OAuthRedirectHandler {
  factory OAuthRedirectHandler.create() => _AppLinksRedirectHandler();

  String get redirectUri;
  Future<Uri?> waitForCallback();
  void cancel();
}

class _AppLinksRedirectHandler implements OAuthRedirectHandler {
  final _appLinks = AppLinks();
  Completer<Uri?>? _completer;
  StreamSubscription<Uri>? _sub;

  @override
  String get redirectUri => _kRedirectUri;

  @override
  Future<Uri?> waitForCallback() {
    final completer = Completer<Uri?>();
    _completer = completer;
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
    return completer.future;
  }

  @override
  void cancel() {
    unawaited(_sub?.cancel());
    _sub = null;
    final c = _completer;
    _completer = null;
    if (c != null && !c.isCompleted) c.complete(null);
  }
}
