import 'package:get/get.dart';

class NavController extends GetxController {
  // -----------------------------
  // BOTTOM NAV
  // -----------------------------
  final selectedIndex = 0.obs;

  void changeTab(int index) {
    selectedIndex.value = index;
  }

  // -----------------------------
  // CARE RECEIVER STATE
  // -----------------------------
  final linkedReceiverId = "".obs;
  final isLoading = true.obs;

  /// Call this when receiver is resolved
  void setReceiver(String receiverId) {
    linkedReceiverId.value = receiverId;
    isLoading.value = false;
  }

  /// Call this when caregiver has no receiver
  void clearReceiver() {
    linkedReceiverId.value = "";
    isLoading.value = false;
  }

  /// Optional: when reloading receiver
  void startLoading() {
    isLoading.value = true;
  }

  /// Reset navigation state back to default
  void reset() {
    selectedIndex.value = 0;
    linkedReceiverId.value = "";
    isLoading.value = true;
  }
}
