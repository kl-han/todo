import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../config.dart';
import '../handlers/health_handler.dart';
import '../handlers/vault_routes.dart';
import '../middleware/auth_middleware.dart';
import '../middleware/problem_middleware.dart';
import '../problem.dart';

/// Builds the complete API handler. Every backend — embedded isolate and
/// standalone server — serves exactly this handler; route differences
/// between backends are prohibited.
Handler buildApiHandler(ApiServerConfig config) {
  final router = Router(notFoundHandler: notFoundProblem)
    ..get('/api/v1/health', healthHandler(config))
    ..get('/api/v1/capabilities', (Request request) {
      return Response.ok(
        jsonEncode({
          'api_version': 'v1',
          'schema_version': config.schemaVersion,
          'features': [
            'tasks',
            'tags',
            'quadrants',
            'vaults',
            'etag-concurrency',
            'soft-delete-restore',
            'temporal',
            'agenda',
          ],
        }),
        headers: {'content-type': 'application/json'},
      );
    })
    ..get('/api/v1/vaults', (Request request) {
      return Response.ok(
        jsonEncode({
          'vaults': [
            for (final name in config.listVaults()) {'id': name},
          ],
        }),
        headers: {'content-type': 'application/json'},
      );
    });
  mountVaultRoutes(router, config);

  return const Pipeline()
      .addMiddleware(authMiddleware(config.authToken))
      .addMiddleware(problemMiddleware())
      .addHandler(router.call);
}
