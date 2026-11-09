import 'dart:async';

import 'package:battery_plus/battery_plus.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:health/health.dart';
import 'package:pedometer/pedometer.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/repositories/user_repository.dart';
import '../../../core/services/cache_service.dart';
import '../../../core/services/fcm_service.dart';
import '../../events/controllers/events_controller.dart';
import '../../events/widgets/healthconnect_dialog.dart';
import '../../tasks/controllers/task_controller.dart';
import 'activity_controller.dart';
import 'reciever_location_controller.dart';

class ReceiverDashboardController extends GetxController {
  final SupabaseClient supabase = Supabase.instance.client;
  TaskController get taskController => Get.find<TaskController>();

  // user info
  final userName = ''.obs;

  String get greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return "Good Morning";
    if (hour < 17) return "Good Afternoon";
    return "Good Evening";
  }

  // mood
  final selectedMood = ''.obs;
  final moodSubmittedToday = false.obs;
  
// MOOD CONFIG (ORDERED: HAPPY → SAD)

  final List<Map<String, String>> moodOptions = [
    {'key': 'very_happy', 'emoji': '😄'},
    {'key': 'happy', 'emoji': '😃'},
    {'key': 'neutral', 'emoji': '😐'},
    {'key': 'sad', 'emoji': '😔'},
    {'key': 'very_sad', 'emoji': '😣'},
  ];



  // DEVICE STATUS
  
  final Battery _battery = Battery();
  final batteryLevel = 0.obs;
  final isCharging = false.obs;
  final isDeviceConnected = false.obs;
  DateTime? lastDeviceSync;

  
  // LOCATION SHARING
  
  Timer? _locationTimer;
  bool _locationStarted = false;
  bool _hasExitedSafeZone = false;
  final isSharingLocation = false.obs;
  final locationStatusMessage = "Initializing...".obs;

  RealtimeChannel? _trackingChannel;
  static const Duration _dbLocationSyncInterval = Duration(minutes: 15);
  DateTime? _lastDbLocationSync;
  double? _lastLatitude;
  double? _lastLongitude;

  // GEOFENCE CACHE (30-min TTL)
  static const Duration _geofenceTtl = Duration(minutes: 30);
  Map<String, dynamic>? _cachedGeofence;
  DateTime? _geofenceCachedAt;

  bool get _isGeofenceMemoryValid {
    if (_cachedGeofence == null || _geofenceCachedAt == null) return false;
    return DateTime.now().difference(_geofenceCachedAt!) < _geofenceTtl;
  }

  
  // STEPS
  
  StreamSubscription<StepCount>? _stepSub;
  StreamSubscription<String>? _tokenRefreshSub;
  Timer? _stepsFlushTimer;
  bool _stepsStarted = false;
  bool _isSendingSOS = false;
  
  // UI STATE
  
  final isLoading = false.obs;

  
  // INIT
  
  @override
  void onInit() {
    super.onInit();
    debugPrint("🚀 ReceiverDashboardController initialized");
    loadDashboard();

    syncFcmToken();
    _notifyCaregiverAppOpened();
  }

  Future<void> _notifyCaregiverAppOpened() async {
    final caregiverId = await _getCaregiverId();
    if (caregiverId != null) {
      await FcmService.sendNotification(
        receiverId: caregiverId,
        title: "Receiver Online",
        body: "The care receiver has just opened the app.",
        type: "app_opened"
      );
    }
  }

  @override
  void onClose() {
    debugPrint("🧹 ReceiverDashboardController disposed");
    flushLocationToDatabase();
    _cleanupTrackingChannel();
    _stepSub?.cancel();
    _tokenRefreshSub?.cancel();
    _stepsFlushTimer?.cancel();
    _locationTimer?.cancel();
    super.onClose();
  }

  
  // DASHBOARD LOAD
  
  Future<void> loadDashboard() async {
    if (isLoading.value) return;

    try {
      isLoading.value = true;
      debugPrint("🔄 Loading receiver dashboard");

      final user = supabase.auth.currentUser;
      if (user == null) {
        debugPrint("❌ No authenticated user");
        return;
      }

      final userRepo = Get.isRegistered<UserRepository>()
          ? Get.find<UserRepository>()
          : UserRepository();

      final profile = await userRepo.getUser(user.id);
      userName.value = profile?.fullName ?? '';

      await Future.wait([
        checkTodayMood(),
        syncDeviceStatus(),
        refreshDeviceConnectionStatus(),
        Get.find<EventsController>().loadEventsForReceiver(user.id),
      ]);

      await startAutomaticLocationSharing();
      await startStepTracking();

      debugPrint("✅ Dashboard load complete");
    } catch (e) {
      debugPrint("❌ ReceiverDashboard load error: $e");
    } finally {
      isLoading.value = false;
    }
  }
  
  // DEVICE STATUS
  
  Future<void> syncDeviceStatus() async {
    if (lastDeviceSync != null &&
        DateTime.now().difference(lastDeviceSync!).inMinutes < 5) {
      return;
    }

    lastDeviceSync = DateTime.now();

    final user = supabase.auth.currentUser;
    if (user == null) return;

    final level = await _battery.batteryLevel;
    final chargingState = await _battery.batteryState;

    batteryLevel.value = level;
    isCharging.value = chargingState == BatteryState.charging;

    await supabase.from('device_status').upsert(
      {
        'user_id': user.id,
        'battery_level': level,
        'charging': isCharging.value,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      },
      onConflict: 'user_id',
    );

    if (Get.isRegistered<ActivityController>()) {
      Get.find<ActivityController>().markActive(syncToServer: false);
    }

    debugPrint("🔋 Battery: $level% | Charging: ${isCharging.value}");
  }

  Future<void> refreshDeviceConnectionStatus() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final res = await supabase
        .from('device_status')
        .select('updated_at')
        .eq('user_id', user.id)
        .maybeSingle();

    if (res == null) {
      isDeviceConnected.value = false;
      debugPrint("📡 Device offline");
      return;
    }

    final last = DateTime.parse(res['updated_at']).toLocal();
    isDeviceConnected.value =
        DateTime.now().difference(last).inMinutes <= 10;

    debugPrint("📡 Device connected: ${isDeviceConnected.value}");
  }

  
  // LOCATION SHARING (LOGGED)
  
  Future<void> startAutomaticLocationSharing() async {
    if (_locationStarted) return;
    _locationStarted = true;

    debugPrint("📍 Starting location sharing");

    final user = supabase.auth.currentUser;
    if (user == null) return;

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      locationStatusMessage.value = "Enable GPS";
      await Geolocator.openLocationSettings();

      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint("❌ Location still disabled");
        return;
      }
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      locationStatusMessage.value = "Permission denied";
      debugPrint("❌ Location permission denied");
      return;
    }

    debugPrint("✅ Location permission granted: $permission");
    isSharingLocation.value = true;
    locationStatusMessage.value = "Sharing location";

    _initTrackingChannel(user.id);

    if (Get.isRegistered<ReceiverLocationController>()) {
      Get.find<ReceiverLocationController>().cancelTrackingIfDashboardActive();
    }

    await _sendLocationOnce();

    _locationTimer = Timer.periodic(
      const Duration(minutes: 2),
          (_) => _sendLocationOnce(),
    );
  }

  void _initTrackingChannel(String userId) {
    if (_trackingChannel != null) return;
    try {
      _trackingChannel = supabase.channel('tracking:$userId');
      _trackingChannel!.subscribe();
      debugPrint("📡 Tracking broadcast channel subscribed: tracking:$userId");
    } catch (e) {
      debugPrint("⚠️ Failed to initialize tracking broadcast channel: $e");
    }
  }

  void _cleanupTrackingChannel() {
    if (_trackingChannel != null) {
      try {
        _trackingChannel!.unsubscribe();
        supabase.removeChannel(_trackingChannel!);
      } catch (_) {}
      _trackingChannel = null;
    }
  }

  Future<void> _syncLocationToPostgres(String userId, double lat, double lng) async {
    try {
      final nowIso = DateTime.now().toUtc().toIso8601String();
      _lastDbLocationSync = DateTime.now();

      await supabase.from('user_locations').upsert(
        {
          'user_id': userId,
          'latitude': lat,
          'longitude': lng,
          'last_activity_at': nowIso,
          'updated_at': nowIso,
        },
        onConflict: 'user_id',
      );

      if (Get.isRegistered<ActivityController>()) {
        final actCtrl = Get.find<ActivityController>();
        actCtrl.recordServerSync(DateTime.now());
        actCtrl.markActive(syncToServer: false);
      }
      debugPrint("💾 Historical backup location written to Postgres");
    } catch (e) {
      debugPrint("⚠️ Historical location backup failed: $e");
    }
  }

  Future<void> flushLocationToDatabase() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;
    if (_lastLatitude != null && _lastLongitude != null) {
      await _syncLocationToPostgres(user.id, _lastLatitude!, _lastLongitude!);
    }
  }

  Future<void> _sendLocationOnce() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.medium,
      ),
    );

    _lastLatitude = position.latitude;
    _lastLongitude = position.longitude;

    debugPrint(
        "📍 Broadcasting live location → lat: ${position.latitude}, lng: ${position.longitude}");

    final nowIso = DateTime.now().toUtc().toIso8601String();

    // 1. WebSocket Broadcast to Caregiver (0% DB CPU)
    try {
      _initTrackingChannel(user.id);
      await _trackingChannel?.sendBroadcastMessage(
        event: 'location_update',
        payload: {
          'latitude': position.latitude,
          'longitude': position.longitude,
          'updated_at': nowIso,
        },
      );
      debugPrint("📡 Broadcasted live location via WebSocket");
    } catch (e) {
      debugPrint("⚠️ Realtime broadcast error: $e");
    }

    // 2. Mark local activity without network write
    if (Get.isRegistered<ActivityController>()) {
      Get.find<ActivityController>().markActive(syncToServer: false);
    }

    // 3. Historical backup write to Postgres every 15-30 minutes
    if (_lastDbLocationSync == null ||
        DateTime.now().difference(_lastDbLocationSync!) >= _dbLocationSyncInterval) {
      await _syncLocationToPostgres(user.id, position.latitude, position.longitude);
    }

    // Check Geofence on each update
    _checkSafeZone(position.latitude, position.longitude);

    debugPrint("📍 Location tick completed");
  }

  Future<void> _checkSafeZone(double lat, double lng) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      final cacheKey = CacheService.userKey(user.id, 'geofence');

      // 1. Read from local in-memory cache first
      if (!_isGeofenceMemoryValid) {
        // 2. Read from CacheService disk cache
        try {
          final diskCached = CacheService.instance.get<Map<String, dynamic>>(
            cacheKey,
            maxAge: _geofenceTtl,
            fromJson: (json) => Map<String, dynamic>.from(json as Map),
          );
          if (diskCached != null && !diskCached.isStale) {
            _cachedGeofence = diskCached.data;
            _geofenceCachedAt = diskCached.timestamp;
          }
        } catch (_) {}
      }

      // 3. Only fetch from Supabase if cache is empty or expired
      if (!_isGeofenceMemoryValid) {
        final res = await supabase
            .from('geofences')
            .select()
            .eq('receiver_id', user.id)
            .maybeSingle();

        if (res == null) {
          // Cache negative result with TTL to avoid repeated queries when no geofence exists
          _cachedGeofence = {'empty': true};
          _geofenceCachedAt = DateTime.now();
          try {
            await CacheService.instance.set(cacheKey, {'empty': true});
          } catch (_) {}
          return;
        }

        _cachedGeofence = res;
        _geofenceCachedAt = DateTime.now();
        try {
          await CacheService.instance.set(cacheKey, res);
        } catch (_) {}
      }

      if (_cachedGeofence == null || _cachedGeofence!['empty'] == true) {
        return;
      }

      final double sLat = (_cachedGeofence!['latitude'] as num).toDouble();
      final double sLng = (_cachedGeofence!['longitude'] as num).toDouble();
      final int radius = (_cachedGeofence!['radius'] as num).toInt();

      final distance = Geolocator.distanceBetween(lat, lng, sLat, sLng);
      if (distance > radius) {
        if (!_hasExitedSafeZone) {
          _hasExitedSafeZone = true;
          final caregiverId = await _getCaregiverId();
          if (caregiverId != null) {
            await FcmService.sendNotification(
              receiverId: caregiverId,
              title: "Safe Zone Alert!",
              body: "The receiver has left the safe zone.",
              type: "location_alert"
            );
          }
        }
      } else {
        _hasExitedSafeZone = false;
      }
    } catch (e) {
      debugPrint("Geofence check error: $e");
    }
  }

  
  // STEPS

  final Health _health = Health();

  Future<void> startStepTracking() async {
    if (_stepsStarted) return;
    _stepsStarted = true;

    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      // Request permission for reading step data
      final types = [HealthDataType.STEPS];

      bool requested = await _health.requestAuthorization(types);

      if (!requested) {
        debugPrint("❌ Health permission denied");
        return;
      }

      debugPrint("✅ Health permission granted");

      // fetch steps immediately
      await _fetchTodaySteps();

      // refresh every 5 minutes
      _stepsFlushTimer = Timer.periodic(
        const Duration(minutes: 5),
            (_) => _fetchTodaySteps(),
      );

      debugPrint("🚶 Health step tracking started");
    } catch (e) {
      debugPrint("❌ Health step tracking error: $e");

      if (e.toString().contains("Health Connect is not available")) {
        showHealthConnectDialog();
      }
    }
  }

  Future<void> _fetchTodaySteps() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      final now = DateTime.now();
      final midnight = DateTime(now.year, now.month, now.day);

      int steps =
          await _health.getTotalStepsInInterval(midnight, now) ?? 0;

      debugPrint("🚶 Today's steps from Health API: $steps");

      final dateKey =
      midnight.toIso8601String().substring(0, 10);

      await supabase.from('steps_data').upsert(
        {
          'user_id': user.id,
          'date': dateKey,
          'steps': steps,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        },
        onConflict: 'user_id,date',
      );

      Get.find<ActivityController>().markActive(syncToServer: false);

      debugPrint("🚶 Steps synced: $steps");
    } catch (e) {
      debugPrint("❌ Health step fetch error: $e");
    }
  }

  
  // SOS
  
  Future<void> sendSOS() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;
    if (_isSendingSOS) {
      debugPrint("🚨 SOS already in progress, ignoring duplicate tap");
      return;
    }
    _isSendingSOS = true;

    debugPrint("🚨 SEND SOS tapped by ${user.id}");

    try {
      Position? position;
      try {
        position = await Geolocator.getLastKnownPosition();
        position ??= await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 8),
          ),
        );
      } catch (locErr) {
        debugPrint("⚠️ Could not acquire current location for SOS: $locErr");
      }

      final double lat = position?.latitude ?? 0.0;
      final double lng = position?.longitude ?? 0.0;
      final String msg = position != null
          ? 'Emergency SOS triggered'
          : 'Emergency SOS triggered (Location unavailable)';

      debugPrint("📍 SOS location: $lat, $lng");

      await supabase.from('sos_alerts').insert({
        'user_id': user.id,
        'lat': lat,
        'lng': lng,
        'message': msg,
        'handled': false,
      });

      // 🔥 Send Remote SOS Alarm to Caregiver
      final caregiverId = await _getCaregiverId();
      if (caregiverId != null) {
        await FcmService.sendNotification(
          receiverId: caregiverId,
          title: "EMERGENCY SOS",
          body: "Receiver has triggered an SOS alert!",
          type: "sos",
        );
      }

      if (Get.isRegistered<ActivityController>()) {
        Get.find<ActivityController>().markActive(syncToServer: false);
      }

      Get.snackbar(
        "SOS Sent",
        "Caregiver has been notified",
        backgroundColor: Colors.red.shade600,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
    } catch (e) {
      debugPrint("❌ SOS INSERT FAILED: $e");
      Get.snackbar(
        "Error",
        "Failed to send SOS. Please call emergency services directly.",
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      _isSendingSOS = false;
    }
  }

// MOOD DIALOG CONTROL (2-HOUR LOGIC)

  final shouldShowMoodDialog = false.obs;
  DateTime? _lastMoodSubmissionTime;
  Future<void> checkTodayMood() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final today = DateTime.now().toIso8601String().substring(0, 10);

    final res = await supabase
        .from('mood_tracking')
        .select('mood, updated_at')
        .eq('user_id', user.id)
        .eq('mood_date', today)
        .maybeSingle();

    if (res != null) {
      selectedMood.value = res['mood'];
      moodSubmittedToday.value = true;

      _lastMoodSubmissionTime =
          DateTime.parse(res['updated_at']).toLocal();

      final diff =
      DateTime.now().difference(_lastMoodSubmissionTime!);

      //  Only show dialog if 2+ hours passed
      shouldShowMoodDialog.value = diff.inHours >= 2;

      debugPrint(
          "🙂 Mood exists | Last updated ${diff.inMinutes} mins ago");
    } else {
      moodSubmittedToday.value = false;
      shouldShowMoodDialog.value = true; // First time today
      debugPrint("🙂 No mood yet today → dialog allowed");
    }
  }


  Future<void> submitMood(String mood) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final today = DateTime.now().toIso8601String().substring(0, 10);

    selectedMood.value = mood;
    moodSubmittedToday.value = true;
    shouldShowMoodDialog.value = false;
    _lastMoodSubmissionTime = DateTime.now();

    await supabase.from('mood_tracking').upsert(
      {
        'user_id': user.id,
        'mood': mood,
        'mood_date': today,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      },
      onConflict: 'user_id,mood_date',
    );

    // Notify Caregiver
    final caregiverId = await _getCaregiverId();
    if (caregiverId != null) {
      await FcmService.sendNotification(
        receiverId: caregiverId,
        title: "Mood Update",
        body: "Receiver is feeling $mood",
        type: "mood_update"
      );
    }

    Get.back();
    debugPrint("🙂 Mood updated → $mood");
  }

  Future<void> refreshDashboard() async {
    if (isLoading.value) return;

    try {
      isLoading.value = true;
      _cachedGeofence = null;
      _geofenceCachedAt = null;

      final user = supabase.auth.currentUser;
      if (user == null) return;

      await syncDeviceStatus();
      await refreshDeviceConnectionStatus();
      await checkTodayMood();

      await Get.find<TaskController>()
          .loadTasksForReceiver(user.id);

      await Get.find<EventsController>()
          .loadEventsForReceiver(user.id);

    } finally {
      isLoading.value = false;
    }
  }

  Future<void> syncFcmToken() async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      debugPrint("❌ Cannot sync FCM token: user not logged in");
      return;
    }

    final userId = user.id;
    debugPrint("👤 Syncing FCM for user: $userId");

    final fcm = FirebaseMessaging.instance;
    final token = await fcm.getToken();

    debugPrint("🔥 FCM TOKEN: $token");

    final cacheKey = CacheService.userKey(userId, 'fcm_token');
    String? cachedToken;
    try {
      cachedToken = CacheService.instance.get<String>(cacheKey)?.data;
    } catch (_) {}

    if (token != null && token.isNotEmpty && token != cachedToken) {
      await supabase
          .from('users')
          .update({'fcm_token': token})
          .eq('id', userId);

      try {
        await CacheService.instance.set(cacheKey, token);
      } catch (_) {}

      debugPrint("✅ FCM token saved to Supabase and cache updated");
    } else {
      debugPrint("ℹ️ FCM token unchanged or empty; skipping update");
    }

    _tokenRefreshSub?.cancel();
    _tokenRefreshSub = FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      debugPrint("🔄 FCM token refreshed: $newToken");

      String? currentCached;
      try {
        currentCached = CacheService.instance.get<String>(cacheKey)?.data;
      } catch (_) {}

      if (newToken.isNotEmpty && newToken != currentCached) {
        await supabase
            .from('users')
            .update({'fcm_token': newToken})
            .eq('id', userId);

        try {
          await CacheService.instance.set(cacheKey, newToken);
        } catch (_) {}

        debugPrint("✅ Updated refreshed token in Supabase and cache");
      }
    });
  }

  Future<String?> _getCaregiverId() async {
    final uid = supabase.auth.currentUser?.id;
    if (uid == null) return null;
    final res = await supabase.from('care_links').select('caregiver_id').eq('receiver_id', uid).maybeSingle();
    return res?['caregiver_id'];
  }

  Future<void> refreshQuickData() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      debugPrint("🔄 Receiver quick refresh");

      await Future.wait([
        syncDeviceStatus(),
        refreshDeviceConnectionStatus(),
        checkTodayMood(),
        Get.find<TaskController>().loadTasksForReceiver(user.id),
        Get.find<EventsController>().loadEventsForReceiver(user.id),
      ]);

    } catch (e) {
      debugPrint("❌ Receiver refresh error: $e");
    }
  }

}
