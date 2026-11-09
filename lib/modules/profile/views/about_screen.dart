// lib/presentation/screens/help_support/about_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  static const String aboutText = '''
ElderCare is designed to make caregiving simpler, safer, and more connected for families and caregivers.
The app provides:
 - Easy caregiver / care-receiver linking
 - Task & reminder management
 - Location assistance for safety and check-ins
 - Secure profile and connection management
 - Emergency procedures (SOS) and quick contact options

Developer: Kartik Kumar
Email: work.kartikkumar@gmail.com

''';

  @override
  Widget build(BuildContext context) {
    final w = Get.width;
    final h = Get.height;
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    return Scaffold(
      appBar: AppBar(
        title: Text('About ElderCare', style: GoogleFonts.nunito(fontWeight: FontWeight.w800)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black87,
        leading: IconButton(onPressed: () => Get.back(), icon: Icon(Icons.arrow_back)),
      ),
      body: Container(
        padding: EdgeInsets.symmetric(horizontal: w * 0.06, vertical: h * 0.02),
        child: Column(
          children: [
            Image.asset('assets/images/eldercare_logo.png', height: h * 0.12),
            SizedBox(height: h * 0.02),
            Text('ElderCare', style: GoogleFonts.nunito(fontSize: w * 0.06, fontWeight: FontWeight.w900)),
            SizedBox(height: h * 0.02),
            Text(aboutText, style: GoogleFonts.nunito(fontSize: w * 0.036, height: 1.5)),
            Spacer(),
            Text('Contact: work.kartikkumar@gmail.com', style: GoogleFonts.nunito(color: Colors.black54)),
            SizedBox(height: h * 0.02),
          ],
        ),
      ),
    );
  }
}
