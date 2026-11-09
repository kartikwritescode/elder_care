import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import '../../../app/utils/mail_utils.dart';
import '../controllers/help_support_controller.dart';
import 'about_screen.dart';
import 'policies_screen.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  HelpSupportController get controller => Get.isRegistered<HelpSupportController>()
      ? Get.find<HelpSupportController>()
      : Get.put(HelpSupportController());
  static const String supportEmail = 'work.kartikkumar@gmail.com';

  @override
  Widget build(BuildContext context) {
    final h = Get.height;
    final w = Get.width;

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
    ));

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Help & Support',
            style: GoogleFonts.nunito(
              color: Colors.black87,
              fontWeight: FontWeight.w800,
            )),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Container(
        height: h,
        width: w,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/auth/login_bg.png"),
            fit: BoxFit.cover,
            opacity: 0.08,
          ),
          gradient: LinearGradient(
            colors: [Color(0xFFeaf4f2), Color(0xFFfdfaf6)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        padding: EdgeInsets.symmetric(horizontal: w * 0.06, vertical: h * 0.02),
        child: Column(
          children: [
            SizedBox(height: h * 0.02),
            Expanded(child: _buildMainContent(context, h, w)),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent(BuildContext context, double h, double w) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // header
          SizedBox(height: h * 0.06,),
          Card(
            elevation: 8,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(w * 0.05)),
            child: Padding(
              padding: EdgeInsets.symmetric(
                  vertical: h * 0.028, horizontal: w * 0.05),
              child: Row(
                children: [
                  Image.asset(
                      'assets/images/eldercare_logo.png', height: h * 0.07),
                  SizedBox(width: w * 0.04),
                  Expanded(
                    child: Text(
                      'Need help? Find answers below or contact support.',
                      style: GoogleFonts.nunito(
                        fontSize: w * 0.038,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: h * 0.02),

          // FAQs heading
          Align(
            alignment: Alignment.centerLeft,
            child: Text('Frequently Asked Questions',
                style: GoogleFonts.nunito(
                    fontSize: w * 0.046, fontWeight: FontWeight.w800)),
          ),
          SizedBox(height: h * 0.01),

          // FAQ list (tap → opens bottom sheet)
          Obx(
                () =>
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(w * 0.04)),
                  child: Column(
                    children: controller.faqs.map((f) =>
                        _faqTile(context, f, w, h)).toList(),
                  ),
                ),
          ),

          SizedBox(height: h * 0.03),

          // Contact/Report/Policies/About list tiles
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(w * 0.04)),
            child: Column(
              children: [
                ListTile(
                  leading: Icon(
                      Icons.email_outlined, color: Colors.teal.shade400),
                  title: Text('Contact Support',
                      style: GoogleFonts.nunito(fontWeight: FontWeight.w800)),
                  subtitle: Text(supportEmail, style: GoogleFonts.nunito()),
                  onTap: () =>
                      MailUtils.openEmail(
                        toEmail: supportEmail,
                        subject: 'ElderCare Support Request',
                        body:
                        'Hello ElderCare team,\n\nI need help with:\n\n(Device / OS (Android/iOS):\nApp version:\nSteps to reproduce:\n\nThanks,\n',
                      ),
                ),
                Divider(height: 1),
                ListTile(
                  leading: Icon(
                      Icons.bug_report_outlined, color: Colors.orange),
                  title: Text('Report a Problem',
                      style: GoogleFonts.nunito(fontWeight: FontWeight.w800)),
                  subtitle: Text('Send details and steps to reproduce',
                      style: GoogleFonts.nunito()),
                  onTap: () =>
                      MailUtils.openEmail(
                        toEmail: supportEmail,
                        subject: 'ElderCare: Problem Report',
                        body:
                        'Hello ElderCare team,\n\nI want to report a problem:\n\nSteps to reproduce:\n1.\n2.\n\nExpected behaviour:\n\nActual behaviour:\n\nDevice & app version:\n\nAdditional notes:\n',
                      ),
                ),
                Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.policy_outlined, color: Colors.blueGrey),
                  title: Text('Policies',
                      style: GoogleFonts.nunito(fontWeight: FontWeight.w800)),
                  subtitle: Text('Privacy Policy, Terms & Data Handling',
                      style: GoogleFonts.nunito()),
                  onTap: () => Get.to(() => PoliciesScreen()),
                ),
                Divider(height: 1),
                ListTile(
                  leading: Icon(
                      Icons.info_outline, color: Colors.teal.shade700),
                  title: Text('About ElderCare',
                      style: GoogleFonts.nunito(fontWeight: FontWeight.w800)),
                  subtitle: Text('App & developer information',
                      style: GoogleFonts.nunito()),
                  onTap: () => Get.to(() => AboutScreen()),
                ),
              ],
            ),
          ),

          SizedBox(height: h * 0.03),

          // Feedback button
          ElevatedButton.icon(
            onPressed: () =>
                MailUtils.openEmail(
                  toEmail: supportEmail,
                  subject: 'ElderCare: Feedback',
                  body: 'Hello, I would like to share feedback:\n\n',
                ),
            icon: Icon(Icons.message,color: Colors.white,size: w*0.06,),
            label: Text('Send Feedback',
                style: GoogleFonts.nunito(fontWeight: FontWeight.w800,color: Colors.white,fontSize: w*0.045)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7AB7A7),
              minimumSize: Size(double.infinity, h * 0.065),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
          SizedBox(height: h * 0.015),
          Text(
            // 'Version ${controller.appVersion.value}',
            'Version 2.0.1',
            style: GoogleFonts.nunito(
                color: Colors.black54, fontSize: Get.height * 0.015),
          ),



          SizedBox(height: h * 0.02),
        ],
      ),
    );
  }

  Widget _faqTile(BuildContext context, FAQItem faq, double w, double h) {
    return InkWell(
      onTap: () => _openFaqBottomSheet(context, faq),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: w * 0.04),
        child: Column(
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(faq.question,
                  style: GoogleFonts.nunito(
                      fontSize: w * 0.04, fontWeight: FontWeight.w800)),
              subtitle: Padding(
                padding: EdgeInsets.only(top: 6.0),
                child: Text(faq.shortAnswer,
                    style: GoogleFonts.nunito(fontSize: w * 0.034)),
              ),
              trailing: Icon(
                  Icons.keyboard_arrow_up_outlined, color: Colors.black45),
            ),
            Divider(height: 1),

          ],
        ),
      ),
    );
  }

  void _openFaqBottomSheet(BuildContext context, FAQItem faq) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: false,   // IMPORTANT → lets content decide height
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(color: Colors.black26, blurRadius: 12),
            ],
          ),

          // 🔥 THIS makes the sheet height = content height
          child: Column(
            mainAxisSize: MainAxisSize.min,     // SUPER IMPORTANT
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 48,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              SizedBox(height: 12),

              Text(
                faq.question,
                style: GoogleFonts.nunito(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),

              SizedBox(height: 8),

              Text(
                faq.longAnswer,
                style: GoogleFonts.nunito(
                  fontSize: 15,
                  height: 1.5,
                ),
              ),

              SizedBox(height: 20),

              Row(
                // mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => MailUtils.openEmail(
                      toEmail: 'work.kartikkumar@gmail.com',
                      subject: 'Support: ${faq.id}',
                      body: 'I have a question about: ${faq.question}\n\nDetails:\n',
                    ),
                    icon: Icon(Icons.email_outlined,color: Colors.white,),
                    label: Text('Contact Support',style: TextStyle(color: Colors.white),),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7AB7A7),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  // SizedBox(width:Get.width*0.1 ),
                  // OutlinedButton.icon(
                  //   onPressed: () => Get.back(),
                  //   icon: Icon(Icons.close,color: Colors.black,),
                  //   label: Text('Close',style: TextStyle(color: Colors.black),),
                  // ),
                ],
              ),



              SizedBox(height: Get.height*0.03),
            ],
          ),
        );
      },
    );
  }


}