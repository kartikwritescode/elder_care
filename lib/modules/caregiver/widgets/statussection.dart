import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../care_receiver/controllers/activity_controller.dart';
import '../controllers/caregiver_dashboard_controller.dart';

class StatusSection extends StatefulWidget {
  const StatusSection({super.key});

  @override
  State<StatusSection> createState() => _StatusSectionState();
}

class _StatusSectionState extends State<StatusSection> {
  CaregiverDashboardController get controller => Get.find<CaregiverDashboardController>();
  ActivityController? get activity => Get.isRegistered<ActivityController>() ? Get.find<ActivityController>() : null;
  final now = DateTime.now().obs;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();

    // update "Xm ago" every minute (same as Receiver)
    _ticker = Timer.periodic(const Duration(minutes: 1), (_) {
      now.value = DateTime.now();
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final mood = controller.receiverMood.value;
      final hasMood = controller.moodAvailable.value;

      final battery = controller.battery.value;
      final charging = controller.isCharging.value;
      final connected = controller.fitbitConnected.value;

      final syncing = controller.isRefreshing.value;
      final lastSync = controller.lastLocationUpdate.value;

      return Padding(
        padding: EdgeInsets.symmetric(horizontal: Get.width * 0.05),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFF6F8F7),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Mood
              Expanded(
                child: Row(
                  children: [
                    Text(
                      _emojiOnlyForMood(mood, hasMood),
                      style: const TextStyle(fontSize: 18),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        _labelForMood(mood, hasMood),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.manrope(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 10),

              // Wearable
              _statusChip(
                icon: connected ? Icons.watch : Icons.watch_off,
                bg: connected ? Colors.teal.shade50 : Colors.red.shade50,
                iconColor:
                connected ? Colors.teal.shade700 : Colors.red.shade700,
              ),

              const SizedBox(width: 8),

              // Battery status
              _statusChip(
                icon: charging
                    ? Icons.battery_charging_full
                    : Icons.battery_full,
                label: "$battery%",
                iconColor:
                battery > 40 ? Colors.green : Colors.orange,
              ),

              const SizedBox(width: 8),

              // Sync
              GestureDetector(
                onTap: syncing ? null : controller.refreshData,
                child: Container(
                  height: 32,
                  padding:
                  const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border:
                    Border.all(color: Colors.blue.shade300),
                  ),
                  child: Row(
                    children: [
                      Text(
                        _adaptiveSyncLabel(lastSync, now.value),
                        style: GoogleFonts.manrope(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.blueGrey,
                        ),
                      ),
                      const SizedBox(width: 6),
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: syncing ? 4 : 0),
                        duration: const Duration(seconds: 1),
                        builder: (context, value, child) {
                          return Transform.rotate(
                            angle: value * 3.14,
                            child: child,
                          );
                        },
                        child: const Icon(
                          Icons.sync,
                          size: 14,
                          color: Colors.blueGrey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );

    });
  }
}
String _adaptiveSyncLabel(DateTime? last, DateTime now) {
  if (last == null) return "Sync";

  final diff = now.difference(last);

  if (diff.inMinutes < 1) return "Now";
  if (diff.inMinutes < 60) return "${diff.inMinutes}m";
  return "${diff.inHours}h";
}
String _labelForMood(String mood, bool hasMood) {
  if (!hasMood) return "Mood not updated";

  switch (mood) {
    case "very_happy":
      return "Feeling great";
    case "happy":
      return "Feeling good";
    case "neutral":
      return "Feeling okay";
    case "sad":
      return "Feeling low";
    case "very_sad":
      return "Feeling very low";
    default:
      return "Feeling okay";
  }
}

String _emojiOnlyForMood(String mood, bool hasMood) {
  if (!hasMood) return "😐";

  switch (mood) {
    case "very_happy":
      return "😄";
    case "happy":
      return "🙂";
    case "neutral":
      return "😐";
    case "sad":
      return "🙁";
    case "very_sad":
      return "😢";
    default:
      return "😐";
  }
}
Widget _statusChip({
  required IconData icon,
  String? label,
  Color bg = Colors.white,
  Color iconColor = Colors.black54,
}) {
  return Container(
    height: 32,
    padding: const EdgeInsets.symmetric(horizontal: 10),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(
      children: [
        Icon(icon, size: 16, color: iconColor),
        if (label != null) ...[
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.manrope(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ],
      ],
    ),
  );
}

