import 'dart:async';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ActivityController extends GetxController {
  final SupabaseClient? _supabase;
  SupabaseClient get supabase => _supabase ?? Supabase.instance.client;

  ActivityController({SupabaseClient? supabase}) : _supabase = supabase;

  // CONFIG
  static const Duration onlineThreshold = Duration(minutes: 3);
  static const Duration watcherInterval = Duration(seconds: 30);
  static const Duration minSyncInterval = Duration(minutes: 2);

  // STATE
  final RxBool isOnline = false.obs;
  final RxString lastSeenText = ''.obs;

  DateTime? _lastActivityAt;
  DateTime? get lastActivityAt => _lastActivityAt;
  DateTime? _lastSyncedAt;
  DateTime? get lastSyncedAt => _lastSyncedAt;
  Timer? _watcher;

  @override
  void onInit() {
    super.onInit();
    _startWatcher();
  }

  @override
  void onClose() {
    _watcher?.cancel();
    super.onClose();
  }

  /// Inform the controller that a server sync was performed externally (e.g. combined with location update)
  void recordServerSync([DateTime? at]) {
    _lastSyncedAt = at ?? DateTime.now();
  }

  // 🔥 CALL THIS ON ANY ACTIVITY
  Future<void> markActive({bool syncToServer = true}) async {
    final now = DateTime.now();

    _lastActivityAt = now;
    isOnline.value = true;
    lastSeenText.value = 'Online';

    if (syncToServer) {
      if (_lastSyncedAt == null ||
          now.difference(_lastSyncedAt!) >= minSyncInterval) {
        _lastSyncedAt = now;
        await _syncToSupabase(now);
      }
    }
  }

  // CAREGIVER SIDE (fetch receiver activity)
  Future<void> hydrateFromServer(String receiverId) async {
    try {
      final res = await supabase
          .from('user_locations')
          .select('last_activity_at')
          .eq('user_id', receiverId)
          .maybeSingle();

      if (res == null) {
        isOnline.value = false;
        lastSeenText.value = 'Offline';
        return;
      }

      final rawTime = res['last_activity_at']?.toString();
      if (rawTime == null || rawTime.isEmpty) {
        isOnline.value = false;
        lastSeenText.value = 'Offline';
        return;
      }

      final last = DateTime.parse(rawTime.endsWith('Z') ? rawTime : '${rawTime}Z').toLocal();
      _lastActivityAt = last;
      _recompute();
    } catch (_) {
      isOnline.value = false;
      lastSeenText.value = 'Offline';
    }
  }

  // INTERNAL
  void _startWatcher() {
    _watcher = Timer.periodic(watcherInterval, (_) => _recompute());
  }

  void _recompute() {
    if (_lastActivityAt == null) {
      isOnline.value = false;
      lastSeenText.value = 'Inactive';
      return;
    }

    final diff = DateTime.now().difference(_lastActivityAt!);

    if (diff <= onlineThreshold) {
      isOnline.value = true;
      lastSeenText.value = 'Connected';
    } else {
      isOnline.value = false;

      if (diff.inMinutes < 60) {
        lastSeenText.value = 'Last seen ${diff.inMinutes} min ago';
      } else if (diff.inHours < 24) {
        lastSeenText.value = 'Last seen ${diff.inHours} hr ago';
      } else {
        lastSeenText.value = 'Last seen ${diff.inDays} days ago';
      }
    }
  }

  Future<void> _syncToSupabase(DateTime at) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      await supabase.from('user_locations').upsert({
        'user_id': user.id,
        'last_activity_at': at.toUtc().toIso8601String(),
      }, onConflict: 'user_id');
    } catch (_) {}
  }
}
