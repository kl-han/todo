import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:quadrant_backend_host/quadrant_backend_host.dart';

/// A running backend under conformance test, however it is hosted.
abstract interface class BackendHarness {
  /// Human-readable name, used in test descriptions.
  String get label;

  /// `embedded` or `standalone`, as reported by the health route.
  String get expectedBackendKind;

  Uri get baseUrl;

  /// Full Authorization header value for authenticated requests.
  String get authorization;

  Future<void> stop();
}

/// Runs the backend in-process as the real embedded isolate.
class EmbeddedBackendHarness implements BackendHarness {
  EmbeddedBackendHarness._(this._backend);

  static Future<EmbeddedBackendHarness> start() async =>
      EmbeddedBackendHarness._(await EmbeddedBackend.start());

  final EmbeddedBackend _backend;

  @override
  String get label => 'embedded backend';

  @override
  String get expectedBackendKind => 'embedded';

  @override
  Uri get baseUrl => _backend.baseUrl;

  @override
  String get authorization => _backend.authorization;

  @override
  Future<void> stop() => _backend.stop();
}

/// Runs `server/bin/quadrant_server.dart` as a real separate OS process,
/// exactly as an operator would.
class StandaloneBackendHarness implements BackendHarness {
  StandaloneBackendHarness._(this._process, this.baseUrl, this._token);

  /// [serverDir] is the path to the `server/` package. Defaults to the
  /// location relative to this package within the repository.
  static Future<StandaloneBackendHarness> start({String? serverDir}) async {
    final dir = serverDir ?? _defaultServerDir();
    final token = LocalSessionToken.generate();
    final process = await Process.start(
      Platform.resolvedExecutable,
      ['run', 'bin/quadrant_server.dart', '--port', '0', '--token', token],
      workingDirectory: dir,
    );

    final stdoutLines = process.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .asBroadcastStream();
    // Surface startup failures instead of hanging.
    final stderrBuffer = StringBuffer();
    process.stderr.transform(utf8.decoder).listen(stderrBuffer.write);

    final listeningLine = await stdoutLines
        .firstWhere((line) => line.contains('listening on'))
        .timeout(
          const Duration(seconds: 30),
          onTimeout: () {
            process.kill();
            throw StateError(
              'quadrant_server did not start: $stderrBuffer',
            );
          },
        );

    final url = Uri.parse(listeningLine.split('listening on ').last.trim());
    return StandaloneBackendHarness._(process, url, token);
  }

  static String _defaultServerDir() {
    // Tests run with the package directory as cwd; the server package is a
    // sibling of packages/ at the repository root.
    final root = Directory.current.path;
    return '$root/../../server';
  }

  final Process _process;
  final String _token;

  @override
  final Uri baseUrl;

  @override
  String get label => 'standalone server';

  @override
  String get expectedBackendKind => 'standalone';

  @override
  String get authorization => 'Bearer $_token';

  @override
  Future<void> stop() async {
    _process.kill(ProcessSignal.sigterm);
    await _process.exitCode.timeout(
      const Duration(seconds: 5),
      onTimeout: () {
        _process.kill(ProcessSignal.sigkill);
        return _process.exitCode;
      },
    );
  }
}
