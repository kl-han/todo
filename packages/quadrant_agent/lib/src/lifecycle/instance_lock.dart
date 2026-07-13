import 'dart:io';

/// A single-instance guard: an advisory exclusive lock on a file. The
/// lock dies with the process, so a crashed agent never leaves a stale
/// lock behind (unlike pid files).
class InstanceLock {
  InstanceLock._(this._file, this.path);

  final RandomAccessFile _file;
  final String path;

  /// POSIX advisory locks are per-process (a process can re-lock its own
  /// file), so in-process double-acquire is tracked separately.
  static final Set<String> _heldInProcess = {};

  /// Acquires the lock or throws [StateError] when another live agent
  /// holds it.
  static InstanceLock acquire(String path) {
    if (_heldInProcess.contains(path)) {
      throw StateError(
        'This process already holds the agent lock $path.',
      );
    }
    Directory(File(path).parent.path).createSync(recursive: true);
    final file = File(path).openSync(mode: FileMode.write);
    try {
      file.lockSync(FileLock.exclusive);
    } on FileSystemException {
      file.closeSync();
      throw StateError(
        'Another quadrant-agent instance already holds $path.',
      );
    }
    _heldInProcess.add(path);
    return InstanceLock._(file, path);
  }

  void release() {
    try {
      _file.unlockSync();
    } finally {
      _file.closeSync();
      _heldInProcess.remove(path);
    }
  }
}
