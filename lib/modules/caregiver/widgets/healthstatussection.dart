import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/caregiver_dashboard_controller.dart';

Widget healthStatusSection() {
  return const HealthStatusSectionWidget();
}

class HealthStatusSectionWidget extends StatelessWidget {
  const HealthStatusSectionWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<CaregiverDashboardController>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: Get.width * 0.05),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "HEALTH STATUS",
                style: GoogleFonts.nunito(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Colors.black87,
                ),
              ),
              Obx(() {
                if (controller.vitalsStatusMessage.value.isEmpty) {
                  return const SizedBox.shrink();
                }
                final isStale = controller.isVitalsStale.value;
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isStale ? Colors.amber.shade50 : Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isStale ? Colors.amber.shade300 : Colors.green.shade300,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isStale ? Icons.history : Icons.check_circle_outline,
                        size: 12,
                        color: isStale ? Colors.amber.shade800 : Colors.green.shade700,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        controller.vitalsStatusMessage.value,
                        style: GoogleFonts.nunito(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isStale ? Colors.amber.shade900 : Colors.green.shade800,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),

        const SizedBox(height: 14),

        Obx(() {
          final hr = controller.heartRate.value == "--"
              ? "--"
              : "${controller.heartRate.value} bpm";

          final oxy = controller.oxygen.value == "--"
              ? "--"
              : "${controller.oxygen.value}%";

          final isFall = controller.fallDetected.value;
          final stepCount = controller.steps.value == "--"
              ? "--"
              : controller.steps.value;

          return SizedBox(
            height: 115,
            child: ListView(
              padding: EdgeInsets.only(left: Get.width * 0.05),
              scrollDirection: Axis.horizontal,
              children: [
                healthCard(
                  icon: Icons.favorite,
                  iconColor: Colors.redAccent,
                  label: "Heart Rate",
                  value: hr,
                  gradient: [
                    Colors.redAccent.withValues(alpha: 0.15),
                    Colors.redAccent.withValues(alpha: 0.05),
                  ],
                ),
                const SizedBox(width: 12),

                healthCard(
                  icon: Icons.warning_amber_rounded,
                  iconColor: isFall ? Colors.orange : Colors.green,
                  label: "Fall",
                  value: isFall ? "Fall Detected" : "No Fall",
                  gradient: [
                    Colors.orange.withValues(alpha: 0.15),
                    Colors.orange.withValues(alpha: 0.05),
                  ],
                ),
                const SizedBox(width: 12),

                healthCard(
                  icon: Icons.directions_walk,
                  iconColor: Colors.deepPurple,
                  label: "Steps",
                  value: stepCount,
                  gradient: [
                    Colors.deepPurple.withValues(alpha: 0.15),
                    Colors.deepPurple.withValues(alpha: 0.05),
                  ],
                ),
                const SizedBox(width: 12),

                healthCard(
                  icon: Icons.water_drop_rounded,
                  iconColor: Colors.blueAccent,
                  label: "Oxygen",
                  value: oxy,
                  gradient: [
                    Colors.blueAccent.withValues(alpha: 0.15),
                    Colors.blueAccent.withValues(alpha: 0.05),
                  ],
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

Widget healthCard({
  required IconData icon,
  required Color iconColor,
  required String label,
  required String value,
  required List<Color> gradient,
}) {
  return Container(
    width: Get.width * 0.28,
    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(16),
      gradient: LinearGradient(
        colors: gradient,
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.05),
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 24, color: iconColor),

        const SizedBox(height: 10),

        Text(
          value,
          style: GoogleFonts.nunito(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: Colors.black87,
          ),
        ),

        const SizedBox(height: 2),

        Text(
          label,
          style: GoogleFonts.nunito(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.black54,
          ),
        ),
      ],
    ),
  );
}
