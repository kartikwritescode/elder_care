import 'dart:async';
import 'package:get/get.dart';
import '../../../core/services/location_service.dart';
import 'carereceiver_dashboard_controller.dart';

class ReceiverLocationController extends GetxController {
  final LocationService _locationService = LocationService();

  Timer? _locationTimer;
  final RxBool permissionGranted = false.obs;

  @override
  void onInit() {
    super.onInit();
    _initLocationFlow();
  }

  Future<void> _initLocationFlow() async {
    final ok = await _locationService.requestPermissions();
    permissionGranted.value = ok;

    if (!ok) return;

    // 🔁 Start periodic updates
    _startTracking();
  }

  bool _isDashboardHandlingLocation() {
    if (Get.isRegistered<ReceiverDashboardController>()) {
      final dashboard = Get.find<ReceiverDashboardController>();
      return !dashboard.isClosed;
    }
    return false;
  }

  void cancelTrackingIfDashboardActive() {
    if (_isDashboardHandlingLocation()) {
      _locationTimer?.cancel();
      _locationTimer = null;
    }
  }

  void _startTracking() {
    if (_isDashboardHandlingLocation()) {
      // ReceiverDashboardController already manages location updates with geofencing
      _locationTimer?.cancel();
      _locationTimer = null;
      return;
    }
    // update immediately once
    _locationService.updateLocationInSupabase();

    // then every 2 minutes
    _locationTimer = Timer.periodic(
      const Duration(minutes: 2),
      (timer) {
        if (_isDashboardHandlingLocation()) {
          timer.cancel();
          _locationTimer = null;
          return;
        }
        _locationService.updateLocationInSupabase();
      },
    );
  }

  @override
  void onClose() {
    _locationTimer?.cancel();
    super.onClose();
  }
}
