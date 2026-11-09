import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/cache_service.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../auth/views/login_screen.dart';

class SplashController extends GetxController {
  final supabase = Supabase.instance.client;
  final AuthController authController = Get.find<AuthController>();

  @override
  void onReady() {
    super.onReady();
    _initApp();
  }

  Future<void> _initApp() async {
    await Future.delayed(const Duration(seconds: 2)); // Show logo nicely

    try {
      debugPrint("[SPLASH] Checking saved session...");
      final session = supabase.auth.currentSession;

      if (session == null) {
        debugPrint("[SPLASH] No session found → go to Login");
        return Get.offAll(() => LoginScreen());
      }

      debugPrint("[SPLASH] Session found for user ${session.user.id}. Validating session…");

      bool isOfflineOrNetworkError = false;
      try {
        await supabase.auth.refreshSession();
      } catch (refreshErr) {
        debugPrint("[SPLASH] Session refresh warning (likely offline): $refreshErr");
        isOfflineOrNetworkError = true;
      }

      // Check if user has cached profile
      final cachedProfile = CacheService.instance.get(
        CacheService.userKey(session.user.id, 'profile'),
      );

      // If refresh succeeded OR we have a valid cached session/profile (offline launch):
      if (!isOfflineOrNetworkError || cachedProfile != null) {
        await authController.fetchRoleAndNavigate(session.user.id);
      } else {
        // Corrupted session with no cached profile
        try {
          await supabase.auth.signOut();
        } catch (_) {}
        Get.offAll(() => LoginScreen());
      }
    } catch (e) {
      debugPrint("[SPLASH] Fatal init error: $e");
      Get.offAll(() => LoginScreen());
    }
  }
}

