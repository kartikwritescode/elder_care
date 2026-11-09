import 'package:date_picker_timeline/date_picker_widget.dart';
import 'package:day_night_time_picker/lib/daynight_timepicker.dart';
import 'package:day_night_time_picker/lib/state/time.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../controllers/task_controller.dart';
import 'repeat_options_tile.dart';

/// Add / Edit Dialog
class AddEditTaskDialog extends StatefulWidget {
  final bool isEdit;
  final TaskController controller;
  const AddEditTaskDialog({super.key, required this.isEdit, required this.controller});

  @override
  State<AddEditTaskDialog> createState() => _AddEditTaskDialogState();
}

class _AddEditTaskDialogState extends State<AddEditTaskDialog> {
  Color kTeal = const Color(0xFF7AB7A7);
  final _form = GlobalKey<FormState>();
  final DateTime start = DateTime.now();
  bool loading = false;
  bool _showRepeatOptions = false;
  String? _errorText;


  static const double _timelineHeight = 92;

  Future<void> _showTimePicker() async {
    final initial = widget.controller.pickedTime ?? TimeOfDay.now();

    await Navigator.of(context).push(
      showPicker(
        context: context,
        value: Time(hour: initial.hour, minute: initial.minute),
        onChange: (time) {
          final chosen = TimeOfDay(hour: time.hour, minute: time.minute);

          // If date is today → disallow selecting past times
          if (widget.controller.pickedDate != null) {
            final d = widget.controller.pickedDate!;
            final combined = DateTime(d.year, d.month, d.day, chosen.hour, chosen.minute);

            if (combined.isBefore(DateTime.now())) {
              Get.snackbar('Invalid', 'Please choose a future time');
              return;
            }
          }

          widget.controller.setPickedTime(chosen);

          // update ISO combined datetime
          if (widget.controller.pickedDate != null) {
            final d = widget.controller.pickedDate!;
            final combined = DateTime(d.year, d.month, d.day, chosen.hour, chosen.minute);
            widget.controller.dateController.text = combined.toIso8601String();
          }

          setState(() {});
        },
        is24HrFormat: false,
        iosStylePicker: false,
      ),
    );
  }


  bool isSameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _displayPicked() {
    if (widget.controller.pickedDate == null && widget.controller.pickedTime == null) return 'Pick date & time (optional)';
    final date = widget.controller.pickedDate;
    final time = widget.controller.pickedTime;
    if (date == null) {
      if (time == null) return 'Pick date & time (optional)';
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

    // ensure when opened for edit the fields already set by controller.startEdit
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {}); // update UI from controller pickedDate/pickedTime if needed
    });

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: const BoxDecoration(
              borderRadius: BorderRadius.all(Radius.circular(40)),
              gradient: LinearGradient(colors: [Color(0xFFeaf4f2), Colors.white])),
          child: Form(
            key: _form,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text(widget.isEdit ? 'Edit Task' : 'New Task', style: GoogleFonts.nunito(fontSize: 20, fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),

              TextFormField(
                controller: widget.controller.titleController,
                decoration: _inputDecor('Task name', Icons.edit, w),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter a task name' : null,
              ),
              const SizedBox(height: 12),

              SizedBox(
                height: _timelineHeight,
                child: DatePicker(
                  start,
                  initialSelectedDate: widget.controller.pickedDate ?? start,
                  selectionColor: kTeal,
                  selectedTextColor: Colors.white,
                  dayTextStyle: const TextStyle(fontSize: 12),
                  dateTextStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  monthTextStyle: const TextStyle(fontSize: 10),
                  onDateChange: (date) {
                    // disallow selecting a past date
                    final now = DateTime.now();
                    final chooseDate = date.isBefore(DateTime(now.year, now.month, now.day)) ? DateTime(now.year, now.month, now.day) : date;
                    widget.controller.setPickedDate(chooseDate);
                    if (widget.controller.pickedTime != null) {
                      final t = widget.controller.pickedTime!;
                      final combined = DateTime(chooseDate.year, chooseDate.month, chooseDate.day, t.hour, t.minute);
                      widget.controller.dateController.text = combined.toIso8601String();
                    }
                    setState(() {

                    });
                  },
                ),
              ),

              const SizedBox(height: 10),

              GestureDetector(
                onTap: _showTimePicker,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(w * 0.05)),
                  child: Row(children: [
                    Icon(Icons.access_time, color: kTeal),
                    const SizedBox(width: 12),
                    Expanded(child: Text(_displayPicked(), style: GoogleFonts.nunito())),
                    const Icon(Icons.keyboard_arrow_down)
                  ]),
                ),
              ),

              const SizedBox(height: 12),

              // visible only when both date & time selected
              if (widget.controller.showAlarmCheckbox())
                Obx(() => Column(
                  children: [

                    /// REMINDER
                    Row(
                      children: [
                        Checkbox(
                          value: widget.controller.reminderEnabled.value,
                          activeColor: kTeal,
                          onChanged: (v) =>
                          widget.controller.reminderEnabled.value = v ?? false,
                        ),
                        Text(
                          'Reminder',
                          style: GoogleFonts.nunito(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),

                    ///  MEDICINE (TAG ONLY)
                    Row(
                      children: [
                        Checkbox(
                          value: widget.controller.isMedicine.value,
                          activeColor: kTeal,
                          onChanged: (v) =>
                          widget.controller.isMedicine.value = v ?? false,
                        ),
                        Text(
                          'Medicine',
                          style: GoogleFonts.nunito(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ],
                )),


              // medicine
              if (widget.controller.showAlarmCheckbox())
                Obx(() => GestureDetector(
                  onTap: () => setState(() => _showRepeatOptions = !_showRepeatOptions),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOut,
                    margin: const EdgeInsets.only(top: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: _showRepeatOptions ? kTeal.withValues(alpha: 0.4) : Colors.transparent,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.repeat, color: kTeal),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _repeatLabel(widget.controller),
                            style: GoogleFonts.nunito(
                              fontWeight: FontWeight.w700,
                              fontSize: 14.5,
                            ),
                          ),
                        ),
                        AnimatedRotation(
                          turns: _showRepeatOptions ? 0.5 : 0,
                          duration: const Duration(milliseconds: 220),
                          child: const Icon(Icons.keyboard_arrow_down),
                        ),
                      ],
                    ),
                  ),
                )),

              // repeat
              if (_showRepeatOptions)
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 260),
                  transitionBuilder: (child, animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, -0.05),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    );
                  },
                  child: !_showRepeatOptions
                      ? const SizedBox.shrink()
                      : RepeatOptions(controller: widget.controller),
                ),

              const SizedBox(height: 12),

              if (_errorText != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8,left: 10),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 18),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          _errorText!,
                          style: GoogleFonts.nunito(
                            color: Colors.red,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),



              const SizedBox(height: 6),


              ElevatedButton(
                onPressed: () async {
                  if (!_form.currentState!.validate()) {
                    setState(() {
                      _errorText = "Please enter a task name";
                    });
                    return;
                  }
                  // if date chosen but no time -> ask
                  if (widget.controller.pickedDate != null && widget.controller.pickedTime == null) {
                    setState(() {
                      _errorText = "Please select a time for the chosen date";
                    });
                    return;
                  }

                  // if date is today + time picked ensure future
                  if (widget.controller.pickedDate != null && widget.controller.pickedTime != null) {
                    final combined = DateTime(widget.controller.pickedDate!.year, widget.controller.pickedDate!.month, widget.controller.pickedDate!.day, widget.controller.pickedTime!.hour, widget.controller.pickedTime!.minute);
                    if (!combined.isAfter(DateTime.now())) {
                      setState(() {
                        _errorText = "Please choose a future time";
                      });
                      return;
                    }
                  }

                  setState(() => loading = true);
                  if (widget.isEdit) {
                    await widget.controller.confirmEdit();
                  } else {
                    await widget.controller.addTask();
                  }
                  if (!mounted || !context.mounted) return;
                  setState(() => loading = false);
                  Navigator.pop(context, true);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: kTeal,
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(w * 0.05)),
                ),
                child: loading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.2))
                    : Text(widget.isEdit ? 'Save Changes' : 'Add Task', style: GoogleFonts.nunito(color: Colors.white)),
              ),

              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  widget.controller.clearForm();
                  Navigator.pop(context);
                },
                child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
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
  String _repeatLabel(TaskController c) {
    switch (c.repeatType.value) {
      case 'daily': return 'Repeat: Daily';
      case 'tomorrow': return 'Repeat: Tomorrow';
      case 'custom': return 'Repeat: ${c.repeatDays.join(', ')}';
      default: return 'Repeat: Never';
    }
  }

}
