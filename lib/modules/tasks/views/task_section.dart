import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/utils/sound_utils.dart';
import '../controllers/task_controller.dart';
import '../../../core/models/task_model.dart';
import '../../dashboard/controllers/nav_controller.dart';
import '../widgets/add_edit_dialog.dart';
import '../widgets/task_tile.dart';
import '../widgets/tasks_details_dialog.dart';

const Color kTeal = Color(0xFF7AB7A7);

class TaskSection extends StatelessWidget {
  final String? receiverIdOverride;

  const TaskSection({super.key, this.receiverIdOverride});

  TaskController get controller => Get.find<TaskController>();
  NavController get nav => Get.find<NavController>();

  @override
  Widget build(BuildContext context) {
    // Sync tasks if receiver changes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final rid = receiverIdOverride ?? nav.linkedReceiverId.value;
      if (rid.isNotEmpty && controller.currentReceiverId != rid) {
        controller.loadTasksForReceiver(rid);
      }
    });

    final receiverId = receiverIdOverride?.isNotEmpty == true
        ? receiverIdOverride!
        : nav.linkedReceiverId.value;

    if (receiverId.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(20.0),
        child: Text(
          receiverIdOverride != null ? "No tasks available" : "No receiver linked yet",
          style: GoogleFonts.nunito(color: Colors.grey, fontSize: 16),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          // const SizedBox(height: 10),
          _buildTaskList(context),
        ],
      ),
    );
  }


  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            'Tasks',
            style: GoogleFonts.nunito(
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        GestureDetector(
          onTap: () {
            controller.clearForm();
            _openAddDialog(context, isEdit: false);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: kTeal,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                    color: kTeal.withValues(alpha: 0.23),
                    blurRadius: 8,
                    offset: const Offset(0, 5))
              ],
            ),
            child: Row(children: [
              const Icon(Icons.add, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text('Add',
                  style: GoogleFonts.nunito(
                      color: Colors.white, fontWeight: FontWeight.w700)),
            ]),
          ),
        )
      ],
    );
  }

  Widget _buildTaskList(BuildContext context) {
    return Obx(() {
      final list = controller.tasks;

      if (list.isEmpty) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20.0),
            child: Text('No tasks yet',
                style: GoogleFonts.nunito(color: Colors.grey)),
          ),
        );
      }

      return ListView.separated(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemCount: list.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) {
          final t = list[i];
          return _TaskItem(
            key: ValueKey("task_${t.id}"),
            task: t,
            index: i,
            controller: controller,
            onTap: () => _openDetailsDialog(context, t),
          );
        },
      );
    });
  }

  void _openAddDialog(BuildContext ctx, {required bool isEdit}) {
    showDialog(
      context: ctx,
      builder: (_) => AddEditTaskDialog(isEdit: isEdit, controller: controller),
    );
  }

  void _openDetailsDialog(BuildContext context, TaskModel t) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.3),
      builder: (_) => TaskDetailsDialog(task: t, controller: controller),
    );
  }
}

class _TaskItem extends StatefulWidget {
  final TaskModel task;
  final int index;
  final TaskController controller;
  final VoidCallback onTap;

  const _TaskItem({
    super.key,
    required this.task,
    required this.index,
    required this.controller,
    required this.onTap,
  });

  @override
  State<_TaskItem> createState() => _TaskItemState();
}

class _TaskItemState extends State<_TaskItem> {
  bool _isRemoving = false;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey("task_${widget.task.id}"),
      direction: DismissDirection.horizontal,
      background: _buildDismissBackground(Alignment.centerLeft),
      secondaryBackground: _buildDismissBackground(Alignment.centerRight),
      onDismissed: (_) {
        widget.controller.deleteTaskWithUndo(widget.task, widget.index);
      },
      child: Stack(
        children: [
          Container(
            height: 80,
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(22),
            ),
          ),
          AnimatedSlide(
            offset: _isRemoving ? const Offset(-1.2, 0) : Offset.zero,
            duration: const Duration(milliseconds: 500),
            child: GestureDetector(
              onTap: widget.onTap,
              child: TaskTile(
                task: widget.task,
                onDone: () async {
                  await SoundUtils.playDone();
                  HapticFeedback.mediumImpact();
                  if (mounted) setState(() => _isRemoving = true);
                  await Future.delayed(const Duration(milliseconds: 500));
                  widget.controller.markTaskCompleted(widget.task, widget.index);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDismissBackground(Alignment alignment) {
    return Container(
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.redAccent.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(22),
      ),
      child: const Icon(Icons.delete_sweep, color: Colors.redAccent),
    );
  }
}

