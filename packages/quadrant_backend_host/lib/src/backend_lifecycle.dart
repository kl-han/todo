import 'dart:async';

import 'package:quadrant_api_client/quadrant_api_client.dart';

/// Which kind of backend the application is connected to.
enum BackendMode { local, remote }

/// A live, health-checked connection to a backend, however it is hosted.
/// Bootstrap code produces one of these; presentation code consumes only
/// the [client] and never learns how the backend is hosted.
class BackendConnection {
  BackendConnection({
    required this.mode,
    required this.client,
    this.shutdown,
    this.restart,
  });

  final BackendMode mode;
  final QuadrantApiClient client;

  /// Stops a backend this process owns (local mode only).
  final Future<void> Function()? shutdown;

  /// Restarts the backend and returns the replacement connection. Used on
  /// app resume when the embedded backend died with the suspended process.
  final Future<BackendConnection> Function()? restart;

  /// Verifies the backend still answers; if not, attempts [restart] when
  /// available (local mode), otherwise rethrows so remote mode can surface
  /// an explicit offline state — never a silent fallback.
  Future<BackendConnection> ensureHealthy({
    Duration timeout = const Duration(seconds: 2),
  }) async {
    try {
      await client.waitUntilHealthy(timeout: timeout);
      return this;
    } on ApiUnavailableException {
      final restart = this.restart;
      if (restart != null) return restart();
      rethrow;
    }
  }
}
