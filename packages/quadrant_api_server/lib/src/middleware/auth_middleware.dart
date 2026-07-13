import 'package:shelf/shelf.dart';

import '../problem.dart';

/// Routes that may be called without credentials. Health must stay open so
/// clients can poll readiness before they hold a token-authenticated client.
const _openPaths = {'api/v1/health'};

/// Requires `Authorization: Local <token>` or `Authorization: Bearer <token>`
/// on every route except [_openPaths]. A null [token] disables the check
/// (unit tests only); production callers always pass one.
Middleware authMiddleware(String? token) {
  return (inner) {
    return (request) {
      if (token == null || _openPaths.contains(request.url.path)) {
        return inner(request);
      }
      final header = request.headers['authorization'];
      if (header == 'Local $token' || header == 'Bearer $token') {
        return inner(request);
      }
      return unauthenticatedProblem();
    };
  };
}
