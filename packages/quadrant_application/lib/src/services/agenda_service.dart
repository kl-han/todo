import 'dart:collection';

import 'package:quadrant_domain/quadrant_domain.dart';
import 'package:timezone/timezone.dart' as tz;

import '../queries/agenda.dart';
import '../queries/task_query.dart';
import '../repositories.dart';
import '../temporal/timezones.dart';

/// Maximum agenda range, inclusive of both endpoints.
const int maxAgendaRangeDays = 366;

/// The agenda read model: scheduled tasks grouped by task-local calendar
/// date. Date-only values contribute their stored date unchanged;
/// date-time values contribute the date of the stored instant rendered in
/// the task's own timezone — never the server's.
class AgendaService {
  AgendaService(this._tasks);

  final TaskRepository _tasks;

  AgendaReport agenda({
    required PlainDate from,
    required PlainDate to,
    StatusFilter status = StatusFilter.open,
  }) {
    if (to.isBefore(from)) {
      throw DomainValidationError('"to" must be on or after "from".');
    }
    if (to.differenceInDays(from) >= maxAgendaRangeDays) {
      throw DomainValidationError(
        'Agenda range must not exceed $maxAgendaRangeDays days.',
      );
    }

    final byDate = SplayTreeMap<PlainDate, List<AgendaEntry>>();
    void add(PlainDate date, AgendaEntry entry) {
      if (date.isBefore(from) || date.isAfter(to)) return;
      byDate.putIfAbsent(date, () => []).add(entry);
    }

    for (final task in _tasks.scheduled(status)) {
      final schedule = task.schedule;
      final start = _localize(
        AgendaEntryKind.start,
        task,
        schedule.startKind,
        schedule.startDate,
        schedule.startAtUtc,
      );
      if (start != null) add(start.$1, start.$2);
      final due = _localize(
        AgendaEntryKind.due,
        task,
        schedule.dueKind,
        schedule.dueDate,
        schedule.dueAtUtc,
      );
      if (due != null) add(due.$1, due.$2);
    }

    return AgendaReport(
      from: from,
      to: to,
      status: status.name,
      days: [
        for (final entry in byDate.entries)
          AgendaDay(date: entry.key, entries: _sorted(entry.value)),
      ],
    );
  }

  (PlainDate, AgendaEntry)? _localize(
    AgendaEntryKind kind,
    Task task,
    ScheduleKind scheduleKind,
    PlainDate? date,
    DateTime? atUtc,
  ) {
    switch (scheduleKind) {
      case ScheduleKind.none:
        return null;
      case ScheduleKind.date:
        return (date!, AgendaEntry(kind: kind, task: task));
      case ScheduleKind.datetime:
        final local = tz.TZDateTime.from(
          atUtc!,
          resolveTimezone(task.schedule.timezoneId!),
        );
        String pad(int n) => n.toString().padLeft(2, '0');
        return (
          PlainDate(local.year, local.month, local.day),
          AgendaEntry(
            kind: kind,
            task: task,
            timeLocal: '${pad(local.hour)}:${pad(local.minute)}',
          ),
        );
    }
  }

  /// All-day entries first, then ascending wall-clock time, then task id,
  /// then start before due — a total order so both backends agree.
  static List<AgendaEntry> _sorted(List<AgendaEntry> entries) {
    entries.sort((a, b) {
      if ((a.timeLocal == null) != (b.timeLocal == null)) {
        return a.timeLocal == null ? -1 : 1;
      }
      if (a.timeLocal != null) {
        final byTime = a.timeLocal!.compareTo(b.timeLocal!);
        if (byTime != 0) return byTime;
      }
      final byId = a.task.id.compareTo(b.task.id);
      if (byId != 0) return byId;
      return a.kind.index.compareTo(b.kind.index);
    });
    return entries;
  }
}
