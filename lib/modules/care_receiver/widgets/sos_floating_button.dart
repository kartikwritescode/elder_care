import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../controllers/carereceiver_dashboard_controller.dart';

class SOSFab extends StatelessWidget {
  final ReceiverDashboardController controller;
  const SOSFab(this.controller, {super.key});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      heroTag: 'sos_fab',
      backgroundColor: Colors.red,
      elevation: 8,
      onPressed: () {
        _confirmSOS(context);
      },
      icon: const Icon(
        Icons.warning_amber_rounded,
        color: Colors.white,
        size: 26,
      ),
      label: Text(
        "SOS",
        style: GoogleFonts.nunito(
          fontSize: 16,
          fontWeight: FontWeight.w900,
          color: Colors.white,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  /// Optional safety confirmation (recommended)
  void _confirmSOS(BuildContext context) {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
        ),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFeaf4f2), Colors.white],
            ),
            borderRadius: BorderRadius.all(Radius.circular(22)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.warning_amber_rounded,
                  size: 46, color: Colors.red.shade600),
              const SizedBox(height: 12),
              Text(
                "Emergency SOS",
                style: GoogleFonts.nunito(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "This will immediately notify your caregiver with your location.",
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(color: Colors.black54),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text("Cancel",
                          style: GoogleFonts.nunito(color: Colors.grey)),
                    ),
                  ),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.of(context).pop(); // safely close dialog
                        await Future.delayed(const Duration(milliseconds: 200));
                        controller.sendSOS();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade600,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        "SEND SOS",
                        style: GoogleFonts.nunito(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
      barrierDismissible: true,
    );
  }
}
