import 'dart:convert';
import 'dart:math';

/// Random per-launch credential for the embedded loopback backend.
///
/// 256 bits from a cryptographically secure source, base64url-encoded.
/// The token lives only in memory: it is generated at backend startup,
/// handed to the UI isolate, and never persisted anywhere.
class LocalSessionToken {
  static String generate() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    return base64UrlEncode(bytes).replaceAll('=', '');
  }
}
