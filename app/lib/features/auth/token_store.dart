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

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

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

/// OS keychain-backed token storage (macOS Keychain, Windows DPAPI, Linux libsecret).
class FlutterSecureTokenStore implements TokenStore {
  FlutterSecureTokenStore() : _storage = const FlutterSecureStorage();
  final FlutterSecureStorage _storage;

  @override
  Future<void> write({required String key, required String value}) =>
      _storage.write(key: key, value: value);

  @override
  Future<String?> read({required String key}) => _storage.read(key: key);

  @override
  Future<void> delete({required String key}) => _storage.delete(key: key);
}
