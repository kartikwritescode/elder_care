import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/models/task_model.dart';
import '../controllers/task_controller.dart';
import 'add_edit_dialog.dart';

class TaskDetailsDialog extends StatelessWidget {
  final TaskModel task;
  final TaskController controller;

  const TaskDetailsDialog({
    super.key,
    required this.task,
    required this.controller,
  });

  static const Color kTeal = Color(0xFF7AB7A7);

  @override
  Widget build(BuildContext context) {
    DateTime? dt;
    try {
      if (task.datetime != null) {
        dt = DateTime.parse(task.datetime!).toLocal();
      }
    } catch (_) {}

    final isMedicine = task.taskType == 'medicine';

    return Material(
      color: Colors.transparent,
      child: Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(26),
        ),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.75,
            ),
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F6F7),
                borderRadius: BorderRadius.circular(26),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  /// HEADER
                  Row(
                    children: [
                      Image.asset(
                        'assets/images/task3.png',
                        width: 36,
                        height: 36,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Task Details',
                        style: GoogleFonts.nunito(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  /// TITLE
                  Text(
                    task.title,
                    style: GoogleFonts.nunito(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),

                  if (dt != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      _friendlyDate(dt),
                      style: GoogleFonts.nunito(
                        fontSize: 13,
                        color: Colors.black54,
                      ),
                    ),
                  ],

                  const SizedBox(height: 14),

                  /// META CHIPS
                  Wrap(
                    spacing: 10,
                    runSpacing: 8,
                    children: [
                      if (task.alarmEnabled)
                        _metaChip(
                          icon: Icons.alarm,
                          label: 'Reminder',
                        ),

                      if (isMedicine)
                        _metaChip(
                          image: 'assets/images/pill.png',
                          label: 'Medicine',
                        ),

                      if (task.repeatType != 'none')
                        _metaChip(
                          icon: Icons.repeat,
                          label: 'Repeat',
                        ),
                    ],
                  ),

                  const SizedBox(height: 22),

                  /// ACTIONS
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            controller.startEdit(task);
                            Navigator.pop(context);
                            Future.delayed(const Duration(milliseconds: 100), () {
                              Get.dialog(
                                AddEditTaskDialog(
                                  isEdit: true,
                                  controller: controller,
                                ),
                              );
                            });
                          },

                          style: ElevatedButton.styleFrom(
                            backgroundColor: kTeal,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            'Edit',
                            style: GoogleFonts.nunito(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            controller.deleteTaskConfirmed(task);
                            Get.back();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            'Delete',
                            style: GoogleFonts.nunito(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _metaChip({
    IconData? icon,
    String? image,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE1E6E8)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null)
            Icon(icon, size: 16, color: Colors.black54),
          if (image != null)
            Image.asset(
              image,
              width: 16,
              height: 16,
              color: Colors.black54,
            ),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.nunito(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  String _friendlyDate(DateTime d) {
    final hour12 = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final minute = d.minute.toString().padLeft(2, '0');
    final period = d.hour >= 12 ? 'PM' : 'AM';

    return '${d.day}/${d.month}/${d.year} • $hour12:$minute $period';
  }

  void openCustomDialog(BuildContext context, Widget dialog) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black.withValues(alpha: 0.25),
        transitionDuration: const Duration(milliseconds: 250),
        pageBuilder: (_, __, ___) => dialog,
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween(begin: 0.96, end: 1.0).animate(
                CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                ),
              ),
              child: child,
            ),
          );
        },
      ),
    );
  }
}
