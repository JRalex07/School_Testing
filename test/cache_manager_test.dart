import 'package:flutter_test/flutter_test.dart';
import 'package:schooltesting/core/cache/cache_manager.dart';

void main() {
  group('CacheManager & CacheKeys Tests (Rules 6, 10, 11, 12)', () {
    late CacheManager cache;

    setUp(() {
      cache = CacheManager();
      cache.clearAll();
    });

    tearDown(() {
      cache.clearAll();
    });

    test('Cache set and get with hit/miss', () {
      expect(cache.get<String>('user:101:profile'), isNull);

      cache.set('user:101:profile', 'Profile Data');
      expect(cache.get<String>('user:101:profile'), 'Profile Data');
    });

    test('Cache respects TTL expiration', () async {
      cache.set(
        'temp_data',
        'value',
        ttl: const Duration(milliseconds: 50),
      );
      expect(cache.get<String>('temp_data'), 'value');

      await Future.delayed(const Duration(milliseconds: 60));
      expect(cache.get<String>('temp_data'), isNull);
    });

    test('Cache invalidation by key', () {
      cache.set('key1', 'val1');
      cache.set('key2', 'val2');

      cache.invalidate('key1');
      expect(cache.get<String>('key1'), isNull);
      expect(cache.get<String>('key2'), 'val2');
    });

    test('Cache invalidation by scope tag (Rule 10)', () {
      cache.set('key_std_1', 'std1_data', scopeTag: 'class_6_A');
      cache.set('key_std_2', 'std2_data', scopeTag: 'class_6_A');
      cache.set('key_std_3', 'std3_data', scopeTag: 'class_7_B');

      expect(cache.get<String>('key_std_1'), 'std1_data');
      expect(cache.get<String>('key_std_3'), 'std3_data');

      // Mutate Class 6-A -> Invalidate tag
      cache.invalidateTag('class_6_A');

      expect(cache.get<String>('key_std_1'), isNull);
      expect(cache.get<String>('key_std_2'), isNull);
      expect(cache.get<String>('key_std_3'), 'std3_data');
    });

    test('Cache clearing on user logout (Rule 12)', () {
      cache.set('user:u1:profile', 'profile1');
      cache.set('parent:u1:children', ['child1']);
      cache.set('user:u2:profile', 'profile2');

      cache.clearForUser('u1');

      expect(cache.get<String>('user:u1:profile'), isNull);
      expect(cache.get<List<String>>('parent:u1:children'), isNull);
      expect(cache.get<String>('user:u2:profile'), 'profile2');
    });

    test('CacheKeys standard formatted strings enforce scope boundaries', () {
      expect(CacheKeys.userProfile('usr_1'), 'user:usr_1:profile');
      expect(
        CacheKeys.teacherAssignments('tch_1'),
        'teacher:tch_1:assignments',
      );
      expect(
        CacheKeys.teacherClassStudents('tch_1', '6', 'A'),
        'teacher:tch_1:class:6_A:students',
      );
      expect(
        CacheKeys.classAttendance('6', 'A', DateTime(2026, 11, 15)),
        'attendance:6_A:2026_11_15',
      );
      expect(CacheKeys.parentChildren('p_1'), 'parent:p_1:children');
      expect(CacheKeys.studentFees('std_1'), 'student:std_1:fees');
      expect(CacheKeys.schoolFeeMetrics('mps_1'), 'school:mps_1:fee_metrics');
    });
  });
}
