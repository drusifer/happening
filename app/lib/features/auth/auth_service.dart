/// Abstract authentication service interface.
///
/// TLDR:
/// Overview: Defines the required methods for any auth implementation.
/// Problem: Need to decouple the UI from specific auth providers (GCP, etc).
/// Solution: Declares an abstract AuthService class (implementation currently in app.dart).
/// Breaking Changes: No.
///
/// ---------------------------------------------------------------------------

abstract class AuthService {
  Future<bool> signIn();
  Future<void> signOut();
  bool get isSignedIn;
}

// GoogleAuthService (google_sign_in) removed — Linux desktop uses the
// googleapis_auth loopback flow directly in HappeningApp. See app.dart.
