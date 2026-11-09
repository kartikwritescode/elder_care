import 'package:supabase_flutter/supabase_flutter.dart';

class ChatService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<String> getOrCreateChat({
    required String userA,
    required String userB,
  }) async {
    // 1️⃣ Find existing chat by finding shared chat_id
    final userAChats = await _client
        .from('chat_members')
        .select('chat_id')
        .eq('user_id', userA);

    final chatIds = (userAChats as List).map((e) => e['chat_id'].toString()).toList();

    if (chatIds.isNotEmpty) {
      final shared = await _client
          .from('chat_members')
          .select('chat_id')
          .eq('user_id', userB)
          .inFilter('chat_id', chatIds)
          .limit(1);

      if ((shared as List).isNotEmpty) {
        return shared.first['chat_id'].toString();
      }
    }

    // 2️⃣ Create new chat
    final chat = await _client
        .from('chats')
        .insert({})
        .select('id')
        .single();

    final chatId = chat['id'].toString();

    // 3️⃣ Insert members
    await _client.from('chat_members').insert([
      {'chat_id': chatId, 'user_id': userA},
      {'chat_id': chatId, 'user_id': userB},
    ]);

    return chatId;
  }
}
