// Abstract token storage interface.
//
// TLDR:
// Overview: Defines how auth tokens should be persisted on disk.
// Problem: Need to swap between insecure and secure storage based on platform capabilities.
// Solution: Declares the TokenStore abstract class (implementation currently in app.dart).
// Breaking Changes: No.
//
// ---------------------------------------------------------------------------

import 'dart:io';

/// Abstract token storage interface.
///
/// TLDR:
/// Overview: Defines how auth tokens should be persisted on disk.
/// Problem: Need to swap between insecure and secure storage based on platform capabilities.
/// Solution: Declares the TokenStore abstract class with a File-based implementation.
/// Breaking Changes: No.
///
/// ---------------------------------------------------------------------------

abstract class TokenStore {
  Future<void> write({required String key, required String value});
  Future<String?> read({required String key});
  Future<void> delete({required String key});
}

/// Simple JSON file-based token storage.
class FileTokenStore implements TokenStore {
  FileTokenStore({required Directory directory}) : _dir = directory;

  final Directory _dir;

  Future<File> _file(String key) async {
    if (!_dir.existsSync()) await _dir.create(recursive: true);
    return File('${_dir.path}/$key.json');
  }

  @override
  Future<void> write({required String key, required String value}) async {
    final file = await _file(key);
    await file.writeAsString(value);
  }

  @override
  Future<String?> read({required String key}) async {
    final file = await _file(key);
    if (!file.existsSync()) return null;
    return file.readAsString();
  }

  @override
  Future<void> delete({required String key}) async {
    final file = await _file(key);
    if (file.existsSync()) await file.delete();
  }
}

// FlutterSecureTokenStore will be added back when flutter_secure_storage
// ships a json.hpp compatible with LLVM 20 (tracked: Sprint 3 / S3-token).
