import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/models/event_model.dart';
import '../../../core/repositories/event_repository.dart';
import '../../../core/services/native_alarm_service.dart';
import '../../../core/services/fcm_service.dart';

class SupabaseEventService {
  static EventRepository get _repo => Get.isRegistered<EventRepository>()
      ? Get.find<EventRepository>()
      : EventRepository();

  static Future<List<EventModel>> fetchEvents(
    String receiverId, {
    void Function(List<EventModel>)? onCacheLoaded,
  }) async {
    return await _repo.getEvents(receiverId, onCacheLoaded: onCacheLoaded);
  }

  static Future<EventModel?> createEvent(EventModel event) async {
    return await _repo.createEvent(event);
  }

  static Future<EventModel?> updateEvent(EventModel event) async {
    return await _repo.updateEvent(event);
  }

  static Future<void> deleteEvent(int id, {String? receiverId}) async {
    if (receiverId != null) {
      await _repo.deleteEvent(id, receiverId);
    } else {
      await Supabase.instance.client.from('events').delete().eq('id', id);
    }
  }
}

class EventsController extends GetxController {
  final supabase = Supabase.instance.client;
  final RxList<EventModel> events = <EventModel>[].obs;
  String? currentReceiverId;

  final isLoading = false.obs;
  final titleController = TextEditingController();
  final dateController = TextEditingController();
  final notesController = TextEditingController();
  final category = 'Medication'.obs;

  final List<String> categories = [
    'Medication',
    'Appointment',
    'Vitals',
    'Activity',
    'Reminder',
    'Other',
    'General',
  ];

  int? editingId;
  DateTime? pickedDate;
  TimeOfDay? pickedTime;

  @override
  void onClose() {
    titleController.dispose();
    dateController.dispose();
    notesController.dispose();
    super.onClose();
  }

  void clearForm() {
    titleController.clear();
    dateController.clear();
    notesController.clear();
    category.value = 'Medication';
    editingId = null;
    pickedDate = null;
    pickedTime = null;
  }

  Future<void> loadEventsForReceiver(String receiverId) async {
    currentReceiverId = receiverId;
    try {
      final list = await SupabaseEventService.fetchEvents(
        receiverId,
        onCacheLoaded: (cachedList) {
          events.assignAll(cachedList);
        },
      );
      events.assignAll(list);
    } catch (e) {
      debugPrint('fetchEvents error: $e');
    }
  }

  DateTime? _combinedDateTime() {
    if (pickedDate == null && pickedTime == null) return null;
    final d = pickedDate ?? DateTime.now();
    final t = pickedTime ?? const TimeOfDay(hour: 9, minute: 0);
    return DateTime(d.year, d.month, d.day, t.hour, t.minute);
  }

  Future<bool> addEvent() async {
    if (titleController.text.trim().isEmpty) {
      Get.snackbar('Validation', 'Enter event title');
      return false;
    }
    final dt = _combinedDateTime();
    if (dt == null || dt.isBefore(DateTime.now())) {
      Get.snackbar('Validation', 'Select future date & time');
      return false;
    }
    if (currentReceiverId == null) return false;

    final model = EventModel(
      receiverId: currentReceiverId!,
      title: titleController.text.trim(),
      eventTime: dt,
      category: category.value,
      notes: notesController.text.trim(),
    );

    final created = await SupabaseEventService.createEvent(model);
    if (created != null) {
      events.add(created);
      events.sort((a, b) => a.eventTime.compareTo(b.eventTime));

      // Native Alarm Scheduling
      final isReceiver = supabase.auth.currentUser?.id == currentReceiverId;
      if (isReceiver) {
        await NativeAlarmService.schedule(
          alarmId: "event_${created.id}",
          dateTime: created.eventTime,
          title: created.title,
        );
      } else {
        await FcmService.sendRemoteAlarm(
          receiverId: currentReceiverId!,
          alarmId: "event_${created.id}",
          time: created.eventTime,
          title: created.title,
        );
      }

      // Notify caregiver if receiver added an event
      if (isReceiver) {
        final caregiver = await _getCaregiverId();
        if (caregiver != null) {
          await FcmService.sendNotification(
            receiverId: caregiver,
            title: "New Event Added",
            body: "Receiver added: ${created.title}",
            type: "event_added"
          );
        }
      }

      Get.snackbar('Success', 'Event added');
      return true;
    }
    return false;
  }

  Future<bool> confirmEdit() async {
    if (editingId == null) return false;
    final dt = _combinedDateTime();
    if (dt == null) return false;

    final model = EventModel(
      id: editingId,
      receiverId: currentReceiverId!,
      title: titleController.text.trim(),
      eventTime: dt,
      category: category.value,
      notes: notesController.text.trim(),
    );

    final updated = await SupabaseEventService.updateEvent(model);
    if (updated != null) {
      final idx = events.indexWhere((e) => e.id == updated.id);
      if (idx != -1) events[idx] = updated;
      events.sort((a, b) => a.eventTime.compareTo(b.eventTime));

      // Reschedule Native Alarm
      final isReceiver = supabase.auth.currentUser?.id == currentReceiverId;
      if (isReceiver) {
        await NativeAlarmService.cancel("event_${updated.id}");
        await NativeAlarmService.schedule(
          alarmId: "event_${updated.id}",
          dateTime: updated.eventTime,
          title: updated.title,
        );
      } else {
        await FcmService.sendRemoteAlarm(
          receiverId: currentReceiverId!,
          alarmId: "event_${updated.id}",
          time: updated.eventTime,
          title: updated.title,
        );
      }

      return true;
    }
    return false;
  }

  Future<void> deleteEventConfirmed(int id) async {
    await SupabaseEventService.deleteEvent(id, receiverId: currentReceiverId);
    events.removeWhere((e) => e.id == id);
    await NativeAlarmService.cancel("event_$id");
    if (currentReceiverId != null) {
       await FcmService.sendRemoteAlarm(
        receiverId: currentReceiverId!,
        alarmId: "event_$id",
        time: DateTime.now(),
        title: "",
        isCancel: true,
      );

       // Notify caregiver
       if (supabase.auth.currentUser?.id == currentReceiverId) {
          final caregiver = await _getCaregiverId();
          if (caregiver != null) {
            await FcmService.sendNotification(
              receiverId: caregiver,
              title: "Event Deleted",
              body: "Receiver deleted an event",
              type: "event_deleted"
            );
          }
       }
    }
    Get.snackbar('Deleted', 'Event removed');
  }

  Future<String?> _getCaregiverId() async {
    final uid = supabase.auth.currentUser?.id;
    if (uid == null) return null;
    final res = await supabase.from('care_links').select('caregiver_id').eq('receiver_id', uid).maybeSingle();
    return res?['caregiver_id'];
  }

  void startEdit(EventModel event) {
    editingId = event.id;
    titleController.text = event.title;
    notesController.text = event.notes;
    category.value = categories.contains(event.category.trim()) ? event.category.trim() : categories.first;
    final dt = event.eventTime.toLocal();
    pickedDate = DateTime(dt.year, dt.month, dt.day);
    pickedTime = TimeOfDay(hour: dt.hour, minute: dt.minute);
  }
}
