import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/task_controller.dart';

const Color kTeal = Color(0xFF7AB7A7);
class CustomDayChips extends StatelessWidget {
  final TaskController controller;
  const CustomDayChips({super.key, required this.controller});

  static const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  static const Color kTeal = Color(0xFF7AB7A7);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, constraints) {
        final chipWidth = (constraints.maxWidth - 24) / 4;

        return Obx(() => Wrap(
          spacing: 8,
          runSpacing: 8,
          children: days.map((d) {
            final selected = controller.repeatDays.contains(d);
            return SizedBox(
              width: chipWidth,
              child: GestureDetector(
                onTap: () {
                  if (selected) {
                    controller.repeatDays.remove(d);
                  } else {
                    controller.repeatDays.add(d);
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected ? kTeal.withValues(alpha: 0.15) : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: selected ? kTeal : Colors.transparent,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    d,
                    style: GoogleFonts.nunito(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: selected ? kTeal : Colors.black87,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ));
      },
    );
  }
}
