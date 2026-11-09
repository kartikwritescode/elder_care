import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:get/get.dart';
import '../../modules/chat/controllers/chat_controller.dart';

/// Top-level background message handler for FCM.
/// Must be outside any class.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint("📩 Background message received: ${message.messageId}");
  // Note: Native side (MyFirebaseMessagingService.kt) also handles this.
}

class NotificationService {
  static final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  static final _supabase = Supabase.instance.client;

  static Future<void> init() async {
    // 1. Request Permission
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint("🔔 Notification permission granted");
    } else {
      debugPrint("❌ Notification permission denied");
    }

    // 2. Initialize Local Notifications for Foreground display
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: DarwinInitializationSettings(),
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // 3. Register Background Handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 4. Handle Foreground Messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint("📩 Foreground message received: ${message.notification?.title}");
      _showLocalNotification(message);
    });

    // 5. Handle notification clicks when app is in background/terminated
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint("🖱️ Notification tapped (Background): ${message.data}");
      _handleNotificationClick(message.data);
    });

    // Check if app was opened from a terminated state via notification
    RemoteMessage? initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      debugPrint("🖱️ Notification tapped (Terminated): ${initialMessage.data}");
      _handleNotificationClick(initialMessage.data);
    }

    // 6. Sync Token
    await syncFcmToken();
    _fcm.onTokenRefresh.listen(_saveTokenToDatabase);
  }

  static Future<void> _showLocalNotification(RemoteMessage message) async {
    if (kIsWeb) return;

    final String? type = message.data['type'];

    // Don't show in-app banner for chat if user is already actively looking at that chat
    if (type == 'chat') {
      final String? chatId = message.data['chat_id'];
      if (chatId != null && Get.isRegistered<ChatController>()) {
        final chatCtl = Get.find<ChatController>();
        if (chatCtl.activeChatId == chatId && Get.currentRoute == '/chat') {
          debugPrint("🔇 Chat screen is currently open for $chatId. Skipping banner.");
          return;
        }
      }
    }

    // Resolve title and body from notification payload OR data payload
    String? title = message.notification?.title;
    if (title == null || title.trim().isEmpty) {
      title = message.data['title'] ?? message.data['sender_name'];
    }

    String? body = message.notification?.body;
    if (body == null || body.trim().isEmpty) {
      body = message.data['body'] ?? message.data['message'];
    }

    title = title?.trim();
    body = body?.trim();

    // NEVER show blank notifications
    final bool isTitleEmpty = title == null || title.isEmpty;
    final bool isBodyEmpty = body == null || body.isEmpty;

    if (isTitleEmpty && isBodyEmpty) {
      debugPrint("⚠️ Skipping blank notification (both title and body are empty)");
      return;
    }

    final String safeTitle = isTitleEmpty ? (type == 'chat' ? 'New Message' : 'ElderCare') : title;
    final String safeBody = isBodyEmpty ? 'You have a new notification' : body;

    // Pick channel matching native side
    String channelId = 'default_channel';
    String channelName = 'General Notifications';

    if (type == 'chat') {
      channelId = 'chat_channel';
      channelName = 'Chat Messages';
    } else if (type == 'mood_update' || type == 'location_alert' || type == 'event_update') {
      channelId = 'update_channel';
      channelName = 'Receiver Updates';
    }

    // Deterministic notification ID based on messageId or content to prevent duplicates
    final int notificationId = message.messageId != null
        ? message.messageId.hashCode
        : (safeTitle + safeBody).hashCode;

    await _localNotifications.show(
      notificationId,
      safeTitle,
      safeBody,
      NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelName,
          importance: Importance.max,
          priority: Priority.high,
          showWhen: true,
        ),
      ),
      payload: message.data.toString(),
    );
  }

  static void _onNotificationTapped(NotificationResponse response) {
    debugPrint("🖱️ Local notification tapped: ${response.payload}");
    // Parse payload if needed and navigate
  }

  static void _handleNotificationClick(Map<String, dynamic> data) {
    // Implementation for deep linking or navigation based on data
    final String? type = data['type'];
    if (type == 'chat') {
      // Get.toNamed('/chat', arguments: data['chat_id']);
    }
  }

  static Future<void> syncFcmToken() async {
    try {
      final token = await _fcm.getToken();
      if (token != null) {
        debugPrint("📱 FCM TOKEN: $token");
        await _saveTokenToDatabase(token);
      }
    } catch (e) {
      debugPrint("❌ Error syncing FCM token: $e");
    }
  }

  static Future<void> _saveTokenToDatabase(String token) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      await _supabase.from('users').update({
        'fcm_token': token,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', userId);
      debugPrint("✅ FCM token synced for user: $userId");
    } catch (e) {
      debugPrint("❌ Failed to save FCM token to DB: $e");
    }
  }
}
