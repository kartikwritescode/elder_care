
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';

class PoliciesScreen extends StatelessWidget {
  const PoliciesScreen({super.key});

  static const double headingSize = 18;

  @override
  Widget build(BuildContext context) {
    final w = Get.width;
    final h = Get.height;
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    return Scaffold(
      appBar: AppBar(
        title: Text('Policies', style: GoogleFonts.nunito(fontWeight: FontWeight.w800)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black87,
        leading: IconButton(onPressed: () => Get.back(), icon: Icon(Icons.arrow_back)),
      ),
      body: Container(
        padding: EdgeInsets.symmetric(horizontal: w * 0.06, vertical: h * 0.02),
        child: SingleChildScrollView(
          child: Column(
            children: [
              _policyCard(
                title: 'Privacy Policy',
                summary:
                'We collect and process the minimal data necessary to provide and improve ElderCare.',
                content: _privacyPolicyText(),
                w: w,
                h: h,
              ),
              SizedBox(height: h * 0.02),
              _policyCard(
                title: 'Terms & Conditions',
                summary: 'Rules for using the app and our services.',
                content: _termsText(),
                w: w,
                h: h,
              ),
              SizedBox(height: h * 0.02),
              _policyCard(
                title: 'Data Handling & Security',
                summary: 'How we store, handle and protect your data.',
                content: _dataHandlingText(),
                w: w,
                h: h,
              ),
              SizedBox(height: h * 0.03),
              Text(
                'If you have any questions about these policies, contact us at work.kartikkumar@gmail.com',
                style: GoogleFonts.nunito(fontSize: w * 0.034, color: Colors.black54),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: h * 0.04),
            ],
          ),
        ),
      ),
    );
  }

  Widget _policyCard({
    required String title,
    required String summary,
    required String content,
    required double w,
    required double h,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(w * 0.04)),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: w * 0.04, vertical: h * 0.02),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: GoogleFonts.nunito(fontSize: w * 0.044, fontWeight: FontWeight.w900)),
          SizedBox(height: h * 0.01),
          Text(summary, style: GoogleFonts.nunito(fontSize: w * 0.036, color: Colors.black54)),
          SizedBox(height: h * 0.01),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => _openFullPolicy(title, content),
              child: Text('Read full policy', style: GoogleFonts.nunito(fontWeight: FontWeight.w800)),
            ),
          )
        ]),
      ),
    );
  }

  void _openFullPolicy(String title, String content) {
    Get.to(() => FullPolicyPage(title: title, content: content));
  }

  String _privacyPolicyText() {
    return '''
Privacy Policy (Summary)

1. Data we collect:
 - Account identifiers (email, display name)
 - Profile details (avatar, bio)
 - Connections data (linked caregivers / care receivers)
 - Optional device diagnostic data for bug resolution

2. How we use data:
 - Provide and improve app functionality (linking, notifications, reminders)
 - Communicate about account activity and updates
 - Investigate and troubleshoot issues

3. Data sharing:
 - We do not sell personal data.
 - We may use third-party services (hosting, analytics) — those services are contractually limited to necessary processing only.

4. User controls:
 - You may request deletion of your account and personal data by contacting support.
 - You can manage profile and notification settings in the app.

(Replace this summary with your complete legal privacy policy before publishing.)
''';
  }

  String _termsText() {
    return '''
Terms & Conditions (Summary)

1. Acceptance:
 By using ElderCare you agree to these Terms.

2. Use:
 The app is provided for personal caregiving coordination purposes. Do not use it for unlawful activities.

3. Accounts:
 You are responsible for maintaining the confidentiality of your account and password.

4. Liability:
 ElderCare provides tools and information; it is not a substitute for professional medical advice. For emergencies contact local services immediately.

(Replace with full legal terms before publishing.)
''';
  }

  String _dataHandlingText() {
    return '''
Data Handling & Security (Summary)

1. Storage & retention:
 - User data is stored on secured backend systems. Retention periods are limited to what is necessary for the service.

2. Encryption:
 - Data in transit is encrypted via TLS. Sensitive fields are stored securely.

3. Backups:
 - Regular backups are performed; access is restricted.

4. Incident response:
 - In case of a security incident, affected users will be notified per applicable laws.

(Provide implementation details and contact info for a production release.)
''';
  }
}

class FullPolicyPage extends StatelessWidget {
  final String title;
  final String content;
  const FullPolicyPage({super.key, required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    final w = Get.width;
    final h = Get.height;
    return Scaffold(
      appBar: AppBar(
        title: Text(title, style: GoogleFonts.nunito(fontWeight: FontWeight.w800)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black87,
        leading: IconButton(onPressed: () => Get.back(), icon: Icon(Icons.arrow_back)),
      ),
      body: Container(
        padding: EdgeInsets.symmetric(horizontal: w * 0.06, vertical: h * 0.02),
        child: SingleChildScrollView(
          child: Text(content, style: GoogleFonts.nunito(fontSize: w * 0.036, height: 1.5)),
        ),
      ),
    );
  }
}
