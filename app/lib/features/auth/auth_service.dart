import 'dart:async';
import 'dart:convert';

import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import 'token_store.dart';

// Abstract authentication service interface.
///
/// TLDR:
/// Overview: Defines the required methods for any auth implementation.
/// Problem: Need to decouple the UI from specific auth providers (GCP, etc).
/// Solution: Declares an abstract AuthService class with a Google implementation.
/// Breaking Changes: No.
///
/// ---------------------------------------------------------------------------

abstract class AuthService {
  Future<bool> signIn();
  Future<void> signOut();
  Future<bool> tryRestore();
  bool get isSignedIn;
  AutoRefreshingAuthClient? get client;
}

class GoogleAuthService implements AuthService {
  GoogleAuthService({
    required ClientId clientId,
    required List<String> scopes,
    required TokenStore tokenStore,
    http.Client? httpClient,
  })  : _clientId = clientId,
        _scopes = scopes,
        _tokenStore = tokenStore,
        _httpClient = httpClient ?? http.Client();

  final ClientId _clientId;
  final List<String> _scopes;
  final TokenStore _tokenStore;
  final http.Client _httpClient;

  AutoRefreshingAuthClient? _client;

  @override
  AutoRefreshingAuthClient? get client => _client;

  @override
  bool get isSignedIn => _client != null;

  @override
  Future<bool> tryRestore() async {
    final json = await _tokenStore.read(key: 'google_credentials');
    if (json == null) return false;

    try {
      final creds = _decode(json);
      _client = autoRefreshingClient(_clientId, creds, _httpClient);
      _client!.credentialUpdates.listen(_onCredentialsChanged);
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> signIn() async {
    try {
      _client = await clientViaUserConsent(
        _clientId,
        _scopes,
        (url) => launchUrl(
          Uri.parse(url),
          mode: LaunchMode.externalApplication,
        ),
      );
      _client!.credentialUpdates.listen(_onCredentialsChanged);
      _onCredentialsChanged(_client!.credentials);
      return true;
    } catch (_) {
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
}
