import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/event_model.dart';
import '../services/cache_service.dart';

/// Repository for Events and Appointments.
/// Implements stale-while-revalidate persistence to support offline and poor-network viewing.
class EventRepository {
  final SupabaseClient? _supabase;
  final CacheService _cache;

  EventRepository({
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

  String _cacheKey(String receiverId) => CacheService.userKey(receiverId, 'events');

  /// Fetches events with stale-while-revalidate strategy.
  Future<List<EventModel>> getEvents(
    String receiverId, {
    bool forceRemote = false,
    Duration maxAge = const Duration(minutes: 5),
    void Function(List<EventModel> cached)? onCacheLoaded,
  }) async {
    final key = _cacheKey(receiverId);

    // 1. Read cached events
    final cached = _cache.get<List<EventModel>>(
      key,
      maxAge: maxAge,
      fromJson: (jsonList) {
        if (jsonList is! List) return <EventModel>[];
        return jsonList
            .map((e) => EventModel.fromMap(Map<String, dynamic>.from(e as Map)))
            .toList();
      },
    );

    if (cached != null) {
      if (onCacheLoaded != null) {
        onCacheLoaded(cached.data);
      }
      if (!cached.isStale && !forceRemote) {
        debugPrint('📅 [EventRepository] Returning fresh cached events (${cached.data.length})');
        return cached.data;
      }
    }

    // 2. Fetch fresh from Supabase
    if (_supabase == null) {
      return cached?.data ?? [];
    }

    try {
      debugPrint('🌐 [EventRepository] Fetching remote events for receiver: $receiverId');
      final res = await _supabase
          .from('events')
          .select()
          .eq('receiver_id', receiverId)
          .order('event_time', ascending: true);

      final list = (res as List)
          .map((e) => EventModel.fromMap(Map<String, dynamic>.from(e)))
          .toList();

      // 3. Persist to cache
      await _cache.set(key, list.map((e) => e.toMap()).toList());
      return list;
    } catch (e) {
      debugPrint('⚠️ [EventRepository] Remote events fetch failed ($e). Using cached data.');
      if (cached != null) {
        return cached.data;
      }
      return [];
    }
  }

  /// Creates a new event in Supabase and updates local cache.
  Future<EventModel?> createEvent(EventModel event) async {
    if (_supabase == null) return null;
    try {
      final res = await _supabase.from('events').insert(event.toMap()).select().single();
      final created = EventModel.fromMap(Map<String, dynamic>.from(res));

      final key = _cacheKey(event.receiverId);
      final currentCached = _cache.get<List<EventModel>>(
        key,
        fromJson: (list) => (list as List)
            .map((e) => EventModel.fromMap(Map<String, dynamic>.from(e as Map)))
            .toList(),
      );

      final list = currentCached?.data != null ? List<EventModel>.from(currentCached!.data) : <EventModel>[];
      list.add(created);
      list.sort((a, b) => a.eventTime.compareTo(b.eventTime));
      await _cache.set(key, list.map((e) => e.toMap()).toList());

      return created;
    } catch (e) {
      debugPrint('❌ [EventRepository] createEvent error: $e');
    }
    return null;
  }

  /// Updates an existing event in Supabase and updates local cache.
  Future<EventModel?> updateEvent(EventModel event) async {
    if (event.id == null || _supabase == null) return null;
    try {
      final res = await _supabase
          .from('events')
          .update({
            'title': event.title,
            'event_time': event.eventTime.toIso8601String(),
            'category': event.category,
            'notes': event.notes,
          })
          .eq('id', event.id!)
          .select()
          .maybeSingle();

      if (res != null) {
        final updated = EventModel.fromMap(Map<String, dynamic>.from(res));

        final key = _cacheKey(event.receiverId);
        final currentCached = _cache.get<List<EventModel>>(
          key,
          fromJson: (list) => (list as List)
              .map((e) => EventModel.fromMap(Map<String, dynamic>.from(e as Map)))
              .toList(),
        );

        if (currentCached != null) {
          final list = List<EventModel>.from(currentCached.data);
          final idx = list.indexWhere((e) => e.id == event.id);
          if (idx != -1) {
            list[idx] = updated;
          } else {
            list.add(updated);
          }
          list.sort((a, b) => a.eventTime.compareTo(b.eventTime));
          await _cache.set(key, list.map((e) => e.toMap()).toList());
        }

        return updated;
      }
    } catch (e) {
      debugPrint('❌ [EventRepository] updateEvent error: $e');
    }
    return null;
  }

  /// Deletes an event from Supabase and removes it from local cache.
  Future<bool> deleteEvent(int id, String receiverId) async {
    try {
      if (_supabase != null) {
        await _supabase.from('events').delete().eq('id', id);
      }

      final key = _cacheKey(receiverId);
      final currentCached = _cache.get<List<EventModel>>(
        key,
        fromJson: (list) => (list as List)
            .map((e) => EventModel.fromMap(Map<String, dynamic>.from(e as Map)))
            .toList(),
      );

      if (currentCached != null) {
        final list = List<EventModel>.from(currentCached.data);
        list.removeWhere((e) => e.id == id);
        await _cache.set(key, list.map((e) => e.toMap()).toList());
      }
      return true;
    } catch (e) {
      debugPrint('❌ [EventRepository] deleteEvent error: $e');
      return false;
    }
  }

  /// Clears events cache for receiver.
  Future<void> clearCache(String receiverId) async {
    await _cache.remove(_cacheKey(receiverId));
  }
}
