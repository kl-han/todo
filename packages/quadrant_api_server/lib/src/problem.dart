import 'dart:convert';

import 'package:shelf/shelf.dart';

/// RFC 9457 Problem Details response builder. All error responses across
/// the API go through this; there is no other error envelope.
Response problemResponse({
  required int status,
  required String title,
  String type = 'about:blank',
  String? detail,
  String? instance,
  Map<String, Object?> extensions = const {},
}) {
  return Response(
    status,
    body: jsonEncode({
      'type': type,
      'title': title,
      'status': status,
      'detail': ?detail,
      'instance': ?instance,
      ...extensions,
    }),
    headers: {'content-type': 'application/problem+json'},
  );
}

Response notFoundProblem(Request request) => problemResponse(
      status: 404,
      type: 'problems/not-found',
      title: 'Not Found',
      detail: 'No resource at /${request.url.path}.',
      instance: '/${request.url.path}',
    );

Response unauthenticatedProblem() => problemResponse(
      status: 401,
      type: 'problems/unauthenticated',
      title: 'Unauthenticated',
      detail: 'A valid Authorization header is required.',
    );
