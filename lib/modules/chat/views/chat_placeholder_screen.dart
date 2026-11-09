import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class ChatPlaceholderScreen extends StatelessWidget {
  const ChatPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final h = Get.height;
    final w = Get.width;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        centerTitle: true,
        title: Text(
          'Chat',
          style: GoogleFonts.nunito(
            color: Colors.black87,
            fontWeight: FontWeight.w800,
          ),
        ),
        // leading: IconButton(
        //   icon: const Icon(Icons.arrow_back, color: Colors.black87),
        //   onPressed: () => Get.back(),
        // ),
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        height: h,
        width: w,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFeaf4f2), Color(0xFFfdfaf6)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: w * 0.12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon bubble
                Container(
                  height: 96,
                  width: 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.teal.withValues(alpha: 0.12),
                  ),
                  child: const Icon(
                    Icons.chat_bubble_outline_rounded,
                    size: 42,
                    color: Colors.teal,
                  ),
                ),

                SizedBox(height: h * 0.035),

                Text(
                  "Chat is coming soon",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.nunito(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.black87,
                  ),
                ),

                SizedBox(height: h * 0.015),

                Text(
                  "We’re working on secure real-time chat so caregivers and receivers can stay connected effortlessly.",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.nunito(
                    fontSize: 15,
                    height: 1.5,
                    color: Colors.black54,
                  ),
                ),

                SizedBox(height: h * 0.04),

                // Disabled CTA (intentional)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Text(
                    "Feature under development",
                    style: GoogleFonts.nunito(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
