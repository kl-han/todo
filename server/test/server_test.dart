import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:quadrant_application/quadrant_application.dart';
import 'package:quadrant_server/quadrant_server.dart';
import 'package:quadrant_store/quadrant_store.dart';
import 'package:test/test.dart';

void main() {
  group('VaultManager', () {
    late Directory dir;
    late VaultManager manager;

    setUp(() {
      dir = Directory.systemTemp.createTempSync('quadrant-vaults-');
      manager = VaultManager(dir.path);
    });

    tearDown(() {
      manager.closeAll();
      dir.deleteSync(recursive: true);
    });

    test('validates vault names strictly', () {
      for (final good in ['default', 'personal', 'work-2026', 'a_b', '0x']) {
        expect(VaultManager.isValidName(good), isTrue, reason: good);
      }
      for (final bad in [
        '',
        'UPPER',
        '../escape',
        'with space',
        'dot.dot',
        '-leading',
        'a' * 65,
      ]) {
        expect(VaultManager.isValidName(bad), isFalse, reason: bad);
      }
    });

    test('default vault is created on first access', () {
      expect(manager.resolve('default'), isNotNull);
      expect(File(manager.pathFor('default')).existsSync(), isTrue);
    });

    test('other vaults must be created explicitly', () {
      expect(manager.resolve('personal'), isNull);
      manager.create('personal');
      expect(manager.resolve('personal'), isNotNull);
      expect(manager.list(), containsAll(['default', 'personal']));
    });

    test('create rejects duplicates and invalid names', () {
      manager.create('personal');
      expect(() => manager.create('personal'), throwsStateError);
      expect(() => manager.create('../evil'), throwsArgumentError);
    });

    test('vaults are isolated datasets', () {
      manager.create('personal');
      final defaultServices = manager.resolve('default')!;
      final personalServices = manager.resolve('personal')!;

      defaultServices.tasks.create(title: 'only in default');
      expect(
        personalServices.tasks.list(const TaskQuery(status: StatusFilter.all)),
        isEmpty,
      );
    });
  });

  group('serve process', () {
    test(
        'requires a token, serves multiple vaults, lists them, and shuts '
        'down cleanly on SIGTERM', () async {
      final dir = Directory.systemTemp.createTempSync('quadrant-serve-');
      addTearDown(() => dir.deleteSync(recursive: true));

      // vault-create subcommand
      final create = await Process.run(
        Platform.resolvedExecutable,
        [
          'run', 'bin/quadrant_server.dart',
          '--data-dir', dir.path,
          'vault-create', 'personal',
        ],
      );
      expect(create.exitCode, 0, reason: '${create.stderr}');

      // missing token refuses to serve
      final noToken = await Process.run(
        Platform.resolvedExecutable,
        ['run', 'bin/quadrant_server.dart', '--port', '0', '--data-dir',
          dir.path],
      );
      expect(noToken.exitCode, isNot(0));

      // real serve
      final process = await Process.start(
        Platform.resolvedExecutable,
        [
          'run', 'bin/quadrant_server.dart',
          '--port', '0',
          '--token', 'secret',
          '--data-dir', dir.path,
        ],
      );
      final lines = process.stdout
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .asBroadcastStream();
      final listening = await lines
          .firstWhere((l) => l.contains('listening on'))
          .timeout(const Duration(seconds: 30));
      final base = Uri.parse(listening.split('listening on ').last.trim());
      final auth = {'authorization': 'Bearer secret'};

      // vault listing includes both vaults
      final vaults = await http.get(
        base.resolve('/api/v1/vaults'),
        headers: auth,
      );
      expect(vaults.statusCode, 200);
      final ids = [
        for (final vault
            in (jsonDecode(vaults.body)['vaults'] as List<Object?>))
          (vault as Map<String, Object?>)['id'],
      ];
      expect(ids, containsAll(['default', 'personal']));

      // vault isolation over HTTP
      final created = await http.post(
        base.resolve('/api/v1/vaults/personal/tasks'),
        headers: {...auth, 'content-type': 'application/json'},
        body: jsonEncode({'title': 'personal task'}),
      );
      expect(created.statusCode, 201);
      final defaults = await http.get(
        base.resolve('/api/v1/vaults/default/tasks?status=all'),
        headers: auth,
      );
      expect(jsonDecode(defaults.body)['tasks'], isEmpty);

      // unknown vault 404s rather than being created implicitly
      final unknown = await http.get(
        base.resolve('/api/v1/vaults/typo/tasks'),
        headers: auth,
      );
      expect(unknown.statusCode, 404);

      // graceful SIGTERM
      process.kill(ProcessSignal.sigterm);
      final exit = await process.exitCode
          .timeout(const Duration(seconds: 10));
      expect(exit, 0);
    });

    test('backup subcommand produces an openable snapshot', () async {
      final dir = Directory.systemTemp.createTempSync('quadrant-backup-');
      addTearDown(() => dir.deleteSync(recursive: true));

      final manager = VaultManager('${dir.path}/vaults');
      manager.resolve('default')!.tasks.create(title: 'snapshot me');
      manager.closeAll();

      final backupPath = '${dir.path}/snapshot.sqlite3';
      final result = await Process.run(
        Platform.resolvedExecutable,
        [
          'run', 'bin/quadrant_server.dart',
          '--data-dir', '${dir.path}/vaults',
          'backup', 'default', backupPath,
        ],
      );
      expect(result.exitCode, 0, reason: '${result.stderr}');

      final restored = QuadrantDatabase.open(backupPath);
      final titles = restored.db
          .select('SELECT title FROM tasks')
          .map((row) => row['title']);
      expect(titles, ['snapshot me']);
      restored.close();
    });

    test('daemon mode writes a pid file and stops on SIGTERM', () async {
      final dir = Directory.systemTemp.createTempSync('quadrant-daemon-');
      addTearDown(() {
        try {
          dir.deleteSync(recursive: true);
        } on FileSystemException {
          // best effort
        }
      });
      final pidFile = '${dir.path}/server.pid';
      final logFile = '${dir.path}/server.log';

      final launcher = await Process.run(
        Platform.resolvedExecutable,
        [
          'run', 'bin/quadrant_server.dart',
          '--port', '0',
          '--token', 'secret',
          '--data-dir', '${dir.path}/vaults',
          '--daemon',
          '--pid-file', pidFile,
          '--log-file', logFile,
        ],
      );
      expect(launcher.exitCode, 0, reason: '${launcher.stderr}');

      // The detached child needs a moment to boot and write its pid.
      final deadline = DateTime.now().add(const Duration(seconds: 30));
      while (!File(pidFile).existsSync() &&
          DateTime.now().isBefore(deadline)) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }
      expect(File(pidFile).existsSync(), isTrue,
          reason: 'daemon never wrote its pid file');
      final daemonPid = int.parse(File(pidFile).readAsStringSync().trim());

      // Log carries the listening line.
      while (DateTime.now().isBefore(deadline)) {
        if (File(logFile).existsSync() &&
            File(logFile).readAsStringSync().contains('listening on')) {
          break;
        }
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }
      expect(File(logFile).readAsStringSync(), contains('listening on'));

      // SIGTERM stops it and removes the pid file.
      Process.killPid(daemonPid, ProcessSignal.sigterm);
      while (File(pidFile).existsSync() &&
          DateTime.now().isBefore(deadline)) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }
      expect(File(pidFile).existsSync(), isFalse,
          reason: 'daemon did not clean up its pid file');
    });
  }, timeout: const Timeout(Duration(minutes: 3)));
}
