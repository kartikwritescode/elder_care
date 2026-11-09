import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/models/task_model.dart';

class TaskTile extends StatelessWidget {
  final TaskModel task;
  final VoidCallback onDone;

  const TaskTile({
    required this.task,
    required this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    final isMedicine = task.taskType == 'medicine';

    return Material(
      color: Colors.transparent,
      child: Container(
        height: Get.height*0.1,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: isMedicine
              ? const Color(0xFFF3F6F7) // might change later
              : const Color(0xFFF3F6F7),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isMedicine
                ? const Color(0xFFE1E6E8)
                : const Color(0xFFE1E6E8),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [

            // LEFT ICON
            Image.asset(
              'assets/images/task3.png',
              width: Get.width * 0.1,
              height: Get.width * 0.12,
              fit: BoxFit.contain,
            ),



            const SizedBox(width: 14),

            // TEXT
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.nunito(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (task.datetime != null)
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            _friendlyDate(task.datetime!),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.nunito(
                              fontSize: 13,
                              color: Colors.black54,
                            ),
                          ),
                        ),

                        if (task.alarmEnabled) ...[
                          const SizedBox(width: 6),
                          const Icon(Icons.alarm, size: 16, color: Colors.black54),
                        ],

                        if (task.taskType == 'medicine') ...[
                          const SizedBox(width: 6),
                          Image.asset(
                            'assets/images/pill.png',
                            width: 16,
                            height: 16,
                            fit: BoxFit.contain,
                            color: Colors.black54,
                          ),
                        ],


                        if (task.repeatType != 'none') ...[
                          const SizedBox(width: 6),
                          const Icon(Icons.repeat, size: 16, color: Colors.black54),
                        ],
                      ],
                    ),

                ],
              ),
            ),

            // Task completed button right
            GestureDetector(
              onTap: onDone,
              child: Container(
                height: 42,
                width: 42,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Icon(
                  isMedicine ? Icons.task_alt_rounded : Icons.task_alt_rounded,
                  color: isMedicine ? Colors.black87 : Colors.black87,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }


}



String _friendlyDate(String iso) {
  try {
    final d = DateTime.parse(iso).toLocal();

    final hour12 = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final minute = d.minute.toString().padLeft(2, '0');
    final period = d.hour >= 12 ? 'PM' : 'AM';

    return '${d.day}/${d.month}/${d.year} • $hour12:$minute $period';
  } catch (_) {
    return iso;
  }
}

