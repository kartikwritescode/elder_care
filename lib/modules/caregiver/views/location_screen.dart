import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../controllers/caregiver_dashboard_controller.dart';
import '../controllers/location_controller.dart';

class LocationScreen extends StatelessWidget {
  const LocationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    debugPrint("🗺️ LocationScreen BUILD");

    final CaregiverDashboardController dashboard = Get.find<CaregiverDashboardController>();

    return Obx(() {
      final linkedUserId = dashboard.receiverId.value;

      debugPrint("🗺️ linkedReceiverId = $linkedUserId");

      // Receiver not linked yet
      if (linkedUserId.isEmpty) {
        return const Scaffold(
          body: Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.warning_amber_rounded,
                      size: 60, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    "No receiver linked yet.",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18),
                  ),
                ],
              ),
            ),
          ),
        );
      }

      // receiver IS linked → get or create controller
      final controller = Get.isRegistered<LocationController>(tag: linkedUserId)
          ? Get.find<LocationController>(tag: linkedUserId)
          : Get.put(
              LocationController(linkedUserId: linkedUserId),
              tag: linkedUserId,
            );

      return _buildLocationMapUI(controller);
    });
  }


  // MARKERS
  Set<Marker> _markers(LocationController c) {
    final set = <Marker>{};

    if (c.receiverLocation.value != null) {
      set.add(
        Marker(
          markerId: const MarkerId("receiver"),
          position: c.receiverLocation.value!,
          icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueRed),
        ),
      );
    }

    if (c.safeCenter.value != null) {
      set.add(
        Marker(
          markerId: const MarkerId("safe_center"),
          position: c.safeCenter.value!,
          icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueAzure),
        ),
      );
    }

    return set;
  }

  // CIRCLES
  Set<Circle> _circles(LocationController c) {
    final set = <Circle>{};

    if (c.safeCenter.value != null) {
      set.add(
        Circle(
          circleId: const CircleId("safe_zone"),
          center: c.safeCenter.value!,
          radius: c.safeRadius.value.toDouble(),
          strokeWidth: 2,
          strokeColor: Colors.teal.withValues(alpha: 0.7),
          fillColor: Colors.teal.withValues(alpha: 0.18),
        ),
      );
    }

    return set;
  }

  // safe zone panel
  Widget _topStatusCard(LocationController c) {
    return Card(
      elevation: 10,
      color: Colors.white.withAlpha(230),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding:
        const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Obx(() {
          final timeAgo = c.timeAgo.value;

          return Row(
            children: [
              Expanded(
                child: Text(
                  timeAgo.isEmpty
                      ? "Last known location"
                      : timeAgo,
                  style: GoogleFonts.nunito(fontSize: 15),
                ),
              ),

              if (!c.geofenceActive.value)
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7AB7A7),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => _openGeofenceEditor(c),
                  child: const Text(
                    "Set Safe Zone",
                    style: TextStyle(color: Colors.white),
                  ),
                )
              else
                Row(
                  children: [
                    if (c.geofenceTriggered.value)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.redAccent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          "Exited!",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7AB7A7),
                      ),
                      onPressed: () => _openGeofenceEditor(c),
                      child: const Text("Edit Safe Zone",
                          style: TextStyle(color: Colors.white)),
                    ),
                    IconButton(
                      onPressed: () => c.removeGeofence(),
                      icon: const Icon(Icons.delete_outline),
                    ),
                  ],
                ),
            ],
          );
        }),
      ),
    );
  }

  // distance chip
  Widget _distanceChip(LocationController c) {
    return Obx(() {
      if (!c.geofenceActive.value ||
          c.safeCenter.value == null ||
          c.receiverLocation.value == null) {
        return const SizedBox.shrink();
      }

      final dist = Geolocator.distanceBetween(
        c.safeCenter.value!.latitude,
        c.safeCenter.value!.longitude,
        c.receiverLocation.value!.latitude,
        c.receiverLocation.value!.longitude,
      ).round();

      return Card(
        color: Colors.black.withValues(alpha: 0.7),
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: 14, vertical: 10),
          child: Text(
            "${c.geofenceTriggered.value ? 'Outside' : 'Inside'} safe zone • $dist m",
            style: GoogleFonts.nunito(
                color: Colors.white, fontSize: 15),
          ),
        ),
      );
    });
  }

  // bottom sheet
  void _openGeofenceEditor(LocationController c) {
    showModalBottomSheet(
      context: Get.context!,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius:
          BorderRadius.vertical(top: Radius.circular(18))),
      builder: (_) => _geofenceEditorUI(c),
    );
  }

  // SAFE ZONE EDITOR
  Widget _geofenceEditorUI(LocationController c) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Obx(() {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 20),

            Text("Safe Zone Settings",
                style: GoogleFonts.nunito(
                    fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 20),

            Text("Radius: ${c.safeRadius.value} meters"),
            Slider(
              value: c.safeRadius.value.toDouble(),
              min: 100,
              max: 5000,
              divisions: 49,
              activeColor: const Color(0xFF7AB7A7),
              onChanged: (v) => c.safeRadius.value = v.toInt(),
            ),

            const SizedBox(height: 10),

            // SELECT LOCATION + USE RECEIVER LOCATION (SIDE-BY-SIDE)
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7AB7A7),
                    ),
                    icon: const Icon(Icons.add_location_alt_outlined,
                        color: Colors.white),
                    onPressed: () {
                      Get.snackbar(
                        "Tap on Map",
                        "Tap anywhere on the map to select safe zone center.",
                        snackPosition: SnackPosition.BOTTOM,
                      );
                    },
                    label: const Text("Select Location",
                        style: TextStyle(color: Colors.white)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7AB7A7),
                    ),
                    icon: const Icon(Icons.my_location,
                        color: Colors.white),
                    onPressed: () {
                      if (c.receiverLocation.value != null) {
                        c.safeCenter.value = c.receiverLocation.value;
                      }
                    },
                    label: const Text("Use Receiver Location",
                        style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // SAVE BUTTON WITH FALLBACK VALIDATION
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7AB7A7),
                minimumSize: const Size(double.infinity, 48),
              ),
              onPressed: () {
                if (c.safeCenter.value == null) {
                  Get.snackbar(
                    "No Center Selected",
                    "Please tap on map or use receiver location.",
                    snackPosition: SnackPosition.BOTTOM,
                  );
                  return;
                }

                c.saveGeofence(
                  c.safeCenter.value!,
                  c.safeRadius.value,
                );

                Get.back();
              },
              child: const Text("Save Safe Zone",
                  style: TextStyle(color: Colors.white)),
            ),

            const SizedBox(height: 20),
          ],
        );
      }),
    );
  }
  Widget _buildLocationMapUI(LocationController controller) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFeaf4f2), Color(0xFFfdfaf6)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          // MAP WITH TAP HANDLER =========================================
          Obx(() {
            if (controller.isLoading.value &&
                controller.receiverLocation.value == null) {
              return const Center(child: CircularProgressIndicator());
            }

            final initial = controller.receiverLocation.value ??
                LatLng(20.5937, 78.9629);

            return GoogleMap(
              initialCameraPosition: CameraPosition(
                target: initial,
                zoom: 15,
              ),
              onMapCreated: controller.onMapCreated,

              zoomControlsEnabled: false,
              myLocationButtonEnabled: false,

              zoomGesturesEnabled: true,
              scrollGesturesEnabled: true,
              rotateGesturesEnabled: true,
              tiltGesturesEnabled: true,

              markers: _markers(controller),
              circles: _circles(controller),

              onTap: (pos) {
                controller.safeCenter.value = pos;
                Get.snackbar(
                  "Safe Zone Center Selected",
                  "Tap Save to confirm this location.",
                  snackPosition: SnackPosition.BOTTOM,
                );
              },
            );
          }),

          // FLOATING APPBAR
          Positioned(
            top: 40,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                color: Colors.white.withValues(alpha: 0.75),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  )
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // BACK BUTTON
                  GestureDetector(
                    onTap: () => Get.back(),
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF7AB7A7).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.all(6),
                      child: const Icon(Icons.arrow_back,
                          color: Color(0xFF7AB7A7)),
                    ),
                  ),

                  Text(
                    "Receiver’s Location",
                    style: GoogleFonts.nunito(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.black87,
                    ),
                  ),

                  GestureDetector(
                    onTap: () => controller.fetchLocation(isRefresh: true),
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF7AB7A7).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.all(6),
                      child: const Icon(Icons.refresh,
                          color: Color(0xFF7AB7A7)),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // SAFE ZONE PANEL ===============================================
          Positioned(
            bottom: Get.height * 0.13,
            left: 16,
            right: 16,
            child: _topStatusCard(controller),
          ),

          // DISTANCE CHIP ================================================
          Positioned(
            bottom: 20,
            left: 16,
            right: 16,
            child: _distanceChip(controller),
          ),
        ],
      ),
    );
  }
}


