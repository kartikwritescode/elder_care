import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/models/message_model.dart';
import '../../../core/services/chat_service.dart';
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

  RealtimeChannel? _channel;
  bool _initialized = false;

  /// 🔹 Called once when screen opens
  Future<void> initChat({
    required String chatId,
    required String partnerId,
    required String partnerName,
    String? partnerImage,
  }) async {
    if (_initialized && _chatId == chatId) return;

    _initialized = true;
    _chatId = chatId;
    _partnerId = partnerId;

    this.partnerName.value = partnerName;
    this.partnerImage.value = partnerImage;

    loading.value = true;

    await _loadMessages();
    await _markMessagesAsSeen(); // ✅ IMPORTANT
    _subscribe();

    loading.value = false;
  }

  Future<void> _loadMessages() async {
    if (_chatId == null) return;

    final res = await supabase
        .from('messages')
        .select()
        .eq('chat_id', _chatId!)
        .order('created_at', ascending: false);

    final loaded =
    (res as List).map((e) => MessageModel.fromJson(e)).toList();

    // Sort descending: newest messages first (at index 0)
    loaded.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    messages.value = loaded;
  }

  ///   SEEN STATUS
  Future<void> _markMessagesAsSeen() async {
    final myId = supabase.auth.currentUser!.id;

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
    if (_chatId == null || _partnerId == null) return;

    final userId = supabase.auth.currentUser!.id;

    await supabase.from('messages').insert({
      'chat_id': _chatId,
      'sender_id': userId,
      'content': text,
      'is_seen': false,
    });

    // 🔥 Send FCM Notification to partner
    final myProfile = await supabase.from('users').select('full_name').eq('id', userId).maybeSingle();
    final myName = myProfile?['full_name'] ?? "Someone";

    await FcmService.sendNotification(
      receiverId: _partnerId!,
      title: "New Message from $myName",
      body: text,
      type: "chat",
      extraData: {
        'chat_id': _chatId!,
        'sender_name': myName,
        'message': text,
      }
    );
  }

  @override
  void onClose() {
    if (_channel != null) {
      supabase.removeChannel(_channel!);
    }
    super.onClose();
  }
}
