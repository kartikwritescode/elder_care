import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import '../services/cache_service.dart';

/// Repository for User Profile metadata with local caching and offline recovery.
class UserRepository {
  final SupabaseClient? _supabase;
  final CacheService _cache;

  UserRepository({
    SupabaseClient? supabase,
    CacheService? cache,
  })  : _supabase = supabase ?? _safeClient(),
        _cache = cache ?? CacheService.instance;

  static SupabaseClient? _safeClient() {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  /// Fetches the user model using a cache-first or stale-while-revalidate strategy.
  /// If offline, returns previously cached profile data gracefully.
  Future<UserModel?> getUser(
    String userId, {
    bool forceRemote = false,
    Duration maxAge = const Duration(hours: 1),
  }) async {
    final cacheKey = CacheService.userKey(userId, 'profile');

    // 1. Check local cache
    final cached = _cache.get<UserModel>(
      cacheKey,
      maxAge: maxAge,
      fromJson: (json) => UserModel.fromJson(Map<String, dynamic>.from(json)),
    );

    // If cache is fresh and forceRemote is not requested, return immediately
    if (cached != null && !cached.isStale && !forceRemote) {
      debugPrint('👤 [UserRepository] Returning fresh cached user profile for $userId');
      return cached.data;
    }

    // 2. Fetch fresh data from Supabase
    if (_supabase == null) {
      return cached?.data;
    }

    try {
      debugPrint('🌐 [UserRepository] Fetching remote user profile for $userId');
      final res = await _supabase.from('users').select().eq('id', userId).single();
      final freshUser = UserModel.fromJson(Map<String, dynamic>.from(res));

      // 3. Update local cache
      await _cache.set(cacheKey, freshUser.toJson());
      return freshUser;
    } catch (e) {
      debugPrint('⚠️ [UserRepository] Remote fetch failed ($e). Falling back to cache.');
      // 4. Fallback to cached data (even if stale) if network fails
      if (cached != null) {
        return cached.data;
      }
      return null;
    }
  }

  /// Caches a user model directly into local storage.
  Future<void> cacheUser(UserModel user) async {
    final cacheKey = CacheService.userKey(user.id, 'profile');
    await _cache.set(cacheKey, user.toJson());
  }

  /// Updates user profile on Supabase and updates the local cache.
  Future<bool> updateUser(String userId, Map<String, dynamic> data) async {
    try {
      if (_supabase != null) {
        await _supabase.from('users').update(data).eq('id', userId);
      }

      // Refresh cache with updated data
      final cacheKey = CacheService.userKey(userId, 'profile');
      final cached = _cache.get<UserModel>(
        cacheKey,
        fromJson: (json) => UserModel.fromJson(Map<String, dynamic>.from(json)),
      );

      if (cached != null) {
        final currentMap = cached.data.toJson();
        currentMap.addAll(data);
        await _cache.set(cacheKey, currentMap);
      }
      return true;
    } catch (e) {
      debugPrint('❌ [UserRepository] updateUser error: $e');
      return false;
    }
  }

  /// Clears user profile from cache.
  Future<void> clearUser(String userId) async {
    await _cache.clearUserCache(userId);
  }
}
