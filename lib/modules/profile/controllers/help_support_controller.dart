// lib/presentation/screens/help_support/faq_item.dart
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';

class FAQItem {
  final String id;
  final String question;
  final String shortAnswer;
  final String longAnswer;

  FAQItem({
    required this.id,
    required this.question,
    required this.shortAnswer,
    required this.longAnswer,
  });
}


class HelpSupportController extends GetxController {
  final RxList<FAQItem> faqs = <FAQItem>[].obs;
  final RxString appVersion = ''.obs;

  @override
  void onInit() {
    super.onInit();
    _loadFaqs();
    _loadPackageInfo();
  }

  void _loadFaqs() {
    // Populate the FAQ list. Expand or modify contents as needed.
    faqs.assignAll([
      FAQItem(
        id: 'create_account',
        question: 'How do I create an account?',
        shortAnswer: 'Open Sign Up, enter your details and verify your email.',
        longAnswer:
        'To create an account in ElderCare:\n\n'
            '1. From the Login screen tap "Sign Up".\n'
            '2. Fill in your name, a valid email, and a strong password.\n'
            '3. Agree to the Terms & Policies and submit.\n'
            '4. Check your email for a verification link (if enabled) and verify your address.\n\n'
            'If you don’t receive an email, check your spam folder or tap "Resend verification" from the login screen.',
      ),
      FAQItem(
        id: 'link_users',
        question: 'How do I link a caregiver / care receiver?',
        shortAnswer:
        'From Profile → Manage Connections → Enter Care ID and send request.',
        longAnswer:
        'Steps to link:\n\n'
            '1. Open Profile and select "Manage Connections".\n'
            '2. Tap "Link new person" and enter their Care ID.\n'
            '3. Send the link request — the other user must approve it.\n'
            '4. Once approved, you will see the linked user under "Connections".\n\n'
            'Troubleshooting: Ensure both users are on a stable internet connection, using the latest app version, and that the Care ID is entered exactly.',
      ),
      FAQItem(
        id: 'notifications',
        question: 'Notifications are not arriving — what do I do?',
        shortAnswer: 'Check notification permissions and battery settings.',
        longAnswer:
        'Fix steps:\n\n'
            '1. Open your device Settings → Apps → ElderCare → Notifications and enable notifications.\n'
            '2. Disable battery optimization for ElderCare (so background services are not killed).\n'
            '3. Ensure the user/device is not in DND mode.\n'
            '4. In-app: open Profile → Settings → Notifications and verify toggles.\n'
            '5. If still not working, reinstall the app and contact Support with device details.',
      ),
      FAQItem(
        id: 'location',
        question: 'Why is location not updating?',
        shortAnswer: 'Allow location permission and keep GPS enabled.',
        longAnswer:
        'Location troubleshooting:\n\n'
            '1. Ensure device Location/GPS is turned on.\n'
            '2. Grant ElderCare “Always allow” location permission if the feature requires background tracking.\n'
            '3. Check network (Wi-Fi/cellular) and that location services are not restricted by device settings.\n'
            '4. Restart the app. If persistent, contact Support with details (device model, Android/iOS version).',
      ),
      FAQItem(
        id: 'data_privacy',
        question: 'How is my personal data protected?',
        shortAnswer: 'We follow standard encryption and data minimisation practices.',
        longAnswer:
        'ElderCare takes data privacy seriously. Summary:\n\n'
            '- We store minimal personal data required to operate the service (email, profile name, connections).\n'
            '- Data in transit is encrypted using HTTPS/TLS.\n'
            '- Access to personal data is limited to authorized systems and admins.\n'
            '- You can request data deletion via Support.\n\n'
            'Full details are available in the Privacy Policy under Policies.',
      ),
      // Add more FAQs here if you want...
    ]);
  }

  Future<void> _loadPackageInfo() async {
    try {
      final info = await PackageInfo.fromPlatform();
      appVersion.value = info.version.isNotEmpty ? '${info.version}+${info.buildNumber}' : '1.0.0';
    } catch (_) {
      appVersion.value = '1.0.0';
    }
  }
}
