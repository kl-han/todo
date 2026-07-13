import 'dart:io';

import 'package:quadrant_backend_host/quadrant_backend_host.dart';

import 'local_bootstrap.dart';
import 'remote_bootstrap.dart';

/// Where the backend selection and (for the Linux file fallback) remote
/// credentials live.
String configDirectory() {
  final env = Platform.environment;
  if (Platform.isIOS || Platform.isMacOS) {
    return '${env['HOME']}/Library/Application Support/quadrant-todo';
  }
  final base = env['XDG_CONFIG_HOME'] ??
      (env['HOME'] == null ? '.' : '${env['HOME']}/.config');
  return '$base/quadrant-todo';
}

SettingsStore defaultSettingsStore() =>
    SettingsStore('${configDirectory()}/backend.json');

/// Platform credential storage. iOS wires the Keychain implementation
/// here; until then (and on Linux without a Secret Service) the 0600 file
/// store is used.
CredentialStore defaultCredentialStore() =>
    FileCredentialStore('${configDirectory()}/credentials');

/// Boots whichever backend the persisted settings select. Local mode is
/// the default and the fallback for a remote profile whose credential is
/// missing — with [missingCredential] flagged so the UI can say why.
Future<BackendConnection> bootstrapFromSettings({
  SettingsStore? settingsStore,
  CredentialStore? credentialStore,
  void Function()? missingCredential,
}) async {
  final settings = (settingsStore ?? defaultSettingsStore()).load();
  if (settings.mode == BackendMode.local) {
    return bootstrapLocalBackend();
  }

  final credentials = credentialStore ?? defaultCredentialStore();
  final token =
      await credentials.read(settings.remoteProfile.credentialKey);
  if (token == null) {
    missingCredential?.call();
    return bootstrapLocalBackend();
  }
  return bootstrapRemoteBackend(
    profile: settings.remoteProfile,
    bearerToken: token,
  );
}
