/// Response body of `GET /api/v1/capabilities` — what the backend can do,
/// used by remote-mode negotiation before trusting a server.
class Capabilities {
  const Capabilities({
    required this.apiVersion,
    required this.schemaVersion,
    required this.features,
  });

  factory Capabilities.fromJson(Map<String, Object?> json) => Capabilities(
        apiVersion: json['api_version'] as String,
        schemaVersion: json['schema_version'] as int,
        features: (json['features'] as List<Object?>).cast<String>(),
      );

  final String apiVersion;
  final int schemaVersion;
  final List<String> features;

  bool get supportsV1 => apiVersion == 'v1';
}
