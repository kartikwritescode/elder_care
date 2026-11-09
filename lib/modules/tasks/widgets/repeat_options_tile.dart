import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../controllers/task_controller.dart';
import 'day_chips.dart';

class RepeatOptions extends StatelessWidget {
  final TaskController controller;
  const RepeatOptions({super.key, required this.controller});

  static const Color kTeal = Color(0xFF7AB7A7);

  @override
  Widget build(BuildContext context) {
    return Obx(() => Column(
      key: const ValueKey('repeat-options'),
      children: [
        const SizedBox(height: 8),

        RepeatCard(
          label: 'Tomorrow',
          selected: controller.repeatType.value == 'tomorrow',
          onTap: () {
            controller.repeatType.value = 'tomorrow';
            controller.repeatDays.clear();
          },
        ),

        RepeatCard(
          label: 'Daily',
          selected: controller.repeatType.value == 'daily',
          onTap: () {
            controller.repeatType.value = 'daily';
            controller.repeatDays.clear();
          },
        ),

        RepeatCard(
          label: 'Custom',
          selected: controller.repeatType.value == 'custom',
          onTap: () {
            controller.repeatType.value = 'custom';
          },
        ),

        if (controller.repeatType.value == 'custom') ...[
          const SizedBox(height: 10),
          CustomDayChips(controller: controller),
        ],
      ],
    ));
  }
}

class RepeatCard extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const RepeatCard({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  static const Color kTeal = Color(0xFF7AB7A7);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? kTeal.withValues(alpha: 0.12) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? kTeal : Colors.transparent,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Text(
              label,
              style: GoogleFonts.nunito(
                fontWeight: FontWeight.w700,
                color: selected ? kTeal : Colors.black87,
              ),
            ),
            const Spacer(),
            if (selected)
              const Icon(Icons.check_circle, size: 18, color: kTeal),
          ],
        ),
      ),
    );
  }
}
