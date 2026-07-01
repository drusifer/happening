import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';

import 'oauth_redirect_handler.dart';
import 'token_store.dart';

abstract class AuthService {
  Future<bool> signIn();
  void cancelSignIn();
  Future<void> signOut();
  Future<bool> tryRestore();
  bool get isSignedIn;
  AutoRefreshingAuthClient? get client;
}

const _googleTokenUrl = 'https://oauth2.googleapis.com/token';
const _kProxyUrl = String.fromEnvironment(
  'PROXY_URL',
  defaultValue: 'https://hproxy.globalheadsortails.com',
);

/// Routes Google token requests through the proxy so client_secret is injected
/// server-side and never embedded in the app binary.
class _ProxyingClient extends http.BaseClient {
  _ProxyingClient(this._inner, this._proxyUrl);

  final http.Client _inner;
  final String _proxyUrl;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    if (request.method == 'POST' && request.url.toString() == _googleTokenUrl) {
      final bytes = await request.finalize().toBytes();
      final proxied = http.Request('POST', Uri.parse('$_proxyUrl/token'))
        ..headers.addAll(request.headers)
        ..bodyBytes = bytes;
      return _inner.send(proxied);
    }
    return _inner.send(request);
  }

  @override
  void close() {
    return;
  } // _inner is owned by GoogleAuthService; closing it here would break the outer service
}

class GoogleAuthService implements AuthService {
  static final _log = Logger('GoogleAuthService');

  GoogleAuthService({
    required ClientId clientId,
    required List<String> scopes,
    required TokenStore tokenStore,
    http.Client? httpClient,
    String proxyUrl = _kProxyUrl,
    OAuthRedirectHandler? redirectHandler,
  })  : _clientId = clientId,
        _scopes = scopes,
        _tokenStore = tokenStore,
        _httpClient = httpClient ?? http.Client(),
        _proxyUrl = proxyUrl,
        _redirectHandler = redirectHandler ?? OAuthRedirectHandler.create();

  final ClientId _clientId;
  final List<String> _scopes;
  final TokenStore _tokenStore;
  final http.Client _httpClient;
  final String _proxyUrl;
  final OAuthRedirectHandler _redirectHandler;

  AutoRefreshingAuthClient? _client;

  @override
  AutoRefreshingAuthClient? get client => _client;

  @override
  bool get isSignedIn => _client != null;

  @override
  void cancelSignIn() => _redirectHandler.cancel();

  @override
  Future<bool> tryRestore() async {
    final json = await _tokenStore.read(key: 'google_credentials');
    if (json == null) return false;

    try {
      final creds = _decode(json);
      _client = autoRefreshingClient(
          _clientId, creds, _ProxyingClient(_httpClient, _proxyUrl));
      _client!.credentialUpdates.listen(_onCredentialsChanged);
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> signIn() async {
    _log.fine('PKCE signIn: starting');
    try {
      final verifier = _generateVerifier();
      final challenge = _sha256Challenge(verifier);
      final state = _generateVerifier(); // CSRF protection (RFC 6749 §10.12)

      final redirectUri = await _redirectHandler.start();

      final authUrl = Uri.https('accounts.google.com', '/o/oauth2/auth', {
        'client_id': _clientId.identifier,
        'redirect_uri': redirectUri,
        'response_type': 'code',
        'scope': _scopes.join(' '),
        'code_challenge': challenge,
        'code_challenge_method': 'S256',
        'access_type': 'offline',
        'prompt': 'consent',
        'state': state,
      });

      final callbackUri = await _redirectHandler.authenticate(authUrl);
      if (callbackUri == null) {
        _log.fine('PKCE signIn: cancelled');
        return false;
      }

      // Verify state to prevent CSRF (RFC 6749 §10.12).
      final returnedState = callbackUri.queryParameters['state'];
      if (returnedState != state) {
        _log.fine('PKCE signIn: state mismatch — possible CSRF');
        return false;
      }

      final code = callbackUri.queryParameters['code'];
      if (code == null) {
        // User denied access — Google redirects back with error= instead of code=.
        _log.fine('PKCE signIn: access denied by user');
        return false;
      }

      // Exchange code + verifier via proxy, which injects client_secret.
      final response = await _httpClient.post(
        Uri.parse('$_proxyUrl/token'),
        body: {
          'client_id': _clientId.identifier,
          'code': code,
          'code_verifier': verifier,
          'grant_type': 'authorization_code',
          'redirect_uri': redirectUri,
        },
      );

      _log.fine('PKCE token response: ${response.statusCode}');
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data.containsKey('error')) {
        _log.fine(
            'PKCE token exchange failed: ${data['error']} — ${data['error_description']}');
        return false;
      }
      final expiresIn = (data['expires_in'] as num).toInt();
      final creds = AccessCredentials(
        AccessToken(
          'Bearer',
          data['access_token'] as String,
          DateTime.now().toUtc().add(Duration(seconds: expiresIn)),
        ),
        data['refresh_token'] as String?,
        _scopes,
      );

      _client = autoRefreshingClient(
          _clientId, creds, _ProxyingClient(_httpClient, _proxyUrl));
      _client!.credentialUpdates.listen(_onCredentialsChanged);
      _onCredentialsChanged(_client!.credentials);
      return true;
    } catch (e, st) {
      _log.fine('PKCE signIn exception: $e\n$st');
      return false;
    }
  }

  @override
  Future<void> signOut() async {
    _client?.close();
    _client = null;
    await _tokenStore.delete(key: 'google_credentials');
  }

  void _onCredentialsChanged(AccessCredentials creds) {
    unawaited(
        _tokenStore.write(key: 'google_credentials', value: _encode(creds)));
  }

  String _encode(AccessCredentials creds) {
    return jsonEncode({
      'accessToken': {
        'type': creds.accessToken.type,
        'data': creds.accessToken.data,
        'expiry': creds.accessToken.expiry.toIso8601String(),
      },
      'refreshToken': creds.refreshToken,
      'scopes': creds.scopes,
    });
  }

  AccessCredentials _decode(String jsonStr) {
    final json = jsonDecode(jsonStr) as Map<String, dynamic>;
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
  }

  // ── PKCE helpers ─────────────────────────────────────────────────────────

  /// Generates a cryptographically random code verifier (RFC 7636 §4.1).
  String _generateVerifier() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    return base64Url.encode(bytes).replaceAll('=', '');
  }

  /// Returns BASE64URL(SHA256(verifier)) with padding stripped (RFC 7636 §4.2).
  String _sha256Challenge(String verifier) {
    final digest = sha256.convert(utf8.encode(verifier));
    return base64Url.encode(digest.bytes).replaceAll('=', '');
  }
}
