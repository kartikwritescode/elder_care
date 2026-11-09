import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/models/task_model.dart';
import '../../../core/repositories/task_repository.dart';
import '../../../core/services/native_alarm_service.dart';
import '../../../core/services/fcm_service.dart';
import '../../../core/services/reciever_service.dart';

class TaskController extends GetxController {
  final supabase = Supabase.instance.client;
  TaskRepository get taskRepo => Get.isRegistered<TaskRepository>()
      ? Get.find<TaskRepository>()
      : TaskRepository();

  RxList<TaskModel> tasks = <TaskModel>[].obs;

  final titleController = TextEditingController();
  final dateController = TextEditingController();
  
  DateTime? pickedDate;
  TimeOfDay? pickedTime;
  RxString repeatType = 'none'.obs;
  RxList<String> repeatDays = <String>[].obs;
  RxBool reminderEnabled = false.obs;
  RxBool isMedicine = false.obs;

  TaskModel? _lastDeletedTask;
  int? _lastDeletedIndex;

  int? editingId;
  String? currentReceiverId;

  @override
  void onClose() {
    titleController.dispose();
    dateController.dispose();
    super.onClose();
  }

  void clearForm() {
    titleController.clear();
    dateController.clear();
    pickedDate = null;
    pickedTime = null;
    editingId = null;
    repeatType.value = 'none';
    repeatDays.clear();
    reminderEnabled.value = false;
    isMedicine.value = false;
  }

  DateTime? _combinedDateTime() {
    if (pickedDate == null && pickedTime == null) return null;
    final d = pickedDate ?? DateTime.now();
    final t = pickedTime ?? const TimeOfDay(hour: 9, minute: 0);
    return DateTime(d.year, d.month, d.day, t.hour, t.minute);
  }

  bool showAlarmCheckbox() {
    return pickedDate != null && pickedTime != null;
  }

  void setPickedDate(DateTime d) {
    pickedDate = d;
    update();
  }

  void setPickedTime(TimeOfDay t) {
    pickedTime = t;
    pickedDate ??= DateTime.now();
    if (!isMedicine.value && !reminderEnabled.value) {
      reminderEnabled.value = true;
    }
    update();
  }

  Future<void> loadTasksForReceiver(String receiverId) async {
    currentReceiverId = receiverId;
    try {
      final list = await taskRepo.getTasks(
        receiverId,
        onCacheLoaded: (cachedList) {
          tasks.assignAll(cachedList);
        },
      );
      tasks.assignAll(list);
    } catch (e) {
      debugPrint('loadTasks error: $e');
    }
  }

  Future<void> addTask() async {
    if (titleController.text.trim().isEmpty) {
      Get.snackbar('Validation', 'Enter medicine/task name');
      return;
    }
    if (currentReceiverId == null) return;

    final dt = _combinedDateTime();
    final model = TaskModel(
      receiverId: currentReceiverId!,
      title: titleController.text.trim(),
      datetime: dt?.toUtc().toIso8601String(),
      alarmEnabled: reminderEnabled.value,
      vibrate: reminderEnabled.value,
      taskType: isMedicine.value ? 'medicine' : 'normal',
      repeatType: repeatType.value,
      repeatDays: repeatDays,
    );

    try {
      final created = await taskRepo.createTask(model);

      if (created != null) {
        tasks.insert(0, created);

        final myUid = supabase.auth.currentUser?.id;
        final isReceiver = myUid == currentReceiverId;

        if (reminderEnabled.value && dt != null) {
          if (isReceiver) {
            await NativeAlarmService.schedule(
              alarmId: created.id.toString(),
              dateTime: dt,
              title: created.title,
              repeatType: created.repeatType,
              repeatDays: created.repeatDays,
            );
          } else {
            await FcmService.sendRemoteAlarm(
              receiverId: currentReceiverId!,
              alarmId: created.id.toString(),
              time: dt,
              title: created.title,
              repeatType: created.repeatType,
              repeatDays: created.repeatDays,
            );
          }
        }

        // Notify other party
        if (isReceiver) {
          final caregiverId = await ReceiverService.getLinkedCaregiverId();
          if (caregiverId != null) {
            await FcmService.sendNotification(
              receiverId: caregiverId,
              title: "Task Added",
              body: "Receiver added: ${created.title}",
              type: "task_added"
            );
          }
        } else {
          await FcmService.sendNotification(
            receiverId: currentReceiverId!,
            title: "New Task",
            body: "Caregiver added: ${created.title}",
            type: "task_added"
          );
        }

        clearForm();
        if (Get.isDialogOpen ?? false) Get.back();
      }
    } catch (e) {
      debugPrint('addTask error: $e');
    }
  }

  Future<void> confirmEdit() async {
    if (editingId == null || currentReceiverId == null) return;

    final dt = _combinedDateTime();
    final model = TaskModel(
      id: editingId,
      receiverId: currentReceiverId!,
      title: titleController.text.trim(),
      datetime: dt?.toUtc().toIso8601String(),
      alarmEnabled: reminderEnabled.value,
      vibrate: reminderEnabled.value,
      taskType: isMedicine.value ? 'medicine' : 'normal',
      repeatType: repeatType.value,
      repeatDays: repeatDays,
    );

    try {
      final updated = await taskRepo.updateTask(editingId!, model);

      if (updated != null) {
        
        final myUid = supabase.auth.currentUser?.id;
        final isReceiver = myUid == currentReceiverId;

        // Cancel old alarm
        if (isReceiver) {
          await NativeAlarmService.cancel(updated.id.toString());
        } else {
          await FcmService.sendRemoteAlarm(
            receiverId: currentReceiverId!,
            alarmId: updated.id.toString(),
            time: DateTime.now(),
            title: "",
            isCancel: true,
          );
        }

        // Schedule new alarm
        if (reminderEnabled.value && dt != null) {
          if (isReceiver) {
            await NativeAlarmService.schedule(
              alarmId: updated.id.toString(),
              dateTime: dt,
              title: updated.title,
              repeatType: updated.repeatType,
              repeatDays: updated.repeatDays,
            );
          } else {
            await FcmService.sendRemoteAlarm(
              receiverId: currentReceiverId!,
              alarmId: updated.id.toString(),
              time: dt,
              title: updated.title,
              repeatType: updated.repeatType,
              repeatDays: updated.repeatDays,
            );
          }
        }
        clearForm();
        if (Get.isDialogOpen ?? false) Get.back();
      }
    } catch (e) {
      debugPrint('confirmEdit error: $e');
    }
  }

  Future<void> deleteTaskConfirmed(TaskModel task) async {
    if (task.id == null || currentReceiverId == null) return;
    try {
      await taskRepo.deleteTask(task.id!, currentReceiverId!);
      tasks.removeWhere((t) => t.id == task.id);

      final myUid = supabase.auth.currentUser?.id;
      final isReceiver = myUid == currentReceiverId;

      if (isReceiver) {
        await NativeAlarmService.cancel(task.id!.toString());
        final caregiverId = await ReceiverService.getLinkedCaregiverId();
        if (caregiverId != null) {
          await FcmService.sendNotification(
            receiverId: caregiverId,
            title: "Task Deleted",
            body: "Receiver deleted: ${task.title}",
            type: "task_deleted"
          );
        }
      } else if (currentReceiverId != null) {
         await FcmService.sendRemoteAlarm(
          receiverId: currentReceiverId!,
          alarmId: task.id.toString(),
          time: DateTime.now(),
          title: "",
          isCancel: true,
        );
         
        await FcmService.sendNotification(
            receiverId: currentReceiverId!,
            title: "Task Removed",
            body: "Caregiver removed: ${task.title}",
            type: "task_deleted"
          );
      }
      Get.snackbar('Deleted', 'Task removed');
    } catch (e) {
      debugPrint('deleteTask error: $e');
    }
  }

  Future<void> deleteTaskWithUndo(TaskModel task, int index) async {
    _lastDeletedTask = task;
    _lastDeletedIndex = index;
    tasks.removeAt(index);

    final myUid = supabase.auth.currentUser?.id;
    final isReceiver = myUid == currentReceiverId;

    if (isReceiver) {
      await NativeAlarmService.cancel(task.id!.toString());
    } else if (currentReceiverId != null) {
      await FcmService.sendRemoteAlarm(
        receiverId: currentReceiverId!,
        alarmId: task.id.toString(),
        time: DateTime.now(),
        title: "",
        isCancel: true,
      );
    }

    try {
      await supabase.from('tasks').delete().eq('id', task.id!);

      Get.snackbar(
        'Task deleted',
        task.title,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 4),
        mainButton: TextButton(
          onPressed: undoDelete,
          child: const Text('UNDO', style: TextStyle(color: Colors.white)),
        ),
        backgroundColor: Colors.black87,
        colorText: Colors.white,
      );
    } catch (e) {
      debugPrint('deleteTaskWithUndo error: $e');
      if (!tasks.contains(task)) {
        tasks.insert(index.clamp(0, tasks.length), task);
      }
      Get.snackbar('Error', 'Could not delete task', snackPosition: SnackPosition.BOTTOM);
    }
  }

  Future<void> undoDelete() async {
    if (_lastDeletedTask == null || _lastDeletedIndex == null) return;
    if (Get.isSnackbarOpen) {
      Get.closeCurrentSnackbar();
    }

    final restored = _lastDeletedTask!;
    final map = restored.toMap()..remove('id');

    try {
      final res = await supabase.from('tasks').insert(map).select().limit(1);
      if (res.isNotEmpty) {
        final recreated = TaskModel.fromMap(res.first);
        tasks.insert(_lastDeletedIndex!, recreated);

        if (recreated.alarmEnabled && recreated.datetime != null) {
          final dt = DateTime.parse(recreated.datetime!).toLocal();
          final isReceiver = supabase.auth.currentUser?.id == currentReceiverId;
          
          if (isReceiver) {
            await NativeAlarmService.schedule(
              alarmId: recreated.id.toString(),
              dateTime: dt,
              title: recreated.title,
              repeatType: recreated.repeatType,
              repeatDays: recreated.repeatDays,
            );
          } else {
            await FcmService.sendRemoteAlarm(
              receiverId: currentReceiverId!,
              alarmId: recreated.id.toString(),
              time: dt,
              title: recreated.title,
              repeatType: recreated.repeatType,
              repeatDays: recreated.repeatDays,
            );
          }
        }
      }
    } catch (e) {
      debugPrint('undoDelete error: $e');
    }
    _lastDeletedTask = null;
    _lastDeletedIndex = null;
  }

  Future<void> markTaskCompleted(TaskModel task, int index) async {
    if (index >= 0 && index < tasks.length) {
      tasks.removeAt(index);
    }

    try {
      final myUid = supabase.auth.currentUser?.id;
      final isReceiver = myUid == currentReceiverId;

      if (isReceiver && task.id != null) {
        await NativeAlarmService.cancel(task.id!.toString());
        final caregiverId = await ReceiverService.getLinkedCaregiverId();
        if (caregiverId != null) {
          await FcmService.sendNotification(
            receiverId: caregiverId,
            title: "Task Completed",
            body: "Receiver completed: ${task.title}",
            type: "task_completed"
          );
        }
      } else if (currentReceiverId != null && task.id != null) {
         await FcmService.sendRemoteAlarm(
           receiverId: currentReceiverId!,
           alarmId: task.id.toString(),
           time: DateTime.now(),
           title: "",
           isCancel: true,
         );
      }

      if (task.id != null) {
        await supabase.from('tasks').update({'is_completed': true}).eq('id', task.id!);
      }
      Get.snackbar('Task completed', task.title, snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      debugPrint('markTaskCompleted error: $e');
      if (!tasks.contains(task)) {
        tasks.insert(index.clamp(0, tasks.length), task);
      }
      Get.snackbar('Error', 'Failed to complete task', snackPosition: SnackPosition.BOTTOM);
    }
  }

  void startEdit(TaskModel t) {
    editingId = t.id;
    titleController.text = t.title;
    repeatType.value = t.repeatType;
    repeatDays.assignAll(t.repeatDays);
    reminderEnabled.value = t.alarmEnabled;
    isMedicine.value = t.taskType == 'medicine';

    if (t.datetime != null) {
      try {
        final dt = DateTime.parse(t.datetime!).toLocal();
        pickedDate = DateTime(dt.year, dt.month, dt.day);
        pickedTime = TimeOfDay(hour: dt.hour, minute: dt.minute);
        dateController.text = dt.toIso8601String();
      } catch (_) {
        pickedDate = null;
        pickedTime = null;
        dateController.clear();
      }
    }
  }
}
