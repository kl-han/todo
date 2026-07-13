import 'dart:convert';

import 'package:quadrant_application/quadrant_application.dart';
import 'package:quadrant_domain/quadrant_domain.dart';
import 'package:shelf/shelf.dart';

import '../etag.dart';
import '../problem.dart';

/// Maps application and parsing failures onto RFC 9457 problems. This is
/// the single translation point from typed errors to HTTP status codes;
/// handlers just let exceptions fly.
Middleware problemMiddleware() {
  return (inner) {
    return (request) async {
      try {
        return await inner(request);
      } on EntityNotFoundException catch (error) {
        return problemResponse(
          status: 404,
          type: 'problems/not-found',
          title: 'Not Found',
          detail: error.message,
        );
      } on StateConflictException catch (error) {
        return problemResponse(
          status: 409,
          type: 'problems/conflict',
          title: 'Conflict',
          detail: error.message,
        );
      } on VersionConflictException catch (error) {
        return preconditionFailedProblem(error.currentVersion);
      } on DomainValidationError catch (error) {
        return _validationProblem(error.message);
      } on MalformedRequestError catch (error) {
        return _validationProblem(error.message);
      } on FormatException catch (error) {
        return _validationProblem('Malformed request: ${error.message}');
      }
    };
  };
}

Response _validationProblem(String detail) => problemResponse(
      status: 400,
      type: 'problems/validation',
      title: 'Invalid Request',
      detail: detail,
    );

/// Strict JSON body reader: the body must be a JSON object.
Future<Map<String, Object?>> readJsonObject(Request request) async {
  final text = await request.readAsString();
  final Object? decoded;
  try {
    decoded = text.isEmpty ? const <String, Object?>{} : jsonDecode(text);
  } on FormatException {
    throw MalformedRequestError('Request body is not valid JSON.');
  }
  if (decoded is! Map<String, Object?>) {
    throw MalformedRequestError('Request body must be a JSON object.');
  }
  return decoded;
}

/// Typed field access with 400s (never 500s) for wrong shapes.
T? optional<T>(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value == null) return null;
  if (value is T) {
    // ignore: unnecessary_cast — Object? does not promote to T here.
    return value as T;
  }
  throw MalformedRequestError('Field "$key" has the wrong type.');
}

T required_<T>(Map<String, Object?> json, String key) {
  final value = optional<T>(json, key);
  if (value == null) {
    throw MalformedRequestError('Field "$key" is required.');
  }
  return value;
}
