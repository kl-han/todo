import 'package:shelf/shelf.dart';

import 'problem.dart';

/// Entity tags are the resource version in quotes: `"7"`.
String etagOf(int version) => '"$version"';

/// Parses an `If-Match` header into an expected version. Absent header
/// means an unconditional request (null). A malformed header — anything
/// but a single strong ETag in version syntax — is a 400.
int? expectedVersionFrom(Request request) {
  final header = request.headers['if-match'];
  if (header == null) return null;
  final match = RegExp(r'^\s*"(\d+)"\s*$').firstMatch(header);
  if (match == null) {
    throw MalformedRequestError(
      'If-Match must be a single strong ETag like "7".',
    );
  }
  return int.parse(match.group(1)!);
}

/// Thrown by request parsing; mapped to a 400 validation problem.
class MalformedRequestError extends Error {
  MalformedRequestError(this.message);

  final String message;
}

Response withEtag(Response response, int version) =>
    response.change(headers: {'etag': etagOf(version)});

Response preconditionFailedProblem(int currentVersion) => problemResponse(
      status: 412,
      type: 'problems/version-conflict',
      title: 'Precondition Failed',
      detail: 'The resource has changed; current version is $currentVersion.',
      extensions: {'current_version': currentVersion},
    );
