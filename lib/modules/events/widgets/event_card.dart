import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/models/event_model.dart';
import '../controllers/events_controller.dart';
import 'event_details_dialog.dart';

const Color kTeal = Color(0xFF7AB7A7);

class EventCardCompact extends StatelessWidget {
  final EventModel event;
  const EventCardCompact({super.key, required this.event});

  String _friendlyDate(DateTime dateTime) {
    final d = dateTime.toLocal();

    return '${d.day}/${d.month}/${d.year} • '
        '${d.hour.toString().padLeft(2, '0')}:'
        '${d.minute.toString().padLeft(2, '0')}';
  }
  Widget _iconForCategory(String c, double size) {
    switch (c) {
      case 'Medication':
        return Image.asset(
          'assets/images/pill.png',
          width: size,
          height: size,
          fit: BoxFit.contain,
          color: Colors.white,
        );

      case 'Appointment':
        return Icon(Icons.medical_services, color: Colors.white, size: size);

      case 'Vitals':
        return Icon(Icons.favorite, color: Colors.white, size: size);

      case 'Activity':
        return Icon(Icons.directions_walk, color: Colors.white, size: size);

      case 'Reminder':
        return Icon(Icons.notifications, color: Colors.white, size: size);

      default:
        return Icon(Icons.event, color: Colors.white, size: size);
    }
  }


  Color _colorForCategory(String c) {
    switch (c) {
      case 'Medication':
        return Colors.orange.shade300;
      case 'Appointment':
        return Colors.blue.shade300;
      case 'Vitals':
        return Colors.red.shade300;
      case 'Activity':
        return Colors.green.shade300;
      case 'Reminder':
        return Colors.purple.shade300;
      default:
        return kTeal.withAlpha(100);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ctl = Get.find<EventsController>();

    return GestureDetector(
      onTap: () {
        showDialog(context: context, builder: (_) => EventDetailsDialog(event: event));
      },
      onLongPress: () {
        ctl.startEdit(event);
        showDialog(context: context, builder: (_) => EventDetailsDialog(event: event));
      },
      child: Container(
        width: Get.width * 0.7,
        height: Get.height * 0.14,
        margin: EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F6F7),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFE1E6E8)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),

        padding: EdgeInsets.all(Get.width * 0.035),
        child: Row(
          children: [
            // Left side Icon bubble
            Container(
              width: Get.width * 0.14,
              height: Get.width * 0.14,
              decoration: BoxDecoration(
                color: _colorForCategory(event.category).withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: _colorForCategory(event.category).withValues(alpha: 0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
          child: Center(
            child: _iconForCategory(
              event.category,
              Get.width * 0.075,
            ),
          ),
            ),

          const SizedBox(width: 14),

            // Right side text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.nunito(
                      fontWeight: FontWeight.w800,
                      fontSize: Get.width * 0.042,
                      color: Colors.black87,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    _friendlyDate(event.eventTime),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.nunito(
                      color: Colors.black54,
                      fontSize: Get.width * 0.0335,
                    ),
                  ),

                  const Spacer(),

                  // Category chip
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(65),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: kTeal.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          event.category,
                          style: GoogleFonts.nunito(
                            fontSize: Get.width * 0.0335,
                            color: kTeal,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}