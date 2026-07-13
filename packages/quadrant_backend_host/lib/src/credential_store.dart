import 'dart:io';

/// Secure storage for remote-mode credentials, keyed by
/// [RemoteBackendProfile.credentialKey]-style identifiers.
///
/// Implementations:
/// * iOS: Keychain (plugin-backed, wired in the app when remote mode
///   ships in v0.7).
/// * Linux: Secret Service when available; otherwise [FileCredentialStore]
///   with 0600 permissions.
/// * Tests: [InMemoryCredentialStore].
///
/// The embedded backend's per-launch token is deliberately NOT stored
/// here or anywhere else.
abstract interface class CredentialStore {
  Future<String?> read(String key);

  Future<void> write(String key, String secret);

  Future<void> delete(String key);
}

/// Volatile store for tests and previews.
class InMemoryCredentialStore implements CredentialStore {
  final Map<String, String> _secrets = {};

  @override
  Future<String?> read(String key) async => _secrets[key];

  @override
  Future<void> write(String key, String secret) async =>
      _secrets[key] = secret;

  @override
  Future<void> delete(String key) async => _secrets.remove(key);
}

/// Plain-file fallback for Linux systems without a Secret Service.
/// One file per credential under [directory], created with 0600
/// permissions (owner read/write only); the directory itself is 0700.
class FileCredentialStore implements CredentialStore {
  FileCredentialStore(this.directory);

  final String directory;

  File _fileFor(String key) {
    // Keys may contain '/' (host/vault); flatten to a safe file name.
    final name = key.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
    return File('$directory/$name.secret');
  }

  Future<void> _ensureDirectory() async {
    final dir = Directory(directory);
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
      await Process.run('chmod', ['700', directory]);
    }
  }

  @override
  Future<String?> read(String key) async {
    final file = _fileFor(key);
    if (!file.existsSync()) return null;
    try {
      return (await file.readAsString()).trim();
    } on FileSystemException {
      // Unreadable credential == missing credential; the caller falls
      // back to asking for it rather than crashing at boot.
      return null;
    }
  }

  @override
  Future<void> write(String key, String secret) async {
    await _ensureDirectory();
    final file = _fileFor(key);
    await file.writeAsString(secret, flush: true);
    final result = await Process.run('chmod', ['600', file.path]);
    if (result.exitCode != 0) {
      throw FileSystemException(
        'Could not restrict credential file permissions',
        file.path,
      );
    }
  }

  @override
  Future<void> delete(String key) async {
    final file = _fileFor(key);
    if (file.existsSync()) await file.delete();
  }
}
