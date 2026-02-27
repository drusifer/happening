import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:happening/features/auth/token_store.dart';

// In-memory fake that satisfies the TokenStore contract.
// Tests here verify any implementation behaves correctly.
class _FakeTokenStore implements TokenStore {
  final _data = <String, String>{};

  @override
  Future<void> write({required String key, required String value}) async =>
      _data[key] = value;

  @override
  Future<String?> read({required String key}) async => _data[key];

  @override
  Future<void> delete({required String key}) async => _data.remove(key);
}

void main() {
  group('TokenStore contract', () {
    late TokenStore store;
    setUp(() => store = _FakeTokenStore());

    test('write then read returns same value', () async {
      await store.write(key: 'access_token', value: 'abc123');
      expect(await store.read(key: 'access_token'), equals('abc123'));
    });

    test('read returns null for unknown key', () async {
      expect(await store.read(key: 'nonexistent'), isNull);
    });

    test('delete removes the stored value', () async {
      await store.write(key: 'token', value: 'xyz');
      await store.delete(key: 'token');
      expect(await store.read(key: 'token'), isNull);
    });
  });

  group('FileTokenStore', () {
    late Directory tempDir;
    late FileTokenStore store;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('happening_test_');
      store = FileTokenStore(directory: tempDir);
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('writes value to a file in the directory', () async {
      await store.write(key: 'auth_token', value: '{"token": "test"}');
      final file = File('${tempDir.path}/auth_token.json');
      expect(await file.exists(), isTrue);
      expect(await file.readAsString(), equals('{"token": "test"}'));
    });

    test('reads value back from file', () async {
      await store.write(key: 'foo', value: 'bar');
      expect(await store.read(key: 'foo'), equals('bar'));
    });

    test('returns null if file does not exist', () async {
      expect(await store.read(key: 'missing'), isNull);
    });

    test('deletes the file', () async {
      await store.write(key: 'to_be_deleted', value: 'gone');
      await store.delete(key: 'to_be_deleted');
      final file = File('${tempDir.path}/to_be_deleted.json');
      expect(await file.exists(), isFalse);
    });

    test('multiple stores share the same directory', () async {
      final store2 = FileTokenStore(directory: tempDir);
      await store.write(key: 'shared', value: 'secret');
      expect(await store2.read(key: 'shared'), equals('secret'));
    });
  });
}
