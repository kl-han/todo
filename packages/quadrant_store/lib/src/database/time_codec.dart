/// Timestamp storage format: fixed-width UTC ISO-8601 with microseconds
/// (`2026-01-02T03:04:05.000006Z`). Fixed width makes lexicographic
/// comparison equal to chronological comparison, which the matrix sort's
/// `updated_at ASC` term relies on inside SQLite.
String encodeTime(DateTime time) {
  final utc = time.toUtc();
  String pad(int n, int width) => n.toString().padLeft(width, '0');
  final micros =
      utc.millisecond * 1000 + utc.microsecond;
  return '${pad(utc.year, 4)}-${pad(utc.month, 2)}-${pad(utc.day, 2)}'
      'T${pad(utc.hour, 2)}:${pad(utc.minute, 2)}:${pad(utc.second, 2)}'
      '.${pad(micros, 6)}Z';
}

DateTime decodeTime(String value) => DateTime.parse(value);

DateTime? decodeTimeOrNull(Object? value) =>
    value == null ? null : decodeTime(value as String);
