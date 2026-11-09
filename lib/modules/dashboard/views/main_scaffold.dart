import 'package:elder_care/modules/care_receiver/views/schedule_screen.dart';
import 'package:elder_care/modules/care_receiver/widgets/sos_floating_button.dart';
import 'package:elder_care/modules/chat/views/direct_chat.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../auth/controllers/auth_controller.dart';
import '../../care_receiver/controllers/activity_controller.dart';
import '../../care_receiver/controllers/carereceiver_dashboard_controller.dart';
import '../../care_receiver/controllers/reciever_location_controller.dart';
import '../../care_receiver/controllers/schedule_controller.dart';
import '../../caregiver/controllers/caregiver_dashboard_controller.dart';
import '../../caregiver/views/caregiver_dashboard.dart';
import '../../tasks/controllers/task_controller.dart';
import '../../tasks/widgets/add_edit_dialog.dart';
import '../widgets/bottom_navigation_bar.dart';
import '../controllers/nav_controller.dart';
import '../../profile/views/profile_screen.dart';
import '../../care_receiver/views/carereciever_dashboard.dart';
import '../../caregiver/views/location_screen.dart';

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  final NavController navController = Get.find<NavController>();
  final AuthController authController = Get.find<AuthController>();
  final SupabaseClient client = Supabase.instance.client;


  Color kTeal = Color(0xFF7AB7A7);

  late final List<Widget> caregiverScreens;
  late final List<Widget> receiverScreens;

  @override
  void initState() {
    super.initState();
    debugPrint("🏗️ MainScaffold INIT");

    // Ensure route / bottom nav tab resets to homescreen (index 0)
    navController.selectedIndex.value = 0;

    final user = authController.user.value;
    debugPrint("🏗️ User at MainScaffold init: ${user?.id} | role=${user?.role}");

    // 1️⃣ Global controllers (ONCE)
    if (!Get.isRegistered<TaskController>()) {
      Get.put(TaskController(), permanent: true);
    }

    // if (!Get.isRegistered<CaregiverDashboardController>()) {
    //   debugPrint("🧠 Registering CaregiverDashboardController");
    //   Get.put(CaregiverDashboardController());
    // } else {
    //   debugPrint("♻️ CaregiverDashboardController ALREADY registered");
    // }


    if (user?.role == 'receiver') {
      if (!Get.isRegistered<ReceiverDashboardController>()) {
        debugPrint("🧠 Registering ReceiverDashboardController");
        Get.put(ReceiverDashboardController(), permanent: true);
      }
    }
    if (user?.role == 'caregiver') {
      if (Get.isRegistered<ReceiverDashboardController>()) {
        Get.delete<ReceiverDashboardController>();
      }
      if (Get.isRegistered<ReceiverLocationController>()) {
        Get.delete<ReceiverLocationController>();
      }
      if (Get.isRegistered<ActivityController>()) {
        Get.delete<ActivityController>();
      }
    }

    // 2️⃣ Caregiver task wiring (SINGLE SOURCE OF TRUTH)
    if (user?.role == 'caregiver') {
      debugPrint("🧵 Wiring caregiver task listeners");

      if (!Get.isRegistered<CaregiverDashboardController>()) {
        Get.put(CaregiverDashboardController(), permanent: true);
      }

      final caregiverController = Get.find<CaregiverDashboardController>();
      final taskController = Get.find<TaskController>();

      // Load immediately if already linked
      final rid = caregiverController.receiverId.value;
      if (rid.isNotEmpty) {
        taskController.loadTasksForReceiver(rid);
      }

      // Load when receiver gets linked later
      ever<String?>(caregiverController.receiverId, (rid) {
        debugPrint("📡 receiverId changed → $rid");

        if (rid == null || rid.isEmpty) {
          debugPrint("⚠️ receiverId empty, skipping task load");
          return;
        }

        if (taskController.currentReceiverId != rid) {
          debugPrint("📥 Loading tasks for receiver $rid");
          taskController.loadTasksForReceiver(rid);
        }
      });

    }

    // 3️⃣ Receiver-only controllers
    if (user?.role == 'receiver') {
      if (!Get.isRegistered<ReceiverLocationController>()) {
        Get.put(ReceiverLocationController(), permanent: true);
      }
      if (!Get.isRegistered<ActivityController>()) {
        Get.put(ActivityController(), permanent: true);
      }
    }

    // 4️⃣ Screens (NO DATA PASSED)
    caregiverScreens = [
      CaregiverDashboard(),
      const DirectChatScreen(),
      const LocationScreen(),
      ProfileScreen(),
    ];

    receiverScreens = [
      ReceiverDashboardScreen(),
      const DirectChatScreen(),
      const ScheduleScreen(),
      ProfileScreen(),
    ];
  }


  @override
  Widget build(BuildContext context) {
    final user = authController.user.value;

    if (user == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF121212),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final screens =
    user.role == "caregiver" ? caregiverScreens : receiverScreens;

    return Scaffold(
      extendBody: true,
      // backgroundColor: const Color(0xFF121212),

      body: Obx(() {
        return IndexedStack(
          index: navController.selectedIndex.value,
          children: screens,
        );
      }),

      bottomNavigationBar: user.role == "caregiver"
          ? CareGiverBottomNavBar()
          : CareReceiverBottomNavBar(),



      floatingActionButton: Obx(() {
        final rxUser = authController.user.value;

        if (rxUser == null || rxUser.role != 'receiver') {
          return const SizedBox.shrink();
        }

        final index = navController.selectedIndex.value;

        // 🏠 Receiver Home → SOS only
        if (index == 0) {
          return SOSFab(Get.find<ReceiverDashboardController>());
        }

        // 📅 Schedule → Add Task only
        if (index == 2) {
          return FloatingActionButton(
            heroTag: 'addTask',
            backgroundColor: kTeal,
            child: const Icon(Icons.add,color: Colors.white,),
            onPressed: () async {
              final currentIndex = navController.selectedIndex.value;

              final result = await _openAddDialog(context, isEdit: false);

              // restore tab index
              navController.selectedIndex.value = currentIndex;

              // ONLY refresh ScheduleScreen if task was added
              if (result == true) {
                // this triggers ScheduleScreen's Obx rebuild
                Get.find<ScheduleController>().loading.value = true;
                await Future.delayed(const Duration(milliseconds: 1));
                Get.find<ScheduleController>().loadForCurrentUser(
                  Get.find<ScheduleController>().selectedDate.value,
                );
              }
            },

          );
        }

        return const SizedBox.shrink();
      }),

      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
  Future<bool?> _openAddDialog(BuildContext ctx, {required bool isEdit}) {
    return showDialog<bool>(
      context: ctx,
      builder: (_) => AddEditTaskDialog(
        isEdit: isEdit,
        controller: Get.find<TaskController>(),
      ),
    );
  }

}
