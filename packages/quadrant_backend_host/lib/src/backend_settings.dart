import 'dart:convert';
import 'dart:io';

import 'backend_lifecycle.dart';
import 'remote_profile.dart';

/// Persisted backend selection: which mode the app boots into and, for
/// remote mode, where the server lives. The credential itself is NOT here
/// — it belongs to the platform's [CredentialStore].
class BackendSettings {
  const BackendSettings.local()
      : mode = BackendMode.local,
        remoteUrl = null,
        remoteVault = 'default';

  const BackendSettings.remote({
    required Uri this.remoteUrl,
    this.remoteVault = 'default',
  }) : mode = BackendMode.remote;

  final BackendMode mode;
  final Uri? remoteUrl;
  final String remoteVault;

  RemoteBackendProfile get remoteProfile =>
      RemoteBackendProfile(baseUrl: remoteUrl!, vaultId: remoteVault);

  factory BackendSettings.fromJson(Map<String, Object?> json) {
    final mode = json['mode'] as String? ?? 'local';
    if (mode == 'remote') {
      return BackendSettings.remote(
        remoteUrl: Uri.parse(json['remote_url'] as String),
        remoteVault: json['remote_vault'] as String? ?? 'default',
      );
    }
    return const BackendSettings.local();
  }

  Map<String, Object?> toJson() => {
        'mode': mode.name,
        'remote_url': ?remoteUrl?.toString(),
        'remote_vault': remoteVault,
      };
}

/// JSON-file persistence for [BackendSettings]. A corrupt or unreadable
/// file falls back to local mode — the app must always be able to boot.
class SettingsStore {
  SettingsStore(this.path);

  final String path;

  BackendSettings load() {
    final file = File(path);
    if (!file.existsSync()) return const BackendSettings.local();
    try {
      final decoded = jsonDecode(file.readAsStringSync());
      if (decoded is! Map<String, Object?>) {
        return const BackendSettings.local();
      }
      return BackendSettings.fromJson(decoded);
    } on FormatException {
      return const BackendSettings.local();
    } on FileSystemException {
      return const BackendSettings.local();
    }
  }

  void save(BackendSettings settings) {
    final file = File(path);
    file.parent.createSync(recursive: true);
    file.writeAsStringSync(jsonEncode(settings.toJson()), flush: true);
  }
}
