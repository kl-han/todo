/// How one side (start or due) of a task's schedule is expressed: not at
/// all, as a plain calendar date, or as an absolute instant in the task's
/// timezone. The two representations never convert into each other.
enum ScheduleKind {
  none,
  date,
  datetime;

  String get wireName => name;

  static ScheduleKind fromWire(String value) => switch (value) {
        'none' => none,
        'date' => date,
        'datetime' => datetime,
        _ => throw ArgumentError.value(value, 'value', 'unknown schedule kind'),
      };
}
