import 'dart:convert';

import 'package:shelf/shelf.dart';

import '../config.dart';

/// GET /api/v1/health — process readiness. See `api/openapi.yaml`.
Handler healthHandler(ApiServerConfig config) {
  return (Request request) {
    return Response.ok(
      jsonEncode({
        'status': 'ok',
        'api_version': 'v1',
        'schema_version': config.schemaVersion,
        'backend': config.backendKind.wireName,
      }),
      headers: {'content-type': 'application/json'},
    );
  };
}
