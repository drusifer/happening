import 'dart:io' show Platform;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_web_auth_2_platform_interface/flutter_web_auth_2_platform_interface.dart';
import 'package:happening/features/auth/oauth_redirect_handler.dart';

const _kScheme =
    'com.googleusercontent.apps.732125393297-j5m383u2fdek7j24olmn2vnmjmf49cqn';

/// Stands in for the native macOS `ASWebAuthenticationSession` channel so
/// tests don't need a real system auth sheet.
class _FakeWebAuthPlatform extends FlutterWebAuth2Platform {
  _FakeWebAuthPlatform.success(this._result) : _error = null;
  _FakeWebAuthPlatform.cancelled()
      : _result = null,
        _error = PlatformException(code: 'CANCELED', message: 'User canceled login');
  _FakeWebAuthPlatform.failure(String code)
      : _result = null,
        _error = PlatformException(code: code, message: 'boom');

  final String? _result;
  final PlatformException? _error;

  @override
  Future<String> authenticate({
    required String url,
    required String callbackUrlScheme,
    required Map<String, dynamic> options,
  }) async {
    if (_error != null) throw _error;
    return _result!;
  }

  @override
  Future clearAllDanglingCalls() async {}
}

// OAuthRedirectHandler.create() branches on Platform.isMacOS; these tests
// only exercise the ASWebAuth path when running on macOS (this repo's dev
// and CI hosts for the macOS target).
final _isMacOS = Platform.isMacOS;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('OAuthRedirectHandler (macOS ASWebAuth)', () {
    late FlutterWebAuth2Platform originalPlatform;

    setUp(() {
      originalPlatform = FlutterWebAuth2Platform.instance;
    });

    tearDown(() {
      FlutterWebAuth2Platform.instance = originalPlatform;
    });

    test('start returns the reverse-client-ID custom scheme redirect', () async {
      final handler = OAuthRedirectHandler.create();
      expect(await handler.start(), '$_kScheme:/oauth2redirect');
    }, skip: !_isMacOS);

    test('authenticate returns the parsed callback URI on success', () async {
      FlutterWebAuth2Platform.instance =
          _FakeWebAuthPlatform.success('$_kScheme:/oauth2redirect?code=abc&state=xyz');
      final handler = OAuthRedirectHandler.create();
      final result = await handler.authenticate(Uri.parse('https://accounts.google.com/o/oauth2/auth'));
      expect(result, isNotNull);
      expect(result!.queryParameters['code'], 'abc');
    }, skip: !_isMacOS);

    test('authenticate returns null when the user cancels (AC-6)', () async {
      FlutterWebAuth2Platform.instance = _FakeWebAuthPlatform.cancelled();
      final handler = OAuthRedirectHandler.create();
      final result = await handler.authenticate(Uri.parse('https://accounts.google.com/o/oauth2/auth'));
      expect(result, isNull);
    }, skip: !_isMacOS);

    test('authenticate returns null on an unrelated platform failure', () async {
      FlutterWebAuth2Platform.instance = _FakeWebAuthPlatform.failure('EUNKNOWN');
      final handler = OAuthRedirectHandler.create();
      final result = await handler.authenticate(Uri.parse('https://accounts.google.com/o/oauth2/auth'));
      expect(result, isNull);
    }, skip: !_isMacOS);

    test('cancel is a no-op that does not throw', () async {
      final handler = OAuthRedirectHandler.create();
      expect(handler.cancel, returnsNormally);
    }, skip: !_isMacOS);
  });
}
