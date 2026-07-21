import 'package:elder_care/app/utils/phone_call.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../controllers/chat_controller.dart';
import '../widgets/chat_bubble.dart';
import '../../auth/controllers/auth_controller.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;
  final String partnerId;
  final String partnerName;
  final String? partnerImage;
  final double keyboardInset;
  ChatScreen({Key? key, required this.chatId, required this.partnerId, required this.partnerName, this.partnerImage, required this.keyboardInset}) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late final ChatController controller;


  final AuthController authController = Get.find<AuthController>();

  final TextEditingController textController = TextEditingController();

  final ScrollController scrollController = ScrollController();
  @override
  void initState() {
    super.initState();

    controller = Get.put(ChatController(), tag: widget.chatId);

    controller.initChat(
      chatId: widget.chatId,
      partnerId: widget.partnerId,
      partnerName: widget.partnerName,
      partnerImage: widget.partnerImage,
    );

    /// Listen for new messages
    int previousLength = 0;

    ever(controller.messages, (list) {
      if (list.length > previousLength) {
        // Only auto-scroll if we are near the bottom or if it's our own message
        if (_isNearBottom() || (list.isNotEmpty && list.first.senderId == authController.user.value?.id)) {
          _scrollToBottom();
        }
      }
      previousLength = list.length;
    });
  }

  bool _isNearBottom() {
    if (!scrollController.hasClients) return true;
    // In a reversed list, 0.0 is the bottom.
    return scrollController.offset < 100;
  }

  @override
  void dispose() {
    Get.delete<ChatController>(tag: widget.chatId);
    scrollController.dispose();
    textController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (!scrollController.hasClients) return;

    scrollController.animateTo(
      0.0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      extendBody: false, // Changed to false to avoid keyboard overlapping issues


      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        titleSpacing: 0,
        title: Obx(() => Row(
          children: [
            SizedBox(width: Get.width * 0.05),
            CircleAvatar(
              radius: 20,
              backgroundImage: controller.partnerImage.value != null &&
                  controller.partnerImage.value!.isNotEmpty
                  ? NetworkImage(controller.partnerImage.value!)
                  : null,
              backgroundColor: Colors.teal.shade100,
              child: controller.partnerImage.value == null || controller.partnerImage.value!.isEmpty
                  ? const Icon(Icons.person, color: Colors.teal)
                  : null,
            ),
            SizedBox(width: Get.width * 0.05),
            Text(
              controller.partnerName.value,
              style: GoogleFonts.nunito(
                fontWeight: FontWeight.w800,
                fontSize: 17,
              ),
            ),
          ],
        )),
        actions: [
          IconButton(icon: const Icon(Icons.call), onPressed: () {
            // Assuming the controller or something has the partner's phone number
            // For now keeping it as is since I should only touch chat logic
            makePhoneCall(""); 
          }),
          IconButton(icon: const Icon(Icons.more_vert), onPressed: () {}),
        ],
      ),

      //  BODY
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFEAF4F2), Color(0xFFFDFBF8)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Obx(() {
          if (controller.loading.value) {
            return const Center(child: CircularProgressIndicator());
          }

          return Column(
            children: [

              /// MESSAGES AREA
              Expanded(
                child: Stack(
                  children: [
                    _chatBackground(),

                    ListView.builder(
                      controller: scrollController,
                      reverse: true, // Crucial for chat apps
                      physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                      padding: EdgeInsets.symmetric(
                        vertical: Get.height * 0.01,
                      ),
                      itemCount: controller.messages.length,
                      itemBuilder: (_, i) {
                        final msg = controller.messages[i];
                        final isMe =
                            msg.senderId == authController.user.value?.id;

                        // In reversed list, i+1 is OLDER than i
                        final currentDate = msg.createdAt;
                        final olderDate = i < controller.messages.length - 1
                            ? controller.messages[i + 1].createdAt
                            : null;

                        // Show separator if this is the oldest message or if the next (older) message is on a different day
                        final showDateSeparator = olderDate == null ||
                            !_isSameDay(currentDate, olderDate);

                        return Column(
                          children: [
                            if (showDateSeparator)
                              _buildDateSeparator(currentDate),

                            ChatBubble(
                              message: msg.content,
                              isMe: isMe,
                              time: msg.createdAt,
                              isSeen: isMe ? msg.isSeen : false,
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),

              /// INPUT BAR
              _inputBar(),
            ],
          );
        }),
      ),
    );

  }

  /// INPUT BAR
  Widget _inputBar() {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          Get.width * 0.04,
          Get.height * 0.004,
          Get.width * 0.04,
          Get.height * 0.015,
        ),
        child: Material(
          elevation: 10,
          borderRadius: BorderRadius.circular(Get.width * 0.07),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: Get.width * 0.03,
              vertical: Get.height * 0.006,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(Get.width * 0.07),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: textController,
                    minLines: 1,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText: "Type a message…",
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                ),

                SizedBox(width: Get.width * 0.02),

                CircleAvatar(
                  radius: Get.width * 0.055,
                  backgroundColor: const Color(0xFF7AB7A7),
                  child: IconButton(
                    icon: Icon(
                      Icons.send_rounded,
                      size: Get.width * 0.05,
                      color: Colors.white,
                    ),
                    onPressed: () {
                      final text = textController.text.trim();
                      if (text.isEmpty) return;

                      controller.sendMessage(text);
                      textController.clear();
                      // No need to manually scroll if 'ever' listener handles it, 
                      // but calling it here ensures immediate feedback for sender.
                      _scrollToBottom();
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Widget _chatBackground() {
  return Positioned.fill(
    child: Opacity(
      opacity: 0.3,
      child: Image.asset(
        'assets/images/chat_bgg.png',
        fit: BoxFit.cover,
      ),
    ),
  );
}

bool _isSameDay(DateTime a, DateTime b) {
  return a.year == b.year &&
      a.month == b.month &&
      a.day == b.day;
}

Widget _buildDateSeparator(DateTime date) {
  final now = DateTime.now();
  String label;

  if (_isSameDay(date, now)) {
    label = "Today";
  } else if (_isSameDay(
      date, now.subtract(const Duration(days: 1)))) {
    label = "Yesterday";
  } else {
    label = "${date.day}/${date.month}/${date.year}";
  }

  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 20),
    child: Center(
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w600),
        ),
      ),
    ),
  );
}
