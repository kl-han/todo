/// Shared REST boundary for Quadrant Todo.
///
/// Both the embedded loopback backend and the standalone server build their
/// HTTP handler from [buildApiHandler]; there is exactly one implementation
/// of every route.
library;

export 'src/config.dart';
export 'src/etag.dart';
export 'src/middleware/auth_middleware.dart';
export 'src/problem.dart';
export 'src/routing/api_router.dart';
