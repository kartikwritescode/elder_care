import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:elder_care/core/models/task_model.dart';
import 'package:elder_care/core/models/event_model.dart';
import 'package:elder_care/core/models/user_model.dart';
import 'package:elder_care/core/models/message_model.dart';
import 'package:elder_care/modules/profile/widgets/profile_tile.dart';

void main() {
  group('TaskModel Unit Tests', () {
    test('TaskModel serializes toMap and copies correctly', () {
      final task = TaskModel(
        id: 42,
        receiverId: 'receiver_123',
        title: 'Take Blood Pressure Medication',
        datetime: '2026-10-10T09:00:00Z',
        alarmEnabled: true,
        vibrate: true,
        repeatType: 'daily',
        repeatDays: const ['Mon', 'Tue'],
        isCompleted: false,
        taskType: 'medicine',
      );

      final map = task.toMap();
      expect(map['id'], 42);
      expect(map['receiver_id'], 'receiver_123');
      expect(map['title'], 'Take Blood Pressure Medication');
      expect(map['alarm_enabled'], true);
      expect(map['repeat_type'], 'daily');
      expect(map['task_type'], 'medicine');

      final updated = task.copyWith(isCompleted: true);
      expect(updated.isCompleted, true);
      expect(updated.title, 'Take Blood Pressure Medication');
      expect(updated.id, 42);
    });

    test('TaskModel uses proper default values', () {
      const defaultTask = TaskModel(receiverId: 'rec_1', title: 'Hydrate');
      expect(defaultTask.alarmEnabled, false);
      expect(defaultTask.vibrate, false);
      expect(defaultTask.repeatType, 'none');
      expect(defaultTask.isCompleted, false);
      expect(defaultTask.taskType, 'normal');
    });
  });

  group('EventModel Unit Tests', () {
    test('EventModel serializes and deserializes correctly', () {
      final now = DateTime.utc(2026, 10, 10, 14, 30);
      final event = EventModel(
        id: 101,
        title: 'Doctor Appointment',
        eventTime: now,
        category: 'Medical',
        notes: 'Bring previous lab results',
        receiverId: 'receiver_456',
      );

      final map = event.toMap();
      expect(map['id'], 101);
      expect(map['title'], 'Doctor Appointment');
      expect(map['category'], 'Medical');
      expect(map['receiver_id'], 'receiver_456');

      final deserialized = EventModel.fromMap(map);
      expect(deserialized.id, 101);
      expect(deserialized.title, 'Doctor Appointment');
      expect(deserialized.category, 'Medical');
      expect(deserialized.eventTime, now);
      expect(deserialized.notes, 'Bring previous lab results');
    });
  });

  group('UserModel Unit Tests', () {
    test('UserModel serializes and deserializes from JSON', () {
      final user = UserModel(
        id: 'usr_789',
        fullName: 'Jane Doe',
        email: 'jane@example.com',
        role: 'care_receiver',
        phone: '+1234567890',
        careId: 'CARE-1234',
      );

      final json = user.toJson();
      expect(json['id'], 'usr_789');
      expect(json['full_name'], 'Jane Doe');
      expect(json['role'], 'care_receiver');

      final deserialized = UserModel.fromJson(json);
      expect(deserialized.id, 'usr_789');
      expect(deserialized.fullName, 'Jane Doe');
      expect(deserialized.role, 'care_receiver');
    });
  });

  group('MessageModel Unit Tests', () {
    test('MessageModel serializes and deserializes correctly', () {
      final now = DateTime.utc(2026, 10, 10, 12, 0);
      final json = {
        'id': 1,
        'chat_id': 'chat_abc',
        'sender_id': 'usr_1',
        'content': 'Good morning! Did you take your medicine?',
        'created_at': now.toIso8601String(),
        'is_seen': true,
      };

      final deserialized = MessageModel.fromJson(json);
      expect(deserialized.id, 1);
      expect(deserialized.chatId, 'chat_abc');
      expect(deserialized.senderId, 'usr_1');
      expect(deserialized.content, 'Good morning! Did you take your medicine?');
      expect(deserialized.isSeen, true);
    });
  });

  group('Widget Tests', () {
    testWidgets('ProfileTile renders label, icon, and handles tap', (
      tester,
    ) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProfileTile(
              icon: Icons.settings,
              label: 'Account Settings',
              onTap: () {
                tapped = true;
              },
            ),
          ),
        ),
      );

      expect(find.text('Account Settings'), findsOneWidget);
      expect(find.byIcon(Icons.settings), findsOneWidget);
      expect(find.byIcon(Icons.arrow_forward_ios), findsOneWidget);

      await tester.tap(find.text('Account Settings'));
      await tester.pump();

      expect(tapped, isTrue);
    });
  });
}
