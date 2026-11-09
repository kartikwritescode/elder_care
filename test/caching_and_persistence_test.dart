import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:elder_care/core/services/cache_service.dart';
import 'package:elder_care/core/services/app_image_cache_manager.dart';
import 'package:elder_care/app/widgets/app_cached_image.dart';
import 'package:elder_care/core/models/user_model.dart';
import 'package:elder_care/core/models/task_model.dart';
import 'package:elder_care/core/repositories/user_repository.dart';
import 'package:elder_care/core/repositories/task_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await CacheService.instance.init();
  });

  group('CacheService Unit Tests', () {
    test('Stores and retrieves typed data with timestamp', () async {
      final cache = CacheService.instance;
      const key = 'test_key';
      final testData = {'name': 'John Doe', 'age': 75};

      final setSuccess = await cache.set(key, testData);
      expect(setSuccess, true);

      final result = cache.get<Map<String, dynamic>>(
        key,
        fromJson: (json) => Map<String, dynamic>.from(json as Map),
      );

      expect(result, isNotNull);
      expect(result!.data['name'], 'John Doe');
      expect(result.data['age'], 75);
      expect(result.isStale, false);
      expect(result.timestamp, isNotNull);
    });

    test('isFresh accurately calculates freshness based on maxAge', () async {
      final cache = CacheService.instance;
      const key = 'fresh_key';
      await cache.set(key, 'value');

      expect(cache.isFresh(key, const Duration(minutes: 5)), true);
      expect(cache.isFresh(key, const Duration(seconds: -1)), false);
    });

    test('clearUserCache removes only keys associated with that user', () async {
      final cache = CacheService.instance;

      final userAKey1 = CacheService.userKey('user_A', 'profile');
      final userAKey2 = CacheService.userKey('user_A', 'tasks');
      final userBKey = CacheService.userKey('user_B', 'profile');

      await cache.set(userAKey1, {'name': 'User A'});
      await cache.set(userAKey2, [{'title': 'Take pill'}]);
      await cache.set(userBKey, {'name': 'User B'});

      expect(cache.get(userAKey1), isNotNull);
      expect(cache.get(userAKey2), isNotNull);
      expect(cache.get(userBKey), isNotNull);

      // Clear user A's cache (simulating logout of User A)
      await cache.clearUserCache('user_A');

      expect(cache.get(userAKey1), isNull);
      expect(cache.get(userAKey2), isNull);
      // User B's cache must remain untouched!
      expect(cache.get(userBKey), isNotNull);
    });
  });

  group('AppImageCacheManager Tests', () {
    test('getStableCacheKey strips volatile query parameters while keeping path', () {
      const signedUrl = 'https://example-bucket.supabase.co/storage/v1/object/sign/avatars/user_1.jpg?token=abc123&expires=9999999';
      final stableKey = AppImageCacheManager.getStableCacheKey(signedUrl);

      expect(stableKey, 'https://example-bucket.supabase.co/storage/v1/object/sign/avatars/user_1.jpg');
    });

    test('getStableCacheKey preserves plain URLs unchanged', () {
      const normalUrl = 'https://res.cloudinary.com/eldercare/image/upload/v12345/profile.png';
      final key = AppImageCacheManager.getStableCacheKey(normalUrl);

      expect(key, normalUrl);
    });

    test('getStableCacheKey handles empty string safely', () {
      expect(AppImageCacheManager.getStableCacheKey(''), '');
    });
  });

  group('Repository Layer Unit Tests', () {
    test('UserRepository loads cached user model when remote fetch fails or is not forced', () async {
      final cache = CacheService.instance;
      final cachedUser = UserModel(
        id: 'usr_offline',
        fullName: 'Mary Jane',
        role: 'receiver',
        careId: 'CARE-9999',
      );

      // Seed cache
      final repo = UserRepository(cache: cache);
      await repo.cacheUser(cachedUser);

      // Fetch without forcing remote (stale-while-revalidate / cache-first)
      final user = await repo.getUser('usr_offline');
      expect(user, isNotNull);
      expect(user!.fullName, 'Mary Jane');
      expect(user.careId, 'CARE-9999');
    });

    test('TaskRepository caches and retrieves tasks locally', () async {
      final cache = CacheService.instance;
      final repo = TaskRepository(cache: cache);

      const receiverId = 'rec_100';
      const key = 'cache:user:rec_100:tasks';

      final tasks = [
        const TaskModel(
          id: 1,
          receiverId: receiverId,
          title: 'Morning Medicine',
          taskType: 'medicine',
        ),
        const TaskModel(
          id: 2,
          receiverId: receiverId,
          title: 'Evening Walk',
          taskType: 'normal',
        ),
      ];

      await cache.set(key, tasks.map((t) => t.toMap()).toList());

      final cachedTasks = await repo.getTasks(receiverId);
      expect(cachedTasks.length, 2);
      expect(cachedTasks[0].title, 'Morning Medicine');
      expect(cachedTasks[1].title, 'Evening Walk');
    });
  });

  group('Widget Tests for AppCachedAvatar', () {
    testWidgets('Renders fallback icon when imageUrl is null', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppCachedAvatar(
              imageUrl: null,
              radius: 30,
              iconFallback: Icons.person,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.person), findsOneWidget);
    });

    testWidgets('Renders fallback icon when imageUrl is empty string', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppCachedAvatar(
              imageUrl: '',
              radius: 30,
              iconFallback: Icons.person,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.person), findsOneWidget);
    });
  });
}
