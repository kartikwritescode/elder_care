
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../controllers/events_controller.dart';
import '../widgets/add_edit_event_dialog.dart';
import '../widgets/event_card.dart';

const Color kTeal = Color(0xFF7AB7A7);

class EventSection extends StatelessWidget {
  EventSection({super.key});

  final EventsController controller = Get.find<EventsController>();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _header(context),
        SizedBox(height: Get.height * 0.015),
        _horizontalList(),
      ],
    );
  }

  Widget _header(BuildContext ctx) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: Get.width * 0.05),
      child: Row(children: [
        Expanded(
          child: Text('Events', style: GoogleFonts.nunito(fontSize: 22, fontWeight: FontWeight.w800)),
        ),
        GestureDetector(
          onTap: () {
            controller.clearForm();
            _openAddDialog(ctx, isEdit: false);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: kTeal,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: kTeal.withValues(alpha: 0.22), blurRadius: 8, offset: const Offset(0, 5))],
            ),
            child: Row(children: [
              const Icon(Icons.add, color: Colors.white),
              const SizedBox(width: 8),
              Text('Add', style: GoogleFonts.nunito(color: Colors.white, fontWeight: FontWeight.w700)),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _horizontalList() {
    return Obx(() {
      final events = controller.events;

      return SizedBox(
        height: events.isNotEmpty
            ? Get.height * 0.14
            : Get.height * 0.06,
        child: events.isEmpty
            ? Padding(
          padding: const EdgeInsets.only(left: 20),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'No events yet',
              style: GoogleFonts.nunito(color: Colors.grey),
            ),
          ),
        )
            : ListView.builder(
          padding: const EdgeInsets.only(left: 20),
          scrollDirection: Axis.horizontal,
          itemCount: events.length,
          itemBuilder: (_, i) {
            return EventCardCompact(event: events[i]);
          },
        ),
      );
    });
  }

  void _openAddDialog(BuildContext ctx, {required bool isEdit}) {
    showDialog(
      context: ctx,
      builder: (_) => AddEditEventDialog(isEdit: isEdit, controller: controller),
    );
  }
}
