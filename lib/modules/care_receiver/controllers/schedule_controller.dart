import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/models/task_model.dart';
import '../../../../core/models/timeline_item.dart';
import '../../../../core/repositories/event_repository.dart';
import '../../../../core/repositories/task_repository.dart';

class ScheduleController extends GetxController {
  final supabase = Supabase.instance.client;

  final RxList<TimelineItem> timeline = <TimelineItem>[].obs;
  final RxBool loading = false.obs;
  final selectedDate = DateTime.now().obs;

  // progress
  int get totalCount =>
      timeline.where((e) => e.type == TimelineType.task).length;

  int get completedCount =>
      timeline.where(
            (e) => e.type == TimelineType.task && e.isCompleted,
      ).length;


  // loading data
  Future<void> loadForCurrentUser(DateTime day) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    loading.value = true;
    timeline.clear();

    try {
      final startOfDay = DateTime(day.year, day.month, day.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final taskRepo = Get.isRegistered<TaskRepository>()
          ? Get.find<TaskRepository>()
          : TaskRepository();
      final eventRepo = Get.isRegistered<EventRepository>()
          ? Get.find<EventRepository>()
          : EventRepository();

      // tasks
      final tasks = await taskRepo.getTasks(user.id);
      final dayKey = DateFormat('yyyy-MM-dd').format(day);

      final taskItems = tasks
          .where((task) => task.datetime != null)
          .where((task) => _shouldAppear(task, day))
          .map((task) => TimelineItem(
                type: TimelineType.task,
                id: task.id ?? 0,
                title: task.title,
                time: DateTime.parse(task.datetime!).toLocal(),
                alarmEnabled: task.alarmEnabled,
                isCompleted: task.repeatType == 'none'
                    ? task.isCompleted
                    : task.completedDates.contains(dayKey),
              ))
          .toList();

      // EVENTS
      final events = await eventRepo.getEvents(user.id);

      final eventItems = events
          .where((e) =>
              e.eventTime.isAfter(startOfDay.subtract(const Duration(seconds: 1))) &&
              e.eventTime.isBefore(endOfDay))
          .map((e) => TimelineItem(
                type: TimelineType.event,
                id: e.id ?? 0,
                title: e.title,
                time: e.eventTime.toLocal(),
              ))
          .toList();

      timeline.assignAll(
        [...taskItems, ...eventItems]
          ..sort((a, b) => a.time.compareTo(b.time)),
      );
    } catch (e) {
      print('❌ Schedule load error: $e');
    } finally {
      loading.value = false;
    }
  }


  // visibility logic
  bool _shouldAppear(TaskModel task, DateTime day) {
    if (task.datetime == null) return false;

    final taskStart = DateTime.parse(task.datetime!).toLocal();

    final taskStartDate = DateTime(
      taskStart.year,
      taskStart.month,
      taskStart.day,
    );

    final targetDate = DateTime(
      day.year,
      day.month,
      day.day,
    );

    //  Never show before task creation date
    if (targetDate.isBefore(taskStartDate)) return false;

    switch (task.repeatType) {
      case 'none':
        return _sameDay(taskStartDate, targetDate);

      case 'tomorrow':
        final tomorrow = taskStartDate.add(const Duration(days: 1));
        return _sameDay(taskStartDate, targetDate) ||
            _sameDay(tomorrow, targetDate);

      case 'daily':
        return true;

      case 'weekly':
        return taskStartDate.weekday == targetDate.weekday;

      case 'custom':
        final weekday = _weekday(targetDate.weekday);

        final normalizedDays = task.repeatDays
            .map((d) => d.toLowerCase().trim())
            .toList();

        return normalizedDays.contains(weekday);

      default:
        return false;
    }
  }


  String _weekday(int d) =>
      ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'][d - 1];

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  // complete task
  Future<void> markTaskCompleted(TimelineItem item) async {
    final dayKey =
    DateFormat('yyyy-MM-dd').format(selectedDate.value);

    final taskRes = await supabase
        .from('tasks')
        .select('repeat_type, completed_dates')
        .eq('id', item.id)
        .single();

    final repeatType = taskRes['repeat_type'];
    final dates =
    List<String>.from(taskRes['completed_dates'] ?? []);

    if (repeatType == 'none') {
      // one-time task → permanent completion
      await supabase
          .from('tasks')
          .update({'is_completed': true})
          .eq('id', item.id);
    } else {
      // repeating task → day-only completion
      if (!dates.contains(dayKey)) dates.add(dayKey);

      await supabase
          .from('tasks')
          .update({'completed_dates': dates})
          .eq('id', item.id);
    }

    final index = timeline.indexOf(item);
    timeline[index] =
        timeline[index].copyWith(isCompleted: true);
  }

  // delete task
  Future<void> deleteItem(TimelineItem item) async {
    final table =
    item.type == TimelineType.task ? 'tasks' : 'events';

    await supabase.from(table).delete().eq('id', item.id);
    timeline.remove(item);
  }

}
