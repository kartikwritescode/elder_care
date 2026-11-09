import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/cache_service.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../dashboard/controllers/nav_controller.dart';
import 'chat_screen.dart';

class DirectChatScreen extends StatefulWidget {
  const DirectChatScreen({super.key});

  @override
  State<DirectChatScreen> createState() => _DirectChatScreenState();
}

class _DirectChatScreenState extends State<DirectChatScreen> {
  final RxBool _isActivated = false.obs;

  @override
  Widget build(BuildContext context) {
    if (Get.isRegistered<NavController>()) {
      final nav = Get.find<NavController>();
      if (nav.selectedIndex.value == 1) {
        _isActivated.value = true;
      }
    } else {
      _isActivated.value = true;
    }

    return Obx(() {
      if (!_isActivated.value) {
        return const SizedBox.shrink();
      }

      final controller = Get.isRegistered<DirectChatResolverController>()
          ? Get.find<DirectChatResolverController>()
          : Get.put(DirectChatResolverController());

      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      if (controller.error.value != null) {
        return Center(child: Text(controller.error.value!));
      }

      final keyboardInset = MediaQuery.of(context).viewInsets.bottom;
      return ChatScreen(
        chatId: controller.chatId!,
        partnerId: controller.partnerId!,
        partnerName: controller.partnerName!,
        partnerImage: controller.partnerImage,
        partnerPhone: controller.partnerPhone,
        keyboardInset: keyboardInset,
      );
    });
  }
}


class DirectChatResolverController extends GetxController {
  final SupabaseClient? _supabase;
  SupabaseClient get supabase => _supabase ?? Supabase.instance.client;

  DirectChatResolverController({SupabaseClient? supabase}) : _supabase = supabase;

  AuthController? get auth =>
      Get.isRegistered<AuthController>() ? Get.find<AuthController>() : null;

  final isLoading = true.obs;
  final error = RxnString();

  String? partnerName;
  String? partnerImage;
  String? partnerPhone;
  String? chatId;
  String? partnerId;

  @override
  void onInit() {
    super.onInit();
    resolve();
  }


  Future<void> resolve() async {
    final me = auth?.user.value;
    if (me == null) {
      error.value = "User not authenticated.";
      isLoading.value = false;
      return;
    }
    final myId = me.id;
    final cacheKey = CacheService.userKey(myId, 'direct_chat_info');

    // 1️⃣ Check local cache for immediate display
    final cached = CacheService.instance.get<Map<String, dynamic>>(
      cacheKey,
      fromJson: (json) => Map<String, dynamic>.from(json as Map),
    );

    if (cached != null) {
      final data = cached.data;
      partnerId = data['partnerId'];
      partnerName = data['partnerName'];
      partnerImage = data['partnerImage'];
      partnerPhone = data['partnerPhone'];
      chatId = data['chatId'];
      if (partnerId != null && chatId != null) {
        isLoading.value = false;
      }
    }

    try {
      // 2️⃣ Fetch care link
      final link = me.role == 'receiver'
          ? await supabase
          .from('care_links')
          .select('caregiver_id')
          .eq('receiver_id', myId)
          .maybeSingle()
          : await supabase
          .from('care_links')
          .select('receiver_id')
          .eq('caregiver_id', myId)
          .maybeSingle();

      if (link == null) {
        if (partnerId == null) {
          error.value = "No care partner linked yet.";
        }
        return;
      }

      // 3️⃣ SET partnerId FIRST
      partnerId = me.role == 'receiver'
          ? link['caregiver_id']
          : link['receiver_id'];

      // 4️⃣ Fetch partner user data
      final partner = await supabase
          .from('users')
          .select('full_name, profile_image, phone')
          .eq('id', partnerId!)
          .single();

      partnerName = partner['full_name'];
      partnerImage = partner['profile_image'];
      partnerPhone = partner['phone'];

      // 5️⃣ Find existing chat
      final existing = await supabase.rpc(
        'get_direct_chat',
        params: {
          'user_a': myId,
          'user_b': partnerId,
        },
      );

      if (existing != null && existing.isNotEmpty) {
        chatId = existing.first['chat_id'];
      } else {
        // 6️⃣ Create new chat if none exists
        final chat =
        await supabase.from('chats').insert({}).select().single();

        await supabase.from('chat_members').insert([
          {'chat_id': chat['id'], 'user_id': myId},
          {'chat_id': chat['id'], 'user_id': partnerId},
        ]);

        chatId = chat['id'];
      }

      // 7️⃣ Cache resolved direct chat information
      if (chatId != null && partnerId != null) {
        await CacheService.instance.set(cacheKey, {
          'partnerId': partnerId,
          'partnerName': partnerName,
          'partnerImage': partnerImage,
          'partnerPhone': partnerPhone,
          'chatId': chatId,
        });
      }
    } catch (e) {
      if (chatId == null) {
        error.value = e.toString();
      }
    } finally {
      isLoading.value = false;
    }
  }

}
