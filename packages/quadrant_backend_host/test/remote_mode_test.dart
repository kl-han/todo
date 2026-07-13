import 'dart:io';

import 'package:quadrant_backend_host/quadrant_backend_host.dart';
import 'package:test/test.dart';

void main() {
  group('BackendSettings / SettingsStore', () {
    late Directory dir;

    setUp(() => dir = Directory.systemTemp.createTempSync('quadrant-set-'));
    tearDown(() => dir.deleteSync(recursive: true));

    test('defaults to local mode when no file exists', () {
      final store = SettingsStore('${dir.path}/settings.json');
      expect(store.load().mode, BackendMode.local);
    });

    test('round-trips remote settings', () {
      final store = SettingsStore('${dir.path}/settings.json');
      store.save(BackendSettings.remote(
        remoteUrl: Uri.parse('https://todo.example.net'),
        remoteVault: 'personal',
      ));

      final loaded = store.load();
      expect(loaded.mode, BackendMode.remote);
      expect(loaded.remoteUrl, Uri.parse('https://todo.example.net'));
      expect(loaded.remoteVault, 'personal');
      expect(loaded.remoteProfile.vaultId, 'personal');
    });

    test('corrupt settings fall back to local mode, never crash', () {
      final path = '${dir.path}/settings.json';
      for (final garbage in ['not json', '[]', '{"mode":"remote"}}}']) {
        File(path).writeAsStringSync(garbage);
        expect(SettingsStore(path).load().mode, BackendMode.local,
            reason: garbage);
      }
    });
  });

  group('diagnoseRemoteBackend', () {
    // The embedded backend accepts Bearer tokens too, so it stands in for
    // a real standalone server without process management.
    late EmbeddedBackend backend;

    setUpAll(() async => backend = await EmbeddedBackend.start());
    tearDownAll(() => backend.stop());

    RemoteBackendProfile profile({String vault = 'default'}) =>
        RemoteBackendProfile(baseUrl: backend.baseUrl, vaultId: vault);

    test('all checks pass against a healthy server', () async {
      final result = await diagnoseRemoteBackend(profile(), backend.token);
      expect(result.ok, isTrue, reason: result.detail ?? '');
    });

    test('unreachable server fails the first check with detail', () async {
      final result = await diagnoseRemoteBackend(
        RemoteBackendProfile(
          baseUrl: Uri.parse('http://127.0.0.1:9'),
          vaultId: 'default',
        ),
        'whatever',
      );
      expect(result.reachable, isFalse);
      expect(result.ok, isFalse);
      expect(result.detail, contains('unreachable'));
    });

    test('a bad credential is reported as rejected, not unreachable',
        () async {
      final result = await diagnoseRemoteBackend(profile(), 'wrong-token');
      expect(result.reachable, isTrue);
      expect(result.authenticated, isFalse);
      expect(result.detail, contains('rejected'));
    });

    test('a missing vault is reported with the available names', () async {
      final result = await diagnoseRemoteBackend(
        profile(vault: 'nope'),
        backend.token,
      );
      expect(result.reachable, isTrue);
      expect(result.authenticated, isTrue);
      expect(result.apiVersionSupported, isTrue);
      expect(result.vaultExists, isFalse);
      expect(result.detail, contains('default'));
    });
  });
}
