/// Response body of `GET /api/v1/health`.
class HealthReport {
  const HealthReport({
    required this.status,
    required this.apiVersion,
    required this.schemaVersion,
    required this.backend,
  });

  factory HealthReport.fromJson(Map<String, Object?> json) => HealthReport(
        status: json['status'] as String,
        apiVersion: json['api_version'] as String,
        schemaVersion: json['schema_version'] as int,
        backend: json['backend'] as String,
      );

  final String status;
  final String apiVersion;
  final int schemaVersion;
  final String backend;

  bool get isReady => status == 'ok';
}
