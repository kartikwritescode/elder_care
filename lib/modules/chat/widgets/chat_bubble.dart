import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ChatBubble extends StatelessWidget {
  final String message;
  final bool isMe;
  final DateTime time;
  final bool isSeen;

  const ChatBubble({
    super.key,
    required this.message,
    required this.isMe,
    required this.time,
    this.isSeen = false,
  });

  @override
  Widget build(BuildContext context) {
    final outgoingColor = const Color(0xFF6FB3A6); // teal
    final incomingColor = const Color(0xFFF9FAFA);

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          left: isMe ? 60 : 14,
          right: isMe ? 14 : 60,
          top: 6,
          bottom: 6,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.65,
        ),
        decoration: BoxDecoration(
          color: isMe ? outgoingColor : incomingColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft:
            isMe ? const Radius.circular(18) : const Radius.circular(4),
            bottomRight:
            isMe ? const Radius.circular(4) : const Radius.circular(18),
          ),
          border: isMe
              ? null
              : Border.all(color: Colors.black.withValues(alpha: 0.05)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.025),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment:
          isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              style: GoogleFonts.nunito(
                fontSize: 15,
                height: 1.4,
                color: isMe ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatTime(time),
                  style: GoogleFonts.nunito(
                    fontSize: 10.5,
                    color:
                    isMe ? Colors.white70 : Colors.black45,
                  ),
                ),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  Icon(
                    isSeen ? Icons.done_all : Icons.done,
                    size: 14,
                    color: isSeen
                        ? Colors.white.withValues(alpha: 0.9)
                        : Colors.white60,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final h = time.hour % 12 == 0 ? 12 : time.hour % 12;
    final m = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return "$h:$m $period";
  }
}
