import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/location_service.dart';
import '../../dashboard/controllers/nav_controller.dart';

class LocationController extends GetxController {
  final String linkedUserId;
  final SupabaseClient? _supabase;
  SupabaseClient get supabase => _supabase ?? Supabase.instance.client;

  LocationController({
    required this.linkedUserId,
    SupabaseClient? supabase,
  }) : _supabase = supabase;

  final LocationService _locationService = LocationService();

  // Google map controller
  GoogleMapController? gmapController;

  // Observables
  final Rx<LatLng?> receiverLocation = Rx<LatLng?>(null);
  final Rx<DateTime?> lastUpdatedAt = Rx<DateTime?>(null);
  final isLoading = true.obs;
  final RxString timeAgo = ''.obs;

  // Geofence properties
  final Rx<LatLng?> safeCenter = Rx<LatLng?>(null);
  final RxInt safeRadius = 300.obs; // meters
  final RxBool geofenceActive = false.obs;
  final RxBool geofenceTriggered = false.obs;

  Timer? _timer;
  RealtimeChannel? _trackingChannel;
  Timer? _pollTimer;
  Worker? _navWorker;

  @override
  void onInit() {
    super.onInit();
    _startTimeAgoTimer();
    fetchAll();
    _subscribeToBroadcast();
    _setupNavListener();
  }

  void _setupNavListener() {
    _navWorker?.dispose();
    if (Get.isRegistered<NavController>()) {
      final nav = Get.find<NavController>();
      if (nav.selectedIndex.value == 2) {
        resumePolling();
      } else {
        pausePolling();
      }

      _navWorker = ever<int>(nav.selectedIndex, (index) {
        if (index == 2) {
          resumePolling();
        } else {
          pausePolling();
        }
      });
    } else {
      resumePolling();
    }
  }

  void pausePolling() {
    debugPrint("⏸️ [LocationController] Pausing 120s polling timer");
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  void resumePolling() {
    debugPrint("▶️ [LocationController] Resuming 120s polling timer");
    _pollTimer?.cancel();
    fetchLocation();
    _pollTimer = Timer.periodic(
      const Duration(seconds: 120),
      (_) => fetchLocation(),
    );
  }

  void _subscribeToBroadcast() {
    if (linkedUserId.isEmpty) return;
    _cleanupTrackingChannel();

    try {
      final channelName = 'tracking:$linkedUserId';
      _trackingChannel = supabase.channel(channelName);
      _trackingChannel!
          .onBroadcast(
            event: 'location_update',
            callback: (payload) {
              final lat = (payload['latitude'] as num?)?.toDouble() ??
                  (payload['lat'] as num?)?.toDouble();
              final lng = (payload['longitude'] as num?)?.toDouble() ??
                  (payload['lng'] as num?)?.toDouble();

              if (lat != null && lng != null) {
                receiverLocation.value = LatLng(lat, lng);

                final updated = payload['updated_at']?.toString();
                if (updated != null) {
                  lastUpdatedAt.value =
                      DateTime.tryParse(updated)?.toLocal() ?? DateTime.now();
                } else {
                  lastUpdatedAt.value = DateTime.now();
                }
                _updateTimeAgo();

                if (gmapController != null && receiverLocation.value != null) {
                  gmapController!.animateCamera(
                    CameraUpdate.newLatLng(receiverLocation.value!),
                  );
                }

                _checkGeofence();
              }
            },
          )
          .subscribe();
    } catch (e) {
      debugPrint("⚠️ LocationController broadcast subscribe error: $e");
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

  @override
  void onClose() {
    _navWorker?.dispose();
    _timer?.cancel();
    pausePolling();
    _cleanupTrackingChannel();
    super.onClose();
  }

  void _startTimeAgoTimer() {
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _updateTimeAgo();
    });
  }

  void _updateTimeAgo() {
    if (lastUpdatedAt.value == null) {
      timeAgo.value = '';
      return;
    }
    final diff = DateTime.now().difference(lastUpdatedAt.value!);
    if (diff.inMinutes < 1) {
      timeAgo.value = 'Updated just now';
    } else if (diff.inMinutes < 60) {
      timeAgo.value = 'Updated ${diff.inMinutes} minute(s) ago';
    } else if (diff.inHours < 24) {
      timeAgo.value = 'Updated ${diff.inHours} hour(s) ago';
    } else {
      timeAgo.value = 'Updated ${diff.inDays} day(s) ago';
    }
  }

  /// Call when map is created
  void onMapCreated(GoogleMapController controller) {
    gmapController = controller;
    // apply custom style if needed
    // controller.setMapStyle(_mapStyle);
    // if we already have receiverLocation, move camera
    if (receiverLocation.value != null) {
      controller.animateCamera(CameraUpdate.newLatLngZoom(receiverLocation.value!, 15.0));
    }
  }

  /// Fetch both location and existing geofence
  Future<void> fetchAll() async {
    isLoading.value = true;
    await Future.wait([fetchLocation(), fetchGeofence()]);
    isLoading.value = false;
  }

  Future<void> fetchLocation({bool isRefresh = false}) async {
    try {
      print("📡 Fetching location for linkedUserId: $linkedUserId");
      final data = await _locationService.getLocationOfLinkedUser(linkedUserId);
      if (data != null && data['latitude'] != null && data['longitude'] != null) {
        final lat = (data['latitude'] as num).toDouble();
        final lng = (data['longitude'] as num).toDouble();
        receiverLocation.value = LatLng(lat, lng);
        if (data['updated_at'] != null) {
          final raw = data['updated_at'] as String;

          debugPrint("🕒 RAW updated_at from DB: $raw");

          final parsed = DateTime.parse(raw);
          final localTime = parsed.toLocal();

          debugPrint("🕒 Parsed local time: $localTime");

          lastUpdatedAt.value = localTime;
          _updateTimeAgo();
        }



        // center map on update only if user hasn't panned the map (we keep it simple and center)
        if (gmapController != null) {
          gmapController!.animateCamera(CameraUpdate.newLatLng(receiverLocation.value!));
        }

        _checkGeofence();
      } else {
        if (isRefresh) {
          Get.snackbar('Location Not Found', 'Receiver may not be sharing location', snackPosition: SnackPosition.BOTTOM);
        }
      }
    } catch (e) {
      print('[LocationController] fetchLocation error: $e');
      Future.delayed(Duration.zero, () {
        Get.snackbar('Error', 'Unable to fetch location', snackPosition: SnackPosition.BOTTOM);
      });

    }
  }

  Future<void> fetchGeofence() async {
    try {
      final g = await _locationService.fetchGeofence(linkedUserId);
      if (g != null) {
        safeCenter.value = LatLng((g['latitude'] as num).toDouble(), (g['longitude'] as num).toDouble());
        safeRadius.value = (g['radius'] as num).toInt();
        geofenceActive.value = true;
      } else {
        safeCenter.value = null;
        geofenceActive.value = false;
      }
    } catch (e) {
      print('[LocationController] fetchGeofence error: $e');
    }
  }

  Future<void> saveGeofence(LatLng center, int radius) async {
    final ok = await _locationService.saveGeofence(linkedUserId, center.latitude, center.longitude, radius);
    if (ok) {
      safeCenter.value = center;
      safeRadius.value = radius;
      geofenceActive.value = true;
      Get.snackbar('Saved', 'Safe zone saved successfully', snackPosition: SnackPosition.BOTTOM);
      _checkGeofence();
    } else {
      Get.snackbar('Error', 'Could not save safe zone', snackPosition: SnackPosition.BOTTOM);
    }
  }

  Future<void> removeGeofence() async {
    final ok = await _locationService.removeGeofence(linkedUserId);
    if (ok) {
      safeCenter.value = null;
      safeRadius.value = 300;
      geofenceActive.value = false;
      geofenceTriggered.value = false;
      Get.snackbar('Removed', 'Safe zone removed', snackPosition: SnackPosition.BOTTOM);
    } else {
      Get.snackbar('Error', 'Could not remove safe zone', snackPosition: SnackPosition.BOTTOM);
    }
  }

  void _checkGeofence() {
    if (!geofenceActive.value || safeCenter.value == null || receiverLocation.value == null) {
      geofenceTriggered.value = false;
      return;
    }
    final dist = Geolocator.distanceBetween(
      safeCenter.value!.latitude,
      safeCenter.value!.longitude,
      receiverLocation.value!.latitude,
      receiverLocation.value!.longitude,
    ); // in meters
    if (dist > safeRadius.value) {
      geofenceTriggered.value = true;
    } else {
      geofenceTriggered.value = false;
    }
  }

  /// Utility: set safe center to current receiver location (for easy set)
  void setSafeCenterToReceiver() {
    if (receiverLocation.value != null) {
      safeCenter.value = receiverLocation.value;
    }
  }
}


