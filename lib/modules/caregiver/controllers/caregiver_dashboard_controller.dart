import 'dart:async';
import 'package:battery_plus/battery_plus.dart';
import 'package:elder_care/modules/events/controllers/events_controller.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/repositories/user_repository.dart';
import '../../../core/services/cache_service.dart';
import '../../../core/services/emergency_alert_service.dart';
import '../../dashboard/controllers/nav_controller.dart';
import '../../tasks/controllers/task_controller.dart';

class CaregiverDashboardController extends GetxController {

  TaskController get taskController => Get.find<TaskController>();
  final supabase = Supabase.instance.client;
  // ----------------------------- VITAL HISTORY FOR CHARTS -----------------------------
  RxList<double> heartRateHistory = <double>[80, 82, 81, 83, 85].obs;
  RxList<double> oxygenHistory = <double>[95, 96, 97, 96, 98].obs;


  // ----------------------------- STATE FLAGS -----------------------------
  final RxBool isMapReady = false.obs;
  final RxBool isLoading = false.obs;

  // ----------------------------- RECEIVER DATA ---------------------------
  final RxString receiverId = "".obs;
  final RxString name = "Loading...".obs;
  final RxString profileUrl = "".obs;

  // ----------------------------- LOCATION DATA ---------------------------
  final RxDouble lat = 0.0.obs;
  final RxDouble lng = 0.0.obs;
  final RxString lastLocationRefresh = "Loading...".obs;

  final Rxn<DateTime> lastLocationUpdate = Rxn<DateTime>();


  // ----------------------------- VITALS DATA -----------------------------
  final RxString heartRate = "--".obs;
  final RxString oxygen = "--".obs;
  final RxBool fallDetected = false.obs;
  final Rxn<DateTime> lastVitalsUpdate = Rxn<DateTime>();
  final RxBool isVitalsStale = false.obs;
  final RxString vitalsStatusMessage = "".obs;

  // ----------------------------- DEVICE STATUS ---------------------------
  final RxBool fitbitConnected = false.obs;
  final RxInt battery = 82.obs;
  final RxBool isCharging = false.obs;
  // ----------------------------- MOOD DATA -----------------------------
  final RxString receiverMood = "".obs;
  final RxBool moodAvailable = false.obs;


  // ----------------------------- CONTROLLERS -----------------------------
  GoogleMapController? mapCtrl;
  RealtimeChannel? locationChannel;
  RealtimeChannel? vitalsChannel;
  RealtimeChannel? stepsChannel;
  RealtimeChannel? sosChannel;

  @override
  void onInit() {
    super.onInit();

    debugPrint("👨‍⚕️ CaregiverDashboardController INIT");


    final uid = supabase.auth.currentUser?.id;
    debugPrint("🔗 Auth UID used for care_links query: $uid");

    syncFcmToken();



  }
  @override
  void onReady() {
    super.onReady();
    loadReceiver();
    debugPrint("🔗 loadReceiver() CALLED");
  }


  @override
  void onClose() {
    locationChannel?.unsubscribe();
    vitalsChannel?.unsubscribe();
    stepsChannel?.unsubscribe();
    sosChannel?.unsubscribe();
    super.onClose();
  }


   
  // mood/status section
   
  Future<void> fetchReceiverMood() async {
    if (receiverId.value.isEmpty) return;

    final today =
    DateTime.now().toIso8601String().substring(0, 10);

    final row = await supabase
        .from('mood_tracking')
        .select('mood')
        .eq('user_id', receiverId.value)
        .eq('mood_date', today)
        .maybeSingle();

    if (row != null && row['mood'] != null) {
      receiverMood.value = row['mood'];
      moodAvailable.value = true;
    } else {
      receiverMood.value = "";
      moodAvailable.value = false;
    }
  }

  Future<void> fetchDeviceStatus() async {
    if (receiverId.value.isEmpty) return;

    final row = await supabase
        .from("device_status")
        .select()
        .eq("user_id", receiverId.value)
        .maybeSingle();

    if (row == null) return;

    battery.value = row["battery_level"] ?? 0;
    fitbitConnected.value = row["fitbit_connected"] ?? false;
    isCharging.value = row["charging"] ?? false;
  }





   
  // LOAD RECEIVER LINK
   
  Future<void> loadReceiver() async {
    debugPrint("🔗 loadReceiver started");
    isLoading.value = true;

    final uid = supabase.auth.currentUser?.id;
    debugPrint("👤 Caregiver UID: $uid");

    if (uid == null) {
      name.value = "User not logged in";
      isMapReady.value = true;
      isLoading.value = false;
      return;
    }

    try {

      final link = await supabase
          .from("care_links")
          .select("receiver_id")
          .eq("caregiver_id", uid)
          .maybeSingle();

      if (link == null || link["receiver_id"] == null) {
        name.value = "No Care Receiver Linked";
        receiverId.value = "";
        isMapReady.value = true;
        isLoading.value = false;
        return;
      }

      receiverId.value = link["receiver_id"];


      Get.find<NavController>().linkedReceiverId.value = receiverId.value;
      await Get.find<EventsController>()
          .loadEventsForReceiver(receiverId.value);

      debugPrint("🧑‍🦳 Receiver ID linked: ${receiverId.value}");


      await Future.wait([
        fetchReceiverProfile(),
        fetchReceiverMood(),
        fetchDeviceStatus(),
        fetchLatestLocation(),
        fetchLatestVitals(),
        fetchLatestSteps(),
      ]);


      subscribeToSOS();
      subscribeToStepsRealtime();
      subscribeToLocationRealtime();
      subscribeToVitalsRealtime();
    } catch (e) {
      name.value = "Error loading receiver";
      print("ERROR: $e");
    }

    isMapReady.value = true;
    isLoading.value = false;
  }

   
  // FETCH PROFILE
   
  Future<void> fetchReceiverProfile() async {
    if (receiverId.value.isEmpty) return;

    final userRepo = Get.isRegistered<UserRepository>()
        ? Get.find<UserRepository>()
        : UserRepository();

    final user = await userRepo.getUser(receiverId.value);

    name.value = user?.fullName ?? "Unknown Receiver";
    profileUrl.value = user?.profileImage ?? "";
  }

   
  // FETCH LATEST LOCATION
   
  // Replace existing fetchLatestLocation() with this
  Future<void> fetchLatestLocation() async {
    if (receiverId.value.isEmpty) {
      print("fetchLatestLocation: receiverId empty");
      return;
    }

    try {
      final row = await supabase
          .from('user_locations')
          .select('latitude, longitude, updated_at')
          .eq('user_id', receiverId.value)
          .order('updated_at', ascending: false)
          .limit(1)
          .maybeSingle();

      debugPrint('fetchLatestLocation raw: $row');

      if (row == null) {
        // no location: still allow UI to load
        isMapReady.value = true;
        return;
      }

      // Support multiple possible key names safely
      double? targetLat;
      double? targetLng;
      if (row['latitude'] != null && row['longitude'] != null) {
        targetLat = (row['latitude'] as num).toDouble();
        targetLng = (row['longitude'] as num).toDouble();
      } else if (row['lat'] != null && row['lng'] != null) {
        targetLat = (row['lat'] as num).toDouble();
        targetLng = (row['lng'] as num).toDouble();
      }

      if (targetLat == null || targetLng == null) {
        debugPrint('fetchLatestLocation: coordinates missing in row');
        isMapReady.value = true;
        return;
      }

      lat.value = targetLat;
      lng.value = targetLng;

      final updated = row['updated_at']?.toString();
      if (updated != null) {
        lastLocationUpdate.value = DateTime.parse(updated).toLocal();
        lastLocationRefresh.value = _formatTimeAgo(updated);
      }
      print('fetchLatestLocation raw: $row');
      // make UI visible
      isMapReady.value = true;

      // animate if map exists
      if (mapCtrl != null) {
        _animateMap();
      }
    } catch (e) {
      print('fetchLatestLocation error: $e');
      isMapReady.value = true; // let UI render even on error
    }
  }



   
  // SUBSCRIBE REALTIME LOCATION
   
  void subscribeToLocationRealtime() {
    if (receiverId.value.isEmpty) return;

    try { locationChannel?.unsubscribe(); } catch (_) {}

    // subscribe to both possible tables by creating two channels or pick the right one:
    final channelName = 'locations_${receiverId.value}';
    locationChannel = supabase.channel(channelName, opts: const RealtimeChannelConfig());

    locationChannel!
        .onPostgresChanges(
      event: PostgresChangeEvent.update,
      schema: 'public',
      table: 'user_locations', // keep user_locations if primary
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'user_id',
        value: receiverId.value,
      ),
      callback: (payload) {
        final newRow = payload.newRecord;
        // reuse parsing logic from fetchLatestLocation
        final latVal = (newRow['latitude'] as num?) ?? (newRow['lat'] as num?);
        final lngVal = (newRow['longitude'] as num?) ?? (newRow['lng'] as num?);
        if (latVal != null && lngVal != null) {
          lat.value = latVal.toDouble();
          lng.value = lngVal.toDouble();

          final updated = newRow['updated_at']?.toString();
          if (updated != null) {
            lastLocationUpdate.value = DateTime.parse(updated).toLocal();
            lastLocationRefresh.value = _formatTimeAgo(updated);
          }
          if (!isMapReady.value) isMapReady.value = true;
          _animateMap();
        }
      },
    ).subscribe();


  }





   
  // FETCH VITALS
   
  Future<void> fetchLatestVitals() async {
    if (receiverId.value.isEmpty) {
      debugPrint("fetchLatestVitals: NO RECEIVER ID");
      return;
    }

    final cacheKey = CacheService.userKey(receiverId.value, 'vitals');

    // 1. Load cached vitals first for instant display / offline support
    final cached = CacheService.instance.get<Map<String, dynamic>>(
      cacheKey,
      fromJson: (json) => Map<String, dynamic>.from(json as Map),
    );

    if (cached != null) {
      final data = cached.data;
      if (data['heart_rate'] != null) heartRate.value = data['heart_rate'].toString();
      if (data['oxygen'] != null) oxygen.value = data['oxygen'].toString();
      if (data['fall_detected'] != null) fallDetected.value = data['fall_detected'] == true;
      if (data['timestamp'] != null) {
        lastVitalsUpdate.value = DateTime.tryParse(data['timestamp'].toString())?.toLocal();
      }
      _checkVitalsFreshness();
    }

    try {
      final rows = await supabase
          .from("health_vitals")
          .select()
          .eq("user_id", receiverId.value)
          .order("timestamp", ascending: false)
          .limit(20);

      if (rows.isEmpty) {
        return;
      }

      Map<String, dynamic> latest = {};
      for (var row in rows) {
        if (!latest.containsKey(row["type"])) latest[row["type"]] = row;
      }

      String? latestTimestamp;

      // HEART
      if (latest["heart_rate"]?["value"] != null) {
        double hr = (latest["heart_rate"]["value"] as num).toDouble();
        heartRate.value = hr.toString();
        latestTimestamp ??= latest["heart_rate"]["timestamp"]?.toString();
      }

      // OXYGEN
      if (latest["oxygen"]?["value"] != null) {
        double oxy = (latest["oxygen"]["value"] as num).toDouble();
        oxygen.value = oxy.toString();
        latestTimestamp ??= latest["oxygen"]["timestamp"]?.toString();
      }

      // FALL
      if (latest["fall_detected"]?["value"] != null) {
        fallDetected.value = latest["fall_detected"]["value"] == 1;
        latestTimestamp ??= latest["fall_detected"]["timestamp"]?.toString();
      }

      if (latestTimestamp != null) {
        lastVitalsUpdate.value = DateTime.tryParse(latestTimestamp)?.toLocal();
      } else {
        lastVitalsUpdate.value = DateTime.now();
      }

      _checkVitalsFreshness();

      // Persist latest readings to cache
      await CacheService.instance.set(cacheKey, {
        'heart_rate': heartRate.value,
        'oxygen': oxygen.value,
        'fall_detected': fallDetected.value,
        'timestamp': lastVitalsUpdate.value?.toUtc().toIso8601String(),
      });
    } catch (e) {
      debugPrint("fetchLatestVitals network warning: $e");
      isVitalsStale.value = true;
      vitalsStatusMessage.value = "Offline • Cached data";
    }
  }

  void _checkVitalsFreshness() {
    if (lastVitalsUpdate.value == null) {
      isVitalsStale.value = true;
      vitalsStatusMessage.value = "";
      return;
    }
    final diff = DateTime.now().difference(lastVitalsUpdate.value!);
    if (diff.inMinutes > 15) {
      isVitalsStale.value = true;
      if (diff.inHours >= 1) {
        vitalsStatusMessage.value = "Stale • ${diff.inHours}h ago";
      } else {
        vitalsStatusMessage.value = "Stale • ${diff.inMinutes}m ago";
      }
    } else {
      isVitalsStale.value = false;
      vitalsStatusMessage.value = "Live";
    }
  }



   
  // SUBSCRIBE REALTIME VITALS
   
  void subscribeToVitalsRealtime() {
    if (receiverId.value.isEmpty) return;

    vitalsChannel?.unsubscribe();

    vitalsChannel = supabase.channel("vitals_${receiverId.value}");

    vitalsChannel!
        .onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: "public",
      table: "health_vitals",
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: "user_id",
        value: receiverId.value,
      ),
      callback: (payload) {
        final row = payload.newRecord;

        switch (row["type"]) {
          case "heart_rate":
            double hr = (row["value"] as num).toDouble();
            heartRate.value = hr.toString();

            heartRateHistory.add(hr);
            if (heartRateHistory.length > 20) heartRateHistory.removeAt(0);
            break;

          case "oxygen":
            double oxy = (row["value"] as num).toDouble();
            oxygen.value = oxy.toString();

            oxygenHistory.add(oxy);
            if (oxygenHistory.length > 20) oxygenHistory.removeAt(0);
            break;

          case "fall_detected":
            fallDetected.value = row["value"] == 1;
            break;
        }

        lastVitalsUpdate.value = DateTime.now();
        isVitalsStale.value = false;
        vitalsStatusMessage.value = "Live";
      },
    ).subscribe();
  }

   
  // MAP HANDLING
   
  void onMapCreated(GoogleMapController c) {
    mapCtrl = c;
    _mapReady = true;
    isMapReady.value = true;

    _animateMap(); // safe now
  }

   
  // MANUAL REFRESH
   
  RxBool isRefreshing = false.obs;

  Future<void> refreshData() async {
    if (isRefreshing.value) return;

    try {
      isRefreshing.value = true;
      debugPrint("🔄 FULL DASHBOARD REFRESH STARTED");

      final stopwatch = Stopwatch()..start();

      // Run independent fetches in parallel (FAST + PRODUCTION READY)
      await Future.wait([
        fetchLatestLocation(),
        fetchLatestVitals(),
        fetchDeviceStatus(),
        fetchReceiverMood(),
        fetchLatestSteps(),
        _refreshTasks(),
        _refreshEvents(),
      ]);

      stopwatch.stop();
      debugPrint("✅ Dashboard refreshed in ${stopwatch.elapsedMilliseconds}ms");
    } catch (e) {
      debugPrint("❌ Refresh error: $e");
    } finally {
      isRefreshing.value = false;
    }
  }

   
// UTILS
 
  String _formatTimeAgo(String timestamp) {
    try {
      final local = DateTime.parse(timestamp).toLocal();
      final diff = DateTime.now().difference(local);

      if (diff.inMinutes < 1) return "Just now";
      if (diff.inHours < 1) return "${diff.inMinutes}m ago";
      if (diff.inDays < 1) return "${diff.inHours}h ago";
      return "${diff.inDays}d ago";
    } catch (e) {
      return timestamp;
    }
  }


  bool _mapReady = false;
  DateTime? _lastCameraMove;


  void _animateMap() {
    if (!_mapReady) return;
    if (mapCtrl == null) return;
    if (lat.value == 0.0 || lng.value == 0.0) return;

    // throttle camera moves (VERY IMPORTANT)
    if (_lastCameraMove != null &&
        DateTime.now().difference(_lastCameraMove!).inSeconds < 2) {
      return;
    }

    _lastCameraMove = DateTime.now();

    try {
      mapCtrl!.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(lat.value, lng.value),
          15,
        ),
      );
    } catch (e) {
      debugPrint("⚠️ animateCamera skipped safely: $e");
    }
  }

  final batery = Battery();

  Future<void> sendBatteryToSupabase(String userId) async {
    final level = await batery.batteryLevel;

    await Supabase.instance.client
        .from("device_status")
        .upsert({
      "user_id": userId,
      "battery_level": level,
      "updated_at": DateTime.now().toIso8601String(),
    });
  }


  //pedometer - for steps


// ====================== STEPS ======================
  RxString steps = "--".obs;



  Future<void> fetchLatestSteps() async {
    if (receiverId.value.isEmpty) return;

    final row = await supabase
        .from("steps_data")
        .select("steps")
        .eq("user_id", receiverId.value)
        .order("updated_at", ascending: false)
        .limit(1)
        .maybeSingle();

    if (row != null && row["steps"] != null) {
      steps.value = row["steps"].toString();
    }
  }

  void subscribeToStepsRealtime() {
    if (receiverId.value.isEmpty) return;

    try { stepsChannel?.unsubscribe(); } catch (_) {}

    stepsChannel = supabase.channel("steps_${receiverId.value}");

    stepsChannel!.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: "public",
      table: "steps_data",
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: "user_id",
        value: receiverId.value,
      ),
      callback: (payload) {
        final newSteps = payload.newRecord["steps"];
        if (newSteps != null) {
          steps.value = newSteps.toString();
        }
      },
    ).subscribe();
  }

// sos implementation

  void subscribeToSOS() {
    if (receiverId.value.isEmpty) {
      debugPrint("🚨 SOS subscribe skipped: receiverId empty");
      return;
    }

    debugPrint("🚨 Subscribing to SOS for receiver ${receiverId.value}");

    sosChannel?.unsubscribe();

    sosChannel = supabase.channel('sos_${receiverId.value}');

    sosChannel!
        .onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'sos_alerts',
      filter: PostgresChangeFilter(
        column: 'user_id',
        value: receiverId.value,
        type: PostgresChangeFilterType.eq,
      ),
      callback: (payload) {
        debugPrint("🚨 SOS PAYLOAD RECEIVED: ${payload.newRecord}");

        EmergencyAlertService.trigger();

        _showSOSDialog(payload.newRecord);
      },
    ).subscribe();

    debugPrint("✅ SOS channel subscribed");
  }





  void _showSOSDialog(Map<String, dynamic> sos) {
    if (Get.context == null) {
      debugPrint("⚠️ SOS dialog skipped: no context");
      return;
    }

    if (Get.isDialogOpen == true) {
      debugPrint("⚠️ SOS dialog already open");
      return;
    }
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFeaf4f2), Colors.white],
            ),
            borderRadius: BorderRadius.all(Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.warning_amber_rounded, size: 48, color: Colors.red),
              const SizedBox(height: 12),
              Text(
                "Emergency Alert",
                style: GoogleFonts.nunito(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "The care receiver has triggered an SOS.",
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  EmergencyAlertService.stop();
                  final navController = Get.find<NavController>();
                  navController.changeTab(2);
                  Get.back();



                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text("View Location",style: TextStyle(color: Colors.white,fontWeight: FontWeight.bold),),
              )
            ],
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }
  Future<void> syncFcmToken() async {
    if (kIsWeb) return;
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

    if (token != null) {
      await supabase
          .from('users')
          .update({'fcm_token': token})
          .eq('id', userId);

      debugPrint("✅ FCM token saved to Supabase");
    }

    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      debugPrint("🔄 FCM token refreshed: $newToken");

      await supabase
          .from('users')
          .update({'fcm_token': newToken})
          .eq('id', userId);

      debugPrint("✅ Updated refreshed token in Supabase");
    });
  }
  Future<void> _refreshTasks() async {
    if (receiverId.value.isEmpty) return;

    try {
      final taskController = Get.find<TaskController>();
      await taskController.loadTasksForReceiver(receiverId.value);
    } catch (_) {}
  }

  Future<void> _refreshEvents() async {
    try {
      final eventController = Get.find<EventsController>();
      await eventController.loadEventsForReceiver(receiverId.value);
    } catch (_) {}
  }






}
