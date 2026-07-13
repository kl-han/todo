/// Configuration for remote mode: the same REST client pointed at a
/// standalone server instead of the embedded loopback backend.
///
/// The credential itself is not stored here — it lives in the platform's
/// secure storage (iOS Keychain; Linux Secret Service or a 0600 file) and
/// is resolved at bootstrap time.
class RemoteBackendProfile {
  const RemoteBackendProfile({
    required this.baseUrl,
    required this.vaultId,
  });

  final Uri baseUrl;
  final String vaultId;

  String get credentialKey => 'quadrant-todo/${baseUrl.host}/$vaultId';
}
