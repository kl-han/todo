import 'dart:io';
import 'dart:math';

/// The per-install credential for the agent's loopback API
/// (`Authorization: Bearer <token>`). Created on first run, mode 0600,
/// and reused thereafter so the GUI can authenticate across agent
/// restarts.
class AgentCredential {
  AgentCredential._(this.token, this.path);

  final String token;
  final String path;

  static const _alphabet =
      'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_';

  static Future<AgentCredential> load(String path) async {
    final file = File(path);
    if (file.existsSync()) {
      final token = (await file.readAsString()).trim();
      if (token.isNotEmpty) return AgentCredential._(token, path);
    }
    Directory(file.parent.path).createSync(recursive: true);
    final random = Random.secure();
    final token = String.fromCharCodes([
      for (var i = 0; i < 43; i++)
        _alphabet.codeUnitAt(random.nextInt(_alphabet.length)),
    ]);
    await file.writeAsString(token);
    // Owner-only, like the server token file convention. Best-effort on
    // platforms without chmod.
    if (!Platform.isWindows) {
      await Process.run('chmod', ['600', path]);
    }
    return AgentCredential._(token, path);
  }
}
