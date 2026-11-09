import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import '../modules/care_receiver/controllers/activity_controller.dart';
import '../modules/care_receiver/controllers/carereceiver_dashboard_controller.dart';

class AppLifecycleHandler extends WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed ||
        state == AppLifecycleState.paused) {
      if (Get.isRegistered<ActivityController>()) {
        Get.find<ActivityController>().markActive();
      }
    }
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.hidden) {
      if (Get.isRegistered<ReceiverDashboardController>()) {
        Get.find<ReceiverDashboardController>().flushLocationToDatabase();
      }
    }
  }
}
