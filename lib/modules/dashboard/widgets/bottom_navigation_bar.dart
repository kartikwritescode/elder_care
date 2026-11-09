import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/nav_controller.dart';

class CareGiverBottomNavBar extends StatelessWidget {
  CareGiverBottomNavBar({super.key});

  final NavController nav = Get.find<NavController>();

  @override
  Widget build(BuildContext context) {
    final rawInset = MediaQuery.of(context).viewPadding.bottom;
    final bottomInset = rawInset > 24 ? rawInset : 0;

    return Obx(() {
      return Container(
        height: Get.height * 0.11 + bottomInset,
        padding: EdgeInsets.fromLTRB(
          26,
          12,
          26,
          12 + bottomInset.toDouble(),
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(28),
            topRight: Radius.circular(28),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.07),
              blurRadius: 18,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _navItem(Icons.home_outlined, "Home", 0),
            _navItem(Icons.chat_bubble_outline, "Chat", 1),
            _navItem(Icons.location_on_outlined, "Location", 2),
            _navItem(Icons.person_outline, "Profile", 3),
          ],
        ),
      );
    });
  }

  Widget _navItem(IconData icon, String label, int index) {
    final isSelected = nav.selectedIndex.value == index;

    return GestureDetector(
      onTap: () => nav.selectedIndex.value = index,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 22 : 16,
          vertical: isSelected ? 14 : 10,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFE8EDFF)
              : const Color(0xFFF2F3F7),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: isSelected ? 28 : 24,
              color: isSelected ? const Color(0xFF1E2A78) : Colors.black54,
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E2A78),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}


class CareReceiverBottomNavBar extends StatelessWidget {
  CareReceiverBottomNavBar({super.key});

  final NavController nav = Get.find<NavController>();

  @override
  Widget build(BuildContext context) {
    final rawInset = MediaQuery.of(context).viewPadding.bottom;
    final bottomInset = rawInset > 24 ? rawInset : 0;

    return Obx(() {
      return Container(
        height: Get.height * 0.11 + bottomInset,
        padding: EdgeInsets.fromLTRB(
          26,
          12,
          26,
          12 + bottomInset.toDouble(),
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(28),
            topRight: Radius.circular(28),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.07),
              blurRadius: 18,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _navItem(Icons.home_outlined, "Home", 0),
            _navItem(Icons.chat_bubble_outline, "Chat", 1),
            _navItem(Icons.calendar_month, "Schedule", 2),
            _navItem(Icons.person_outline, "Profile", 3),
          ],
        ),
      );
    });
  }

  Widget _navItem(IconData icon, String label, int index) {
    final isSelected = nav.selectedIndex.value == index;

    return GestureDetector(
      onTap: () => nav.selectedIndex.value = index,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 22 : 16,
          vertical: isSelected ? 14 : 10,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFE8EDFF)
              : const Color(0xFFF2F3F7),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: isSelected ? 28 : 24,
              color: isSelected ? const Color(0xFF1E2A78) : Colors.black54,
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E2A78),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}