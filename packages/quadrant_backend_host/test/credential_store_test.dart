import 'dart:io';

import 'package:quadrant_backend_host/quadrant_backend_host.dart';
import 'package:test/test.dart';

void main() {
  group('FileCredentialStore', () {
    late Directory dir;
    late FileCredentialStore store;

    setUp(() {
      dir = Directory.systemTemp.createTempSync('quadrant-cred-');
      store = FileCredentialStore('${dir.path}/credentials');
    });

    tearDown(() => dir.deleteSync(recursive: true));

    test('round-trips secrets', () async {
      await store.write('quadrant-todo/host/personal', 'secret-token');
      expect(
        await store.read('quadrant-todo/host/personal'),
        'secret-token',
      );
    });

    test('returns null for unknown keys', () async {
      expect(await store.read('missing'), isNull);
    });

    test('delete removes the credential', () async {
      await store.write('key', 'value');
      await store.delete('key');
      expect(await store.read('key'), isNull);
    });

    test('credential files are 0600 and the directory 0700', () async {
      await store.write('quadrant-todo/host/personal', 'secret');
      final files = Directory('${dir.path}/credentials')
          .listSync()
          .whereType<File>()
          .toList();
      expect(files, hasLength(1));

      String modeOf(String path) =>
          (Process.runSync('stat', ['-c', '%a', path]).stdout as String)
              .trim();
      expect(modeOf(files.single.path), '600');
      expect(modeOf('${dir.path}/credentials'), '700');
    });

    test('flattens separator characters out of file names', () async {
      await store.write('a/b/c', 'x');
      final names = Directory('${dir.path}/credentials')
          .listSync()
          .map((e) => e.uri.pathSegments.last);
      expect(names, ['a_b_c.secret']);
    });
  });

  group('InMemoryCredentialStore', () {
    test('behaves like a map', () async {
      final store = InMemoryCredentialStore();
      await store.write('k', 'v');
      expect(await store.read('k'), 'v');
      await store.delete('k');
      expect(await store.read('k'), isNull);
    });
  });
}
