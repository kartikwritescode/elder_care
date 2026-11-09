import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// Centralized CacheManager for ElderCare remote images.
/// Configures bounded storage (max 150 objects, 14 days retention) to prevent
/// unbounded disk consumption on elderly devices.
class AppImageCacheManager {
  static const String key = 'eldercare_image_cache';

  static final CacheManager instance = CacheManager(
    Config(
      key,
      stalePeriod: const Duration(days: 14),
      maxNrOfCacheObjects: 150,
      repo: JsonCacheInfoRepository(databaseName: key),
      fileService: HttpFileService(),
    ),
  );

  /// Clears the entire disk cache for remote images (e.g., during full reset).
  static Future<void> emptyCache() async {
    try {
      await instance.emptyCache();
    } catch (_) {}
  }

  /// Removes a specific URL from cache if updated.
  static Future<void> evictUrl(String url) async {
    try {
      final cacheKey = getStableCacheKey(url);
      await instance.removeFile(cacheKey);
    } catch (_) {}
  }

  /// Generates a stable cache key by stripping volatile query parameters
  /// from signed URLs while keeping the base asset path.
  static String getStableCacheKey(String url) {
    if (url.isEmpty) return '';
    try {
      final uri = Uri.parse(url);
      if (uri.hasQuery) {
        // Strip out volatile expiry query params if it's a signed storage url
        // but preserve the path
        return '${uri.origin}${uri.path}';
      }
    } catch (_) {}
    return url;
  }
}
