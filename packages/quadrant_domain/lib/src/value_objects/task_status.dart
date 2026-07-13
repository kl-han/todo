/// Observable task status. Derived from `completed_at`: a task is
/// completed exactly when its completion timestamp is set.
enum TaskStatus {
  open,
  completed;

  String get wireName => name;

  static TaskStatus fromWire(String value) => switch (value) {
        'open' => open,
        'completed' => completed,
        _ => throw ArgumentError.value(value, 'value', 'unknown task status'),
      };
}
