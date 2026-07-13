import '../repositories.dart';
import 'agenda_service.dart';
import 'focus_service.dart';
import 'planning_service.dart';
import 'quadrant_service.dart';
import 'recurrence_service.dart';
import 'reminder_service.dart';
import 'tag_service.dart';
import 'task_service.dart';
import 'weekly_review_service.dart';

/// The full application service set for one vault. Backends construct one
/// per vault and hand it to the REST routing layer.
class AppServices {
  AppServices({
    required TaskRepository taskRepository,
    required TagRepository tagRepository,
    required RecurrenceRepository recurrenceRepository,
    required ReminderRepository reminderRepository,
    required FocusSessionRepository focusSessionRepository,
    required PlanningRepository planningRepository,
    required ReportRepository reportRepository,
    DateTime Function()? clock,
  })  : tasks = TaskService(taskRepository, tagRepository, clock: clock),
        tags = TagService(tagRepository, taskRepository, clock: clock),
        quadrants = QuadrantService(taskRepository),
        agenda = AgendaService(taskRepository),
        recurrence =
            RecurrenceService(taskRepository, recurrenceRepository, clock: clock),
        reminders = ReminderService(
            reminderRepository, taskRepository, recurrenceRepository,
            clock: clock),
        focus = FocusService(
            focusSessionRepository, taskRepository, recurrenceRepository,
            clock: clock),
        planning = PlanningService(planningRepository, taskRepository,
            recurrenceRepository, focusSessionRepository,
            clock: clock),
        weeklyReview = WeeklyReviewService(taskRepository,
            recurrenceRepository, focusSessionRepository,
            planningRepository, reportRepository,
            clock: clock);

  final TaskService tasks;
  final TagService tags;
  final QuadrantService quadrants;
  final AgendaService agenda;
  final RecurrenceService recurrence;
  final ReminderService reminders;
  final FocusService focus;
  final PlanningService planning;
  final WeeklyReviewService weeklyReview;
}
