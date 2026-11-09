import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/carereceiver_dashboard_controller.dart';

class BatterySection extends StatelessWidget {
  const BatterySection({super.key});

  @override
  Widget build(BuildContext context) {
    final ReceiverDashboardController controller =
        Get.find<ReceiverDashboardController>();

  return Obx(() {
    final connected = controller.isDeviceConnected.value;
    final battery = controller.batteryLevel.value;

    Color batteryColor;
    if (battery >= 60) {
      batteryColor = Colors.green;
    } else if (battery >= 30) {
      batteryColor = Colors.orange;
    } else {
      batteryColor = Colors.red;
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: Get.width * 0.05),
      child: Row(
        children: [
          // -------- Device Status --------
          Expanded(
            child: Row(
              children: [
                Container(
                  height: 32,
                  width: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: connected
                        ? Colors.teal.shade100
                        : Colors.red.shade100,
                  ),
                  child: Icon(
                    connected
                        ? Icons.watch_rounded
                        : Icons.watch_off_rounded,
                    color: connected
                        ? Colors.teal.shade700
                        : Colors.red.shade700,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    connected
                        ? "Device Connected"
                        : "Device Offline",
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.nunito(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 10),

          // -------- Battery --------
          Row(
            children: [
              Row(
                children: [
                  Icon(
                    controller.isCharging.value
                        ? Icons.battery_charging_full
                        : Icons.battery_full,
                    size: 20,
                    color: batteryColor,
                  ),

                ],
              ),

              const SizedBox(width: 4),
              Text(
                "$battery%",
                style: GoogleFonts.nunito(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
            ],
          ),

          const SizedBox(width: 8),

          // -------- Refresh Button --------
          SizedBox(
            height: 32,
            child: OutlinedButton(
              onPressed: () async {
                await controller.syncDeviceStatus();
                await controller.refreshDeviceConnectionStatus();
              },
              style: OutlinedButton.styleFrom(
                side: BorderSide(color:Colors.blue.shade300, width: 1),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: Text(
                "Refresh",
                style: GoogleFonts.nunito(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.blue.shade700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  });
  }
}
