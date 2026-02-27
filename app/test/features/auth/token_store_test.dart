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

    test('write overwrites existing value', () async {
      await store.write(key: 'token', value: 'old');
      await store.write(key: 'token', value: 'new');
      expect(await store.read(key: 'token'), equals('new'));
    });

    test('keys are independent', () async {
      await store.write(key: 'a', value: '1');
      await store.write(key: 'b', value: '2');
      expect(await store.read(key: 'a'), equals('1'));
      expect(await store.read(key: 'b'), equals('2'));
    });

    test('delete of nonexistent key is silent', () async {
      await expectLater(store.delete(key: 'missing'), completes);
    });
  });
}
