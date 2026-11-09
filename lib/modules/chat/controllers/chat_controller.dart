import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/models/message_model.dart';
import '../../../core/services/fcm_service.dart';
import '../../auth/controllers/auth_controller.dart';

class ChatController extends GetxController {
  final SupabaseClient supabase = Supabase.instance.client;

  final messages = <MessageModel>[].obs;
  final loading = true.obs;

  final partnerName = "Care Partner".obs;
  final partnerImage = RxnString();

  String? _chatId;
  String? _partnerId;

  String? get activeChatId => _chatId;

  RealtimeChannel? _channel;
  bool _isSending = false;

  void initChat({
    required String chatId,
    required String partnerId,
    required String partnerName,
    String? partnerImage,
  }) {
    _chatId = chatId;
    _partnerId = partnerId;
    this.partnerName.value = partnerName;
    this.partnerImage.value = partnerImage;

    _loadMessages();
    _subscribe();
    _markMessagesAsSeen();
  }

  @override
  void onClose() {
    _channel?.unsubscribe();
    _chatId = null;
    _partnerId = null;
    super.onClose();
  }

  /// 📥 LOAD MESSAGES (Descending for reverse ListView)
  Future<void> _loadMessages() async {
    try {
      loading.value = true;

      final response = await supabase
          .from('messages')
          .select()
          .eq('chat_id', _chatId!)
          .order('created_at', ascending: false)
          .limit(50);

      final loaded = (response as List)
          .map((e) => MessageModel.fromJson(e))
          .toList();

      messages.value = loaded;
    } catch (e) {
      debugPrint("Load messages error: $e");
    } finally {
      loading.value = false;
    }
  }

  /// 👀 SEEN STATUS
  Future<void> _markMessagesAsSeen() async {
    await supabase
        .from('messages')
        .update({'is_seen': true})
        .eq('chat_id', _chatId!)
        .eq('sender_id', _partnerId!)
        .eq('is_seen', false);
  }

  void _subscribe() {
    if (_chatId == null) return;
    if (_channel != null) {
      supabase.removeChannel(_channel!);
    }


    _channel = supabase.channel('chat:$_chatId')
      ..onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'messages',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'chat_id',
          value: _chatId!,
        ),
        callback: (payload) async {
          final msg = MessageModel.fromJson(payload.newRecord);
          // Insert at the beginning of the list (newest first)
          messages.insert(0, msg);

          // auto-mark seen if message is from partner
          if (msg.senderId == _partnerId) {
            await _markMessagesAsSeen();
          }
        },
      )
      ..onPostgresChanges(
        event: PostgresChangeEvent.update,
        schema: 'public',
        table: 'messages',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'chat_id',
          value: _chatId!,
        ),
        callback: (payload) {
          final updated = MessageModel.fromJson(payload.newRecord);
          final index =
          messages.indexWhere((m) => m.id == updated.id);
          if (index != -1) {
            messages[index] = updated;
            messages.refresh();

          }
        },
      )
      ..subscribe();
  }

  Future<void> sendMessage(String text) async {
    final trimmedText = text.trim();
    if (trimmedText.isEmpty) return;
    if (_isSending) return;
    _isSending = true;
    if (_chatId == null || _partnerId == null) return;

    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;
      final userId = user.id;

      await supabase.from('messages').insert({
        'chat_id': _chatId,
        'sender_id': userId,
        'content': trimmedText,
        'is_seen': false,
      });

      // 🔥 Send FCM Notification to partner with cached sender name
      String myName = "Someone";
      if (Get.isRegistered<AuthController>()) {
        final authUser = Get.find<AuthController>().user.value;
        if (authUser?.fullName?.isNotEmpty == true) {
          myName = authUser!.fullName!;
        }
      }

      await FcmService.sendNotification(
        receiverId: _partnerId!,
        title: myName,
        body: trimmedText,
        type: "chat",
        extraData: {
          'chat_id': _chatId!,
          'sender_name': myName,
          'message': trimmedText,
        },
      );
    } catch (e) {
      debugPrint("SendMessage error: $e");
    } finally {
      _isSending = false;
    }
  }
}
