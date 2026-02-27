import 'package:flutter_test/flutter_test.dart';
import 'package:happening/features/auth/auth_service.dart';

// Fake satisfies the AuthService contract without touching google_sign_in.
class _FakeAuthService implements AuthService {
  final bool _signInSucceeds;
  bool _signedIn = false;

  _FakeAuthService({bool signInSucceeds = true})
      : _signInSucceeds = signInSucceeds;

  @override
  Future<bool> signIn() async {
    if (!_signInSucceeds) return false;
    _signedIn = true;
    return true;
  }

  @override
  Future<void> signOut() async => _signedIn = false;

  @override
  bool get isSignedIn => _signedIn;
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
  });
}
