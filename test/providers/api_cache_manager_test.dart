import 'package:flutter_app/core/cache/api_cache_manager.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ApiCacheManager cache envelope', () {
    test('marks envelope as fresh before expiresAt', () {
      final now = DateTime(2026, 3, 21, 10, 0, 0);
      final envelope = ApiCacheManager.buildCacheEnvelope(
        {'value': 1},
        ttl: const Duration(minutes: 1),
        now: now,
      );

      final result = ApiCacheManager.parseCachedPayload(
        envelope,
        fallbackTtl: const Duration(minutes: 1),
        now: now.add(const Duration(seconds: 30)),
      );

      expect(result.state, CacheState.fresh);
      expect(result.data, {'value': 1});
    });

    test('marks envelope as stale after expiresAt', () {
      final now = DateTime(2026, 3, 21, 10, 0, 0);
      final envelope = ApiCacheManager.buildCacheEnvelope(
        {'value': 1},
        ttl: const Duration(seconds: 10),
        now: now,
      );

      final result = ApiCacheManager.parseCachedPayload(
        envelope,
        fallbackTtl: const Duration(minutes: 1),
        now: now.add(const Duration(seconds: 15)),
      );

      expect(result.state, CacheState.stale);
      expect(result.data, {'value': 1});
    });

    test('treats legacy payload as stale for immediate revalidation', () {
      final result = ApiCacheManager.parseCachedPayload(
        {'legacy': true},
        fallbackTtl: const Duration(minutes: 1),
        now: DateTime(2026, 3, 21, 10, 0, 0),
      );

      expect(result.state, CacheState.stale);
      expect(result.data, {'legacy': true});
    });
  });
}
