import 'package:flutter_test/flutter_test.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:happening/features/auth/auth_service.dart';
import 'package:happening/features/auth/token_store.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

@GenerateNiceMocks([MockSpec<TokenStore>()])
import 'auth_service_test.mocks.dart';

// Fake satisfies the AuthService contract without touching google_sign_in.
class _FakeAuthService implements AuthService {
  final bool _signInSucceeds;
  bool _signedIn = false;
  bool cancelCalled = false;

  _FakeAuthService({bool signInSucceeds = true})
      : _signInSucceeds = signInSucceeds;

  @override
  Future<bool> signIn() async {
    if (!_signInSucceeds) return false;
    _signedIn = true;
    return true;
  }

  @override
  void cancelSignIn() => cancelCalled = true;

  @override
  Future<void> signOut() async => _signedIn = false;

  @override
  Future<bool> tryRestore() async => false;

  @override
  bool get isSignedIn => _signedIn;

  @override
  AutoRefreshingAuthClient? get client => null;
}

void main() {
  group('AuthService contract', () {
    test('isSignedIn is false before sign in', () {
      final service = _FakeAuthService();
      expect(service.isSignedIn, isFalse);
    });

    test('signIn returns true on success', () async {
      expect(await _FakeAuthService().signIn(), isTrue);
    });

    test('isSignedIn is true after successful sign in', () async {
      final service = _FakeAuthService();
      await service.signIn();
      expect(service.isSignedIn, isTrue);
    });

    test('signIn returns false on failure', () async {
      expect(await _FakeAuthService(signInSucceeds: false).signIn(), isFalse);
    });

    test('isSignedIn remains false after failed sign in', () async {
      final service = _FakeAuthService(signInSucceeds: false);
      await service.signIn();
      expect(service.isSignedIn, isFalse);
    });

    test('signOut sets isSignedIn to false', () async {
      final service = _FakeAuthService();
      await service.signIn();
      await service.signOut();
      expect(service.isSignedIn, isFalse);
    });

    test('cancelSignIn is callable and does not throw', () {
      final service = _FakeAuthService();
      service.cancelSignIn();
      expect(service.cancelCalled, isTrue);
    });
  });

  group('GoogleAuthService', () {
    late MockTokenStore mockStore;
    late GoogleAuthService service;
    final clientId = ClientId('id', '');

    setUp(() {
      mockStore = MockTokenStore();
      service = GoogleAuthService(
        clientId: clientId,
        scopes: ['scope'],
        tokenStore: mockStore,
      );
    });

    test('tryRestore returns false when no tokens stored', () async {
      when(mockStore.read(key: anyNamed('key'))).thenAnswer((_) async => null);
      expect(await service.tryRestore(), isFalse);
    });

    test('tryRestore returns true and sets client when valid tokens exist',
        () async {
      const credsJson =
          '{"accessToken":{"type":"Bearer","data":"token","expiry":"2026-12-31T00:00:00Z"},"refreshToken":"refresh","scopes":["scope"]}';
      when(mockStore.read(key: 'google_credentials'))
          .thenAnswer((_) async => credsJson);

      expect(await service.tryRestore(), isTrue);
      expect(service.isSignedIn, isTrue);
      expect(service.client, isNotNull);
    });

    test('signOut deletes credentials', () async {
      await service.signOut();
      verify(mockStore.delete(key: 'google_credentials')).called(1);
      expect(service.isSignedIn, isFalse);
    });
  });
}
