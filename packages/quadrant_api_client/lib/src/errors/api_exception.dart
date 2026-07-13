/// The backend could not be reached at the transport level (connection
/// refused, DNS failure, timeout). In remote mode the UI presents this as an
/// explicit offline state; it never falls back to another backend.
class ApiUnavailableException implements Exception {
  ApiUnavailableException(this.baseUrl, [this.cause]);

  final Uri baseUrl;
  final Object? cause;

  @override
  String toString() =>
      'ApiUnavailableException: could not reach $baseUrl'
      '${cause == null ? '' : ' ($cause)'}';
}

/// The backend answered with an RFC 9457 Problem Details error body.
class ProblemDetailsException implements Exception {
  ProblemDetailsException({
    required this.status,
    required this.type,
    required this.title,
    this.detail,
    this.instance,
  });

  factory ProblemDetailsException.fromJson(Map<String, Object?> json) =>
      ProblemDetailsException(
        status: json['status'] as int? ?? 0,
        type: json['type'] as String? ?? 'about:blank',
        title: json['title'] as String? ?? '',
        detail: json['detail'] as String?,
        instance: json['instance'] as String?,
      );

  final int status;
  final String type;
  final String title;
  final String? detail;
  final String? instance;

  @override
  String toString() =>
      'ProblemDetailsException($status $title, type: $type'
      '${detail == null ? '' : ', detail: $detail'})';
}

/// The backend answered with a non-problem, non-2xx response — a contract
/// violation worth surfacing distinctly.
class UnexpectedResponseException implements Exception {
  UnexpectedResponseException(this.statusCode, this.body);

  final int statusCode;
  final String body;

  @override
  String toString() => 'UnexpectedResponseException($statusCode): $body';
}
