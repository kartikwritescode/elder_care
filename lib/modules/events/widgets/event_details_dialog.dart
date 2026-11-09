import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/models/event_model.dart';
import '../controllers/events_controller.dart';
import 'add_edit_event_dialog.dart';

const Color kTeal = Color(0xFF7AB7A7);

class EventDetailsDialog extends StatelessWidget {
  final EventModel event;
  final EventsController controller = Get.find<EventsController>();

  EventDetailsDialog({
    super.key,
    required this.event,
  });

  static const Color kBg = Color(0xFFF3F6F7);

  @override
  Widget build(BuildContext context) {
    // final controller = Get.find<EventsController>();

    final DateTime dt = event.eventTime.toLocal();

    return Dialog(
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
              color: kBg,
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
                      'assets/images/event.png',
                      width: Get.width*0.1,
                      height: Get.width*0.1,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Event Details',
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
                  event.title,
                  style: GoogleFonts.nunito(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 6),
                Text(
                  _friendlyDate(dt),
                  style: GoogleFonts.nunito(
                    fontSize: 13,
                    color: Colors.black54,
                  ),
                ),

                const SizedBox(height: 14),

                /// META CHIPS
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  children: [
                    _metaChip(
                      icon: Icons.event,
                      label: event.category,
                    ),

                    if (event.notes.isNotEmpty)
                      _metaChip(
                        icon: Icons.note,
                        label: 'Notes',
                      ),
                  ],
                ),

                if (event.notes.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    event.notes,
                    style: GoogleFonts.nunito(
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                ],

                const SizedBox(height: 22),

                /// ACTIONS
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          controller.startEdit(event);
                          Navigator.pop(context);
                          showDialog(
                            context: context,
                            builder: (_) => AddEditEventDialog(
                              isEdit: true,
                              controller: controller,
                            ),
                          );
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
                      child: StatefulBuilder(
                        builder: (context, setState) {
                          return Obx(() {
                            final deleting = controller.isLoading.value;
                            return ElevatedButton(
                              onPressed: deleting
                                  ? null
                                  : () async {
                                await controller.deleteEventConfirmed(event.id!);
                                if (!context.mounted) return;
                                Navigator.of(context).pop();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.redAccent,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                elevation: 0,
                              ),
                              child: deleting
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Text(
                                      'Delete',
                                      style: GoogleFonts.nunito(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                            );
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// META CHIP
  Widget _metaChip({
    IconData? icon,
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
}
