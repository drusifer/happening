/// Abstract token storage interface.
///
/// TLDR:
/// Overview: Defines how auth tokens should be persisted on disk.
/// Problem: Need to swap between insecure and secure storage based on platform capabilities.
/// Solution: Declares the TokenStore abstract class (implementation currently in app.dart).
/// Breaking Changes: No.
///
/// ---------------------------------------------------------------------------

abstract class TokenStore {
  Future<void> write({required String key, required String value});
  Future<String?> read({required String key});
  Future<void> delete({required String key});
}

// FlutterSecureTokenStore will be added back when flutter_secure_storage
// ships a json.hpp compatible with LLVM 20 (tracked: Sprint 3 / S3-token).
