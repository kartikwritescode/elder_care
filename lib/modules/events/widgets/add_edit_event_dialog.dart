import 'package:date_picker_timeline/date_picker_widget.dart';
import 'package:day_night_time_picker/lib/daynight_timepicker.dart';
import 'package:day_night_time_picker/lib/state/time.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../care_receiver/views/schedule_screen.dart';
import '../controllers/events_controller.dart';

class AddEditEventDialog extends StatefulWidget {
  final bool isEdit;
  final EventsController controller;
  const AddEditEventDialog({super.key, required this.isEdit, required this.controller});

  @override
  State<AddEditEventDialog> createState() => _AddEditEventDialogState();
}

class _AddEditEventDialogState extends State<AddEditEventDialog> {

  String? errorMessage;
  @override
  void initState() {
    super.initState();

    if (!widget.isEdit) {
      final now = DateTime.now();
      widget.controller.pickedDate ??= DateTime(now.year, now.month, now.day);
    }
  }
  final _form = GlobalKey<FormState>();
  bool loading = false;

  // DatePicker needs a starting date; we show timeline from today
  final DateTime start = DateTime.now();

  // Use a small fixed height for the timeline to avoid overflow
  static final double _timelineHeight = Get.height * 0.11;


  // Open day-night time picker (animated)
  Future<void> _showTimePicker() async {
    final initial = widget.controller.pickedTime ?? TimeOfDay.now();


    await Navigator.of(context).push(
      showPicker(
        context: context,
        value: Time(hour: initial.hour, minute: initial.minute),
        onChange: (time) {
          final t = TimeOfDay(hour: time.hour, minute: time.minute);
          widget.controller.pickedTime = t;

          if (widget.controller.pickedDate != null) {
            final combined = DateTime(widget.controller.pickedDate!.year, widget.controller.pickedDate!.month,
                widget.controller.pickedDate!.day, t.hour, t.minute);
            widget.controller.dateController.text = combined.toIso8601String();
          } else {
            final now = DateTime.now();
            final combined = DateTime(now.year, now.month, now.day, t.hour, t.minute);
            widget.controller.dateController.text = combined.toIso8601String();
          }
          setState(() {
            errorMessage = null;
          });
        },

        iosStylePicker: false,

      ),
    );
  }

  String _displayPicked() {
    if (widget.controller.pickedDate == null && widget.controller.pickedTime == null) return 'Select date & time';
    final date = widget.controller.pickedDate;
    final time = widget.controller.pickedTime;
    if (date == null) {
      if (time == null) return 'Select date & time';
      return 'Time: ${time.format(context)}';
    }
    if (time == null) {
      return '${date.day}/${date.month}/${date.year} • pick time';
    }
    return '${date.day}/${date.month}/${date.year} • ${time.format(context)}';
  }

  @override
  Widget build(BuildContext context) {
    final w = Get.width;
    return Dialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: Get.width * 0.05,
        // vertical: Get.height * 0.04,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: SingleChildScrollView(
        child: Container(
          padding: EdgeInsets.all(Get.width * 0.045),
          decoration: BoxDecoration(
              borderRadius: BorderRadius.all(Radius.circular(30)),
              gradient: LinearGradient(colors: [Color(0xFFeaf4f2), Colors.white])),
          child: Form(
            key: _form,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              // header


              Text(widget.isEdit ? 'Edit Event' : 'New Event', style: GoogleFonts.nunito(fontSize: 22, fontWeight: FontWeight.w800)),
              SizedBox(height: Get.height * 0.015),

              // Title
              TextFormField(
                controller: widget.controller.titleController,
                decoration: _inputDecor('Event Name', Icons.edit, w),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter a title' : null,
              ),
              SizedBox(height: Get.height * 0.015),

              // Date timeline - fixed height to avoid overflow
              SizedBox(
                height: _timelineHeight,
                child: DatePicker(
                  start,
                  initialSelectedDate: widget.controller.pickedDate ?? start,
                  selectionColor: kTeal,
                  selectedTextColor: Colors.white,
                  dayTextStyle: TextStyle(fontSize: 12),
                  dateTextStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  monthTextStyle: TextStyle(fontSize: 10),
                  onDateChange: (date) {
                    // date selected
                    widget.controller.pickedDate = date.isBefore(DateTime.now()) ? DateTime.now() : date;
                    if (widget.controller.pickedTime != null) {
                      final t = widget.controller.pickedTime!;
                      final combined = DateTime(date.year, date.month, date.day, t.hour, t.minute);
                      widget.controller.dateController.text = combined.toIso8601String();
                    }
                    setState(() {
                      errorMessage=null;
                    });
                  },
                ),
              ),

              SizedBox(height: Get.height * 0.012),

              // Time picker trigger
              GestureDetector(
                onTap: _showTimePicker,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(w * 0.05)),
                  child: Row(
                    children: [
                      Icon(Icons.access_time, color: kTeal),
                      SizedBox(width: 12),
                      Expanded(child: Text(_displayPicked(), style: GoogleFonts.nunito())),
                      Icon(Icons.keyboard_arrow_down)
                    ],
                  ),
                ),
              ),

              SizedBox(height: Get.height * 0.015),

              // Category dropdown
              Obx(() {
                return Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: w * 0.02,
                    vertical: h * 0.002,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(w * 0.05),
                    // border: Border.all(
                    //   color: kTeal.withOpacity(0.35),
                    //   width: 1,
                    // ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButtonFormField<String>(
                      value: widget.controller.category.value,
                      isExpanded: true,
                      icon: const Icon(Icons.keyboard_arrow_down),
                      dropdownColor: Colors.white,
                      borderRadius: BorderRadius.circular(18),

                      style: GoogleFonts.nunito(
                        fontSize: w * 0.038,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),

                      decoration: InputDecoration(
                        prefixIcon: Icon(Icons.category, color: kTeal),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          vertical: h * 0.018,
                          horizontal: w * 0.02,
                        ),
                      ),

                      items: widget.controller.categories.map((c) {
                        return DropdownMenuItem<String>(
                          value: c,
                          child: Text(
                            c,
                            style: GoogleFonts.nunito(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      }).toList(),

                      onChanged: (v) {
                        if (v != null) {
                          widget.controller.category.value = v;
                        }
                      },
                    ),
                  ),
                );
              }),



              SizedBox(height: Get.height * 0.015),

              // Notes (multiline)
              TextFormField(
                controller: widget.controller.notesController,
                minLines: 2,
                maxLines: 4,
                decoration: _inputDecor('Notes (optional)', Icons.note, w),
              ),

              SizedBox(height: 16),
              SizedBox(height: 8),//todo fix sizing here

              if (errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red, size: 18),
                      SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          errorMessage!,
                          style: GoogleFonts.nunito(
                            color: Colors.red,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Save button
              ElevatedButton(
                onPressed: loading
                    ? null
                    : () async {
                  if (!_form.currentState!.validate()) return;


                  setState(() {
                    errorMessage = null;
                  });

                  if (widget.controller.pickedDate == null ||
                      widget.controller.pickedTime == null) {
                    setState(() {
                      errorMessage = "Please select date & time";
                    });
                    return;
                  }

                  final combined = DateTime(
                    widget.controller.pickedDate!.year,
                    widget.controller.pickedDate!.month,
                    widget.controller.pickedDate!.day,
                    widget.controller.pickedTime!.hour,
                    widget.controller.pickedTime!.minute,
                  );

                  if (!combined.isAfter(DateTime.now())) {
                    setState(() {
                      errorMessage = "Please select a future date & time";
                    });
                    return;
                  }

                  setState(() => loading = true);

                  bool success;

                  if (widget.isEdit) {
                    success = await widget.controller.confirmEdit();
                  } else {
                    success = await widget.controller.addEvent();
                  }

                  if (!mounted || !context.mounted) return;

                  setState(() => loading = false);

                  if (success) {
                    widget.controller.clearForm();
                    Navigator.of(context).pop(true);


                    Future.delayed(const Duration(milliseconds: 100), () {
                      Get.snackbar(
                        'Success',
                        widget.isEdit ? 'Event updated' : 'Event added',
                        snackPosition: SnackPosition.TOP,
                        backgroundColor: Colors.green.shade100,
                        colorText: Colors.black,
                        margin: const EdgeInsets.all(12),
                      );
                    });
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: kTeal,
                  minimumSize: Size(double.infinity, Get.height * 0.055),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(Get.width * 0.05),
                  ),
                ),
                child: loading
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.2,
                  ),
                )
                    : Text(
                  widget.isEdit ? 'Save Changes' : 'Add Event',
                  style: GoogleFonts.nunito(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),

              SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  widget.controller.clearForm();
                  Navigator.pop(context);
                },
                child: Text('Cancel', style: GoogleFonts.nunito(color: Colors.grey)),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecor(String label, IconData icon, double w) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: kTeal),
      filled: true,
      fillColor: Colors.grey.shade100,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(w * 0.05), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(w * 0.05), borderSide: BorderSide(color: kTeal, width: 1.3)),
    );
  }
}
