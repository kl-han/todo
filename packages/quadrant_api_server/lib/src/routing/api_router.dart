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
    ..get('/api/v1/health', healthHandler(config));
  mountVaultRoutes(router, config);

  return const Pipeline()
      .addMiddleware(authMiddleware(config.authToken))
      .addMiddleware(problemMiddleware())
      .addHandler(router.call);
}
