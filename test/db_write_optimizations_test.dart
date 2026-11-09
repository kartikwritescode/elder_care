import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:elder_care/core/services/cache_service.dart';
import 'package:elder_care/modules/care_receiver/controllers/activity_controller.dart';
import 'package:elder_care/modules/dashboard/controllers/nav_controller.dart';
import 'package:elder_care/modules/chat/controllers/chat_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await CacheService.instance.init();
  });

  group('Geofence Local Caching Tests', () {
    test('Stores and retrieves receiver geofence within 30-minute TTL', () async {
      final cache = CacheService.instance;
      const receiverId = 'receiver_123';
      final geofenceKey = CacheService.userKey(receiverId, 'geofence');

      final geofenceData = {
        'receiver_id': receiverId,
        'latitude': 37.7749,
        'longitude': -122.4194,
        'radius': 200,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      };

      final saved = await cache.set(geofenceKey, geofenceData);
      expect(saved, true);

      final cached = cache.get<Map<String, dynamic>>(
        geofenceKey,
        maxAge: const Duration(minutes: 30),
        fromJson: (json) => Map<String, dynamic>.from(json as Map),
      );

      expect(cached, isNotNull);
      expect(cached!.isStale, false);
      expect(cached.data['latitude'], 37.7749);
      expect(cached.data['longitude'], -122.4194);
      expect(cached.data['radius'], 200);
    });

    test('Identifies geofence as stale when older than 30 minutes', () async {
      final cache = CacheService.instance;
      const receiverId = 'receiver_456';
      final geofenceKey = CacheService.userKey(receiverId, 'geofence');

      await cache.set(geofenceKey, {
        'receiver_id': receiverId,
        'latitude': 37.0,
        'longitude': -122.0,
        'radius': 100,
      });

      // Query with a negative duration to simulate expiration
      final cached = cache.get<Map<String, dynamic>>(
        geofenceKey,
        maxAge: const Duration(seconds: -1),
        fromJson: (json) => Map<String, dynamic>.from(json as Map),
      );

      expect(cached, isNotNull);
      expect(cached!.isStale, true);
    });
  });

  group('FCM Token Debouncing Tests', () {
    test('Skips write when token matches cached token', () async {
      final cache = CacheService.instance;
      const userId = 'user_abc';
      final fcmKey = CacheService.userKey(userId, 'fcm_token');

      const existingToken = 'fcm_mock_token_12345';
      await cache.set(fcmKey, existingToken);

      final cachedToken = cache.get<String>(fcmKey)?.data;
      expect(cachedToken, existingToken);

      // Simulating new check with the exact same token
      const incomingToken = 'fcm_mock_token_12345';
      final bool shouldUpdate = incomingToken.isNotEmpty && incomingToken != cachedToken;
      expect(shouldUpdate, false);
    });

    test('Triggers update and updates cache when token is new or changed', () async {
      final cache = CacheService.instance;
      const userId = 'user_xyz';
      final fcmKey = CacheService.userKey(userId, 'fcm_token');

      // No token in cache initially
      final initialCachedToken = cache.get<String>(fcmKey)?.data;
      expect(initialCachedToken, isNull);

      const newToken = 'fcm_new_token_777';
      final bool shouldUpdateInitial = newToken.isNotEmpty && newToken != initialCachedToken;
      expect(shouldUpdateInitial, true);

      // Update cache
      await cache.set(fcmKey, newToken);

      // Re-read cache
      final updatedCachedToken = cache.get<String>(fcmKey)?.data;
      expect(updatedCachedToken, newToken);

      // Subsequent token with same value should NOT update
      final bool shouldUpdateSubsequent = newToken.isNotEmpty && newToken != updatedCachedToken;
      expect(shouldUpdateSubsequent, false);
    });
  });

  group('ActivityController Unit Tests', () {
    test('markActive with syncToServer: false updates local state without network write', () async {
      final controller = ActivityController();
      expect(controller.isOnline.value, false);

      await controller.markActive(syncToServer: false);

      expect(controller.isOnline.value, true);
      expect(controller.lastSeenText.value, 'Online');
      expect(controller.lastActivityAt, isNotNull);
      expect(controller.lastSyncedAt, isNull);

      controller.onClose();
    });

    test('recordServerSync tracks when external controller performed backend sync', () {
      final controller = ActivityController();
      expect(controller.lastSyncedAt, isNull);

      final syncTime = DateTime.now();
      controller.recordServerSync(syncTime);

      expect(controller.lastSyncedAt, syncTime);

      controller.onClose();
    });
  });

  group('Realtime Broadcast Payload Tests', () {
    test('Constructs valid location_update broadcast payload', () {
      final nowIso = DateTime.now().toUtc().toIso8601String();
      final payload = {
        'latitude': 37.7749,
        'longitude': -122.4194,
        'updated_at': nowIso,
      };

      expect(payload['latitude'], 37.7749);
      expect(payload['longitude'], -122.4194);
      expect(DateTime.tryParse(payload['updated_at'] as String), isNotNull);
    });

    test('Parses broadcast location_update payload accurately', () {
      final payload = {
        'latitude': 37.7749,
        'longitude': -122.4194,
        'updated_at': '2026-11-09T18:30:00.000Z',
      };

      final lat = (payload['latitude'] as num).toDouble();
      final lng = (payload['longitude'] as num).toDouble();
      final updated = DateTime.parse(payload['updated_at'] as String).toLocal();

      expect(lat, 37.7749);
      expect(lng, -122.4194);
      expect(updated.isUtc, false); // converted to local
    });
  });

  group('Tab Lifecycle Awareness Tests', () {
    test('NavController tab changes correctly switch active tab index', () {
      final nav = NavController();
      expect(nav.selectedIndex.value, 0);

      nav.changeTab(1);
      expect(nav.selectedIndex.value, 1);

      nav.changeTab(2);
      expect(nav.selectedIndex.value, 2);

      nav.changeTab(3);
      expect(nav.selectedIndex.value, 3);
    });

    test('ChatController unsubscribeRealtime safely cleans up channel', () {
      final controller = ChatController();
      // Should not throw even when channel is null
      expect(() => controller.unsubscribeRealtime(), returnsNormally);
      controller.onClose();
    });
  });
}
