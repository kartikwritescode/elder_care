import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';

import '../controllers/carereceiver_dashboard_controller.dart';

class MoodDialog {
  static void show(BuildContext context) {
    final controller = Get.find<ReceiverDashboardController>();
    final w = Get.width;
    final h = Get.height;



    Get.dialog(
      Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: w * 0.8,
            padding: EdgeInsets.symmetric(
              horizontal: w * 0.055,
              vertical: h * 0.028,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(26),
              color: const Color(0xFFF9FCFB),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.14),
                  blurRadius: 26,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                /// LOTTIE SPACE (KEPT)
                ClipRect(
                  child: SizedBox(
                    height: h*0.15,
                    width: w*0.5,
                    child: Transform.scale(
                      scale: 1,
                      child: Lottie.asset(
                        'assets/lottie/Happy_Dog.json',
                        repeat: true,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),


                Text(
                  "Just checking in with you",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.nunito(
                    fontSize: w * 0.048,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF2F5D58),
                  ),
                ),

                SizedBox(height: h * 0.006),

                /// SUBTITLE
                Text(
                  "How are you feeling right now?",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.nunito(
                    fontSize: w * 0.034,
                    color: Colors.black54,
                  ),
                ),

                SizedBox(height: h * 0.028),

                /// MOOD EMOJIS
                Obx(
                      () => Wrap(
                    alignment: WrapAlignment.center,
                    spacing: w * 0.032,
                    runSpacing: h * 0.02,
                    children: controller.moodOptions.map((mood) {
                      final key = mood['key']!;
                      final emoji = mood['emoji']!;
                      final isSelected = controller.selectedMood.value == key;

                      return GestureDetector(
                        onTap: () => controller.submitMood(key),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeOutBack,
                          padding: EdgeInsets.all(w * 0.04),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected ? Color(0xFFE6F3EF) : Colors.white,

                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(isSelected ? 0.18 : 0.1),
                                blurRadius: 12,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: AnimatedScale(
                            scale: isSelected ? 1.1 : 1.0,
                            duration: const Duration(milliseconds: 180),
                            curve: Curves.easeOutBack,
                            child: Text(
                              emoji,
                              style: TextStyle(fontSize: w * 0.088),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),


                SizedBox(height: h * 0.026),

                /// FOOTNOTE
                FittedBox(
                  child: Text(
                    "This helps your caregiver understand you better",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.nunito(
                      fontSize: w * 0.03,
                      color: Colors.black45,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      barrierDismissible: true,
    );
  }
}
