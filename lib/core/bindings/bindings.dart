import 'package:elder_care/core/repositories/event_repository.dart';
import 'package:elder_care/core/repositories/task_repository.dart';
import 'package:elder_care/core/repositories/user_repository.dart';
import 'package:elder_care/core/services/cache_service.dart';
import 'package:elder_care/modules/care_receiver/controllers/activity_controller.dart';
import 'package:elder_care/modules/caregiver/controllers/care_link_controller.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../../modules/auth/controllers/auth_controller.dart';
import '../../modules/care_receiver/controllers/schedule_controller.dart';
import '../../modules/dashboard/controllers/dashboard_controller.dart';
import '../../modules/dashboard/controllers/nav_controller.dart';
import '../../modules/events/controllers/events_controller.dart';
import '../../modules/tasks/controllers/task_controller.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    debugPrint("[InitialBinding] start");

    Get.put(CacheService.instance, permanent: true);
    Get.put(UserRepository(), permanent: true);
    Get.put(TaskRepository(), permanent: true);
    Get.put(EventRepository(), permanent: true);

    Get.put(AuthController(), permanent: true);
    Get.put(NavController(), permanent: true);
    Get.put(CareLinkController(), permanent: true);
    Get.put(TaskController(), permanent: true);
    Get.put(ActivityController(), permanent: true);
    Get.put(EventsController(), permanent: true);

    Get.lazyPut(() => DashboardController(), fenix: true);
    Get.lazyPut<ScheduleController>(() => ScheduleController(), fenix: true);

    debugPrint("[InitialBinding] end");
  }
}
