/// Eisenhower quadrant. Always derived from the urgency and importance
/// flags — never stored, never set directly.
enum Quadrant {
  /// Urgent and important.
  q1(1),

  /// Important, not urgent.
  q2(2),

  /// Urgent, not important.
  q3(3),

  /// Neither urgent nor important.
  q4(4);

  const Quadrant(this.number);

  final int number;

  static Quadrant derive({required bool isUrgent, required bool isImportant}) {
    if (isUrgent && isImportant) return q1;
    if (isImportant) return q2;
    if (isUrgent) return q3;
    return q4;
  }

  static Quadrant fromNumber(int number) =>
      values.firstWhere((q) => q.number == number);
}
