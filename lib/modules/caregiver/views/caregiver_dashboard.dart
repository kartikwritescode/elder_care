
import 'package:elder_care/modules/care_receiver/controllers/activity_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/widgets/app_cached_image.dart';
import '../../events/views/eventssection.dart';
import '../../tasks/controllers/task_controller.dart';
import '../widgets/caregiver_map.dart';
import '../widgets/healthstatussection.dart';
import '../../tasks/views/task_section.dart';
import '../controllers/caregiver_dashboard_controller.dart';
import '../widgets/statussection.dart';

class CaregiverDashboard extends StatefulWidget {
  const CaregiverDashboard({super.key});

  @override
  State<CaregiverDashboard> createState() => _CaregiverDashboardState();
}

class _CaregiverDashboardState extends State<CaregiverDashboard> {
  final activity = Get.isRegistered<ActivityController>()
      ? Get.find<ActivityController>()
      : Get.put(ActivityController());

  final controller = Get.find<CaregiverDashboardController>();
  final TaskController taskController = Get.find<TaskController>();

  Worker? _receiverWorker;

  @override
  void initState() {
    super.initState();
    debugPrint("🖥️ CaregiverDashboard initState");
    debugPrint("🖥️ receiverId at init: ${controller.receiverId.value}");

    // 1️⃣ If receiverId is ALREADY available
    final rid = controller.receiverId.value;
    if (rid.isNotEmpty) {
      taskController.loadTasksForReceiver(rid);
    }

    // 2️⃣ If receiverId comes LATER
    _receiverWorker = ever<String?>(controller.receiverId, (rid) {
      debugPrint("🖥️ Dashboard saw receiverId change → $rid");

      if (rid == null || rid.isEmpty) return;

      if (taskController.currentReceiverId != rid) {
        taskController.loadTasksForReceiver(rid);
      }
    });
  }

  @override
  void dispose() {
    _receiverWorker?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint("🖥️ CaregiverDashboard BUILD");
    debugPrint("🖥️ receiverId=${controller.receiverId.value}");
    debugPrint("🖥️ isMapReady=${controller.isMapReady.value}");

    final srch = Get.height;
    final srcw = Get.width;
    return Scaffold(
      backgroundColor: Colors.white,
      body: Obx(() {
        if (controller.receiverId.value.isEmpty) {
          if (!controller.isLoading.value) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.person_off_outlined, size: 60, color: Colors.grey),
                    const SizedBox(height: 16),
                    Text(
                      "No care receiver linked yet.",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.nunito(fontSize: 18, color: Colors.black54),
                    ),
                  ],
                ),
              ),
            );
          }
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (!controller.isMapReady.value) {
          return const Center(child: CircularProgressIndicator());
        }

          return SingleChildScrollView(
            padding: EdgeInsets.only(
              bottom: kBottomNavigationBarHeight*0.2,
            ),
            child: Column(
              children: [
                // =================== MAP + PANEL STACK ===================
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                      // MAP
                      SizedBox(
                        height: Get.height * 0.42,
                        width: double.infinity,
                        child: CaregiverMap(
                          lat: controller.lat.value,
                          lng: controller.lng.value,
                          onMapCreated: controller.onMapCreated,
                        ),
                      ),

                      // SizedBox(
                      //   height: Get.height * 0.42,
                      //   width: double.infinity,
                      //   child: GoogleMap(
                      //     markers: {
                      //       Marker(
                      //         markerId: const MarkerId("receiver"),
                      //         position: LatLng(
                      //           controller.lat.value,
                      //           controller.lng.value,
                      //         ),
                      //         icon: BitmapDescriptor.defaultMarkerWithHue(
                      //             BitmapDescriptor.hueRed),
                      //       ),
                      //     },
                      //     initialCameraPosition: CameraPosition(
                      //       target: LatLng(
                      //         controller.lat.value == 0 ? 20.5937 : controller.lat.value,
                      //         controller.lng.value == 0 ? 78.9629 : controller.lng.value,
                      //       ),
                      //       zoom: 14,
                      //     ),
                      //     onMapCreated: controller.onMapCreated,
                      //     zoomControlsEnabled: false,
                      //     gestureRecognizers: {
                      //       Factory<OneSequenceGestureRecognizer>(
                      //               () => EagerGestureRecognizer()),
                      //     },
                      //   ),
                      // ),

                      // WHITE PANEL
                      Positioned(
                        // top: Get.height * 0.28,
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          // padding:  EdgeInsets.only(left:Get.width*0.04),
                          decoration: const BoxDecoration(

                            color: Colors.white,
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(40),
                              topRight: Radius.circular(40),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [

                              //title and location
                          Row(
                            // mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                          SizedBox(width:srcw*0.35), // offset for profile image
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(height: srch*0.01,),
                              Text(
                                controller.name.value,
                                style: GoogleFonts.nunito(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black87,
                                ),
                              ),
                              SizedBox(height:srch*0.0001),
                              Text(
                                "Location refreshed ${controller.lastLocationRefresh.value}",
                                style: GoogleFonts.nunito(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                          ],
                        ),



                            ],
                          ),
                        ),
                      ),

                      // PROFILE PICTURE inside the white panel
                      Positioned(
                        // top: Get.height * 0.24,
                        bottom: srch*0.03,
                        left: srcw*.08,
                        child: Container(
                          width: 85,
                          height: 85,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: Colors.white, width: 4),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: controller.profileUrl.value.isEmpty
                                ? Image.asset("assets/images/def_png.png", fit: BoxFit.cover)
                                : AppCachedImage(
                                    imageUrl: controller.profileUrl.value,
                                    fit: BoxFit.cover,
                                    width: 85,
                                    height: 85,
                                    memCacheWidth: 200,
                                    memCacheHeight: 200,
                                    errorWidget: Image.asset(
                                      "assets/images/def_png.png",
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),

                // const SizedBox(height: 30),
                SizedBox(height:srch*0.01),
                // ReceiverStatusChips(),
                StatusSection(),
                SizedBox(height:srch*0.01),
                healthStatusSection(),
                // SizedBox(height:srch*0.01),
                SizedBox(height: srch * 0.015),
                EventSection(),
                SizedBox(height: srch * 0.02),

                TaskSection(),
                // SizedBox(height: srch * 0.05),




                // Bottom Action Buttons (Call, Emergency, Caregivers)


                // const SizedBox(height: 200),
              ],
            ),
          );
        }),
      );
    }




  }



