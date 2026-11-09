import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/task_model.dart';
import '../services/cache_service.dart';

/// Repository for Tasks and Medication schedules.
/// Implements stale-while-revalidate persistence to support offline and poor-network viewing.
class TaskRepository {
  final SupabaseClient? _supabase;
  final CacheService _cache;

  TaskRepository({
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

  String _cacheKey(String receiverId) => CacheService.userKey(receiverId, 'tasks');

  /// Fetches tasks with stale-while-revalidate strategy.
  /// Returns cached tasks immediately if available, then updates when network response arrives.
  Future<List<TaskModel>> getTasks(
    String receiverId, {
    bool forceRemote = false,
    Duration maxAge = const Duration(minutes: 5),
    void Function(List<TaskModel> cached)? onCacheLoaded,
  }) async {
    final key = _cacheKey(receiverId);

    // 1. Read cached tasks
    final cached = _cache.get<List<TaskModel>>(
      key,
      maxAge: maxAge,
      fromJson: (jsonList) {
        if (jsonList is! List) return <TaskModel>[];
        return jsonList
            .map((e) => TaskModel.fromMap(Map<String, dynamic>.from(e as Map)))
            .toList();
      },
    );

    if (cached != null) {
      if (onCacheLoaded != null) {
        onCacheLoaded(cached.data);
      }
      if (!cached.isStale && !forceRemote) {
        debugPrint('📋 [TaskRepository] Returning fresh cached tasks (${cached.data.length})');
        return cached.data;
      }
    }

    // 2. Fetch fresh from Supabase
    if (_supabase == null) {
      return cached?.data ?? [];
    }

    try {
      debugPrint('🌐 [TaskRepository] Fetching remote tasks for receiver: $receiverId');
      final res = await _supabase
          .from('tasks')
          .select()
          .eq('receiver_id', receiverId)
          .or('repeat_type.neq.none,is_completed.eq.false')
          .order('datetime', ascending: true)
          .limit(100);

      final list = (res as List)
          .map((e) => TaskModel.fromMap(Map<String, dynamic>.from(e)))
          .toList();

      // 3. Persist to cache
      await _cache.set(key, list.map((t) => t.toMap()).toList());
      return list;
    } catch (e) {
      debugPrint('⚠️ [TaskRepository] Remote tasks fetch failed ($e). Using cached data.');
      // 4. Return cached tasks if available
      if (cached != null) {
        return cached.data;
      }
      return [];
    }
  }

  /// Adds a task to Supabase and immediately updates local cache.
  Future<TaskModel?> createTask(TaskModel model) async {
    if (_supabase == null) return null;
    try {
      final res = await _supabase.from('tasks').insert(model.toMap()).select().limit(1);
      if (res.isNotEmpty) {
        final created = TaskModel.fromMap(Map<String, dynamic>.from(res.first));

        // Update local cache
        final key = _cacheKey(model.receiverId);
        final currentCached = _cache.get<List<TaskModel>>(
          key,
          fromJson: (list) => (list as List)
              .map((e) => TaskModel.fromMap(Map<String, dynamic>.from(e as Map)))
              .toList(),
        );

        final updatedList = currentCached?.data != null ? List<TaskModel>.from(currentCached!.data) : <TaskModel>[];
        updatedList.add(created);
        await _cache.set(key, updatedList.map((t) => t.toMap()).toList());

        return created;
      }
    } catch (e) {
      debugPrint('❌ [TaskRepository] createTask error: $e');
    }
    return null;
  }

  /// Updates an existing task on Supabase and updates local cache.
  Future<TaskModel?> updateTask(int taskId, TaskModel model) async {
    if (_supabase == null) return null;
    try {
      final res = await _supabase.from('tasks').update(model.toUpdateMap()).eq('id', taskId).select().limit(1);
      if (res.isNotEmpty) {
        final updated = TaskModel.fromMap(Map<String, dynamic>.from(res.first));

        // Update local cache
        final key = _cacheKey(model.receiverId);
        final currentCached = _cache.get<List<TaskModel>>(
          key,
          fromJson: (list) => (list as List)
              .map((e) => TaskModel.fromMap(Map<String, dynamic>.from(e as Map)))
              .toList(),
        );

        if (currentCached != null) {
          final list = List<TaskModel>.from(currentCached.data);
          final idx = list.indexWhere((t) => t.id == taskId);
          if (idx != -1) {
            list[idx] = updated;
          } else {
            list.add(updated);
          }
          await _cache.set(key, list.map((t) => t.toMap()).toList());
        }

        return updated;
      }
    } catch (e) {
      debugPrint('❌ [TaskRepository] updateTask error: $e');
    }
    return null;
  }

  /// Deletes a task from Supabase and removes it from the local cache.
  Future<bool> deleteTask(int taskId, String receiverId) async {
    try {
      if (_supabase != null) {
        await _supabase.from('tasks').delete().eq('id', taskId);
      }

      final key = _cacheKey(receiverId);
      final currentCached = _cache.get<List<TaskModel>>(
        key,
        fromJson: (list) => (list as List)
            .map((e) => TaskModel.fromMap(Map<String, dynamic>.from(e as Map)))
            .toList(),
      );

      if (currentCached != null) {
        final list = List<TaskModel>.from(currentCached.data);
        list.removeWhere((t) => t.id == taskId);
        await _cache.set(key, list.map((t) => t.toMap()).toList());
      }
      return true;
    } catch (e) {
      debugPrint('❌ [TaskRepository] deleteTask error: $e');
      return false;
    }
  }

  /// Clears tasks cache for receiver.
  Future<void> clearCache(String receiverId) async {
    await _cache.remove(_cacheKey(receiverId));
  }
}
