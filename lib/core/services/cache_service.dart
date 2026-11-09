import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Lightweight, production-grade local data persistence service.
/// Uses SharedPreferences with user-scoped namespacing and metadata
/// (timestamps and TTL) to prevent cross-account data leaks and stale data.
class CacheService {
  static CacheService? _instance;
  static CacheService get instance => _instance ??= CacheService._();

  SharedPreferences? _prefs;

  CacheService._();

  /// Initialize SharedPreferences instance.
  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// Ensure prefs is initialized before access.
  SharedPreferences get prefs {
    if (_prefs == null) {
      throw StateError("CacheService must be initialized before access. Call await CacheService.instance.init()");
    }
    return _prefs!;
  }

  /// Builds a user-partitioned key to prevent data leakage between accounts.
  static String userKey(String? userId, String collection) {
    final uid = (userId != null && userId.isNotEmpty) ? userId : 'anonymous';
    return 'cache:user:$uid:$collection';
  }

  /// Store raw JSON-serializable object with timestamp metadata.
  Future<bool> set(String key, dynamic data) async {
    try {
      final payload = {
        'timestamp': DateTime.now().toUtc().toIso8601String(),
        'data': data,
      };
      final jsonString = jsonEncode(payload);
      return await prefs.setString(key, jsonString);
    } catch (e) {
      debugPrint('[CacheService] Error setting key $key: $e');
      return false;
    }
  }

  /// Retrieve cached data with timestamp and stale check.
  CachedResult<T>? get<T>(
    String key, {
    Duration? maxAge,
    T Function(dynamic json)? fromJson,
  }) {
    try {
      final jsonString = prefs.getString(key);
      if (jsonString == null || jsonString.isEmpty) return null;

      final Map<String, dynamic> decoded = jsonDecode(jsonString);
      final timestampStr = decoded['timestamp'] as String?;
      final timestamp = timestampStr != null ? DateTime.parse(timestampStr).toLocal() : DateTime.now();

      final rawData = decoded['data'];
      final isStale = maxAge != null && DateTime.now().difference(timestamp) > maxAge;

      T parsedData;
      if (fromJson != null) {
        parsedData = fromJson(rawData);
      } else {
        parsedData = rawData as T;
      }

      return CachedResult<T>(
        data: parsedData,
        timestamp: timestamp,
        isStale: isStale,
      );
    } catch (e) {
      debugPrint('[CacheService] Error getting key $key: $e');
      return null;
    }
  }

  /// Checks if a key has valid cached data that is not older than [maxAge].
  bool isFresh(String key, Duration maxAge) {
    try {
      final jsonString = prefs.getString(key);
      if (jsonString == null) return false;
      final Map<String, dynamic> decoded = jsonDecode(jsonString);
      final timestampStr = decoded['timestamp'] as String?;
      if (timestampStr == null) return false;
      final timestamp = DateTime.parse(timestampStr).toLocal();
      return DateTime.now().difference(timestamp) <= maxAge;
    } catch (_) {
      return false;
    }
  }

  /// Returns the saved timestamp for a given key.
  DateTime? getTimestamp(String key) {
    try {
      final jsonString = prefs.getString(key);
      if (jsonString == null) return null;
      final Map<String, dynamic> decoded = jsonDecode(jsonString);
      final timestampStr = decoded['timestamp'] as String?;
      if (timestampStr == null) return null;
      return DateTime.parse(timestampStr).toLocal();
    } catch (_) {
      return null;
    }
  }

  /// Remove a specific key from cache.
  Future<bool> remove(String key) async {
    return await prefs.remove(key);
  }

  /// Clears all keys scoped to a specific user (called on logout or account switch).
  Future<void> clearUserCache(String? userId) async {
    if (userId == null || userId.isEmpty) return;
    try {
      final prefix = 'cache:user:$userId:';
      final keys = prefs.getKeys();
      for (final key in keys) {
        if (key.startsWith(prefix)) {
          await prefs.remove(key);
        }
      }
      debugPrint('[CacheService] Cleared user cache for: $userId');
    } catch (e) {
      debugPrint('[CacheService] Error clearing user cache: $e');
    }
  }

  /// Completely clears all cache keys.
  Future<void> clearAll() async {
    try {
      final keys = prefs.getKeys();
      for (final key in keys) {
        if (key.startsWith('cache:')) {
          await prefs.remove(key);
        }
      }
    } catch (_) {}
  }
}

/// Represents a cached item along with freshness metadata.
class CachedResult<T> {
  final T data;
  final DateTime timestamp;
  final bool isStale;

  const CachedResult({
    required this.data,
    required this.timestamp,
    required this.isStale,
  });
}
