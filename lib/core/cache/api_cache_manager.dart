import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum CacheState { miss, fresh, stale }

class CacheReadResult {
  const CacheReadResult({required this.state, this.data, this.expiresAt});

  final CacheState state;
  final dynamic data;
  final DateTime? expiresAt;

  bool get hasData => data != null;
}

/// 全局 API JSON 缓存管理器 (支持 Web WASM 双端融合)
/// 架构定位：Core/Infrastructure Layer
class ApiCacheManager {
  static const String _boxName = 'app_api_cache_box';
  static const String _dataKey = 'data';
  static const String _cachedAtKey = 'cachedAt';
  static const String _expiresAtKey = 'expiresAt';
  static const Duration defaultTtl = Duration(minutes: 3);
  static Box? _box;
  static SharedPreferences? _prefs;

  /// 1. 初始化引擎
  static Future<void> init() async {
    if (kIsWeb) {
      //  Web 端 (WASM) 专用：完美避开 Hive 崩溃，使用 SP 替代
      _prefs = await SharedPreferences.getInstance();
      debugPrint(' [ApiCacheManager] Web SharedPreferences Cache Opened.');
    } else {
      //  手机端：继续使用高性能的 Hive
      try {
        await Hive.initFlutter();
        _box = await Hive.openBox(_boxName);
        debugPrint(' [ApiCacheManager] Hive Cache Box Opened.');
      } catch (e) {
        // 如果 Hive 初始化失败，回退到 SharedPreferences
        debugPrint(' [ApiCacheManager] Hive initialization failed: $e. Falling back to SharedPreferences.');
        _prefs = await SharedPreferences.getInstance();
        debugPrint(' [ApiCacheManager] Fallback to SharedPreferences Cache.');
      }
    }
  }

  /// 2. 写入缓存
  static Future<void> setCache(
    String key,
    dynamic data, {
    Duration ttl = defaultTtl,
  }) async {
    try {
      final String jsonString = jsonEncode(buildCacheEnvelope(data, ttl: ttl));
      if (_prefs != null) {
        // Use SharedPreferences for web or fallback
        await _prefs?.setString('${_boxName}_$key', jsonString);
      } else {
        // Use Hive for mobile
        await _box?.put(key, jsonString);
      }
    } catch (e) {
      debugPrint(' [ApiCacheManager] Set Cache Error: $e');
    }
  }

  /// 3. 读取缓存 (极速瞬间返回)
  static dynamic getCache(String key) {
    final entry = getCacheEntry(key);
    return entry.data;
  }

  /// 3.1 读取缓存并返回 freshness（SWR 用）
  static CacheReadResult getCacheEntry(
    String key, {
    Duration legacyFallbackTtl = defaultTtl,
  }) {
    try {
      final String? jsonString = _prefs != null
          ? _prefs?.getString('${_boxName}_$key')
          : _box?.get(key);

      if (jsonString != null && jsonString.isNotEmpty) {
        final dynamic decoded = jsonDecode(jsonString);
        return parseCachedPayload(decoded, fallbackTtl: legacyFallbackTtl);
      }
      return const CacheReadResult(state: CacheState.miss);
    } catch (e) {
      debugPrint(' [ApiCacheManager] Get Cache Error: $e');
      return const CacheReadResult(state: CacheState.miss);
    }
  }

  @visibleForTesting
  static Map<String, dynamic> buildCacheEnvelope(
    dynamic data, {
    required Duration ttl,
    DateTime? now,
  }) {
    final ts = (now ?? DateTime.now()).millisecondsSinceEpoch;
    return {
      _dataKey: data,
      _cachedAtKey: ts,
      _expiresAtKey: ts + ttl.inMilliseconds,
    };
  }

  @visibleForTesting
  static CacheReadResult parseCachedPayload(
    dynamic decoded, {
    required Duration fallbackTtl,
    DateTime? now,
  }) {
    final current = now ?? DateTime.now();
    if (decoded is Map<String, dynamic> && decoded.containsKey(_dataKey)) {
      final expiresAtRaw = decoded[_expiresAtKey];
      final expiresAt = expiresAtRaw is int
          ? DateTime.fromMillisecondsSinceEpoch(expiresAtRaw)
          : null;
      final isFresh = expiresAt != null && current.isBefore(expiresAt);
      return CacheReadResult(
        state: isFresh ? CacheState.fresh : CacheState.stale,
        data: decoded[_dataKey],
        expiresAt: expiresAt,
      );
    }

    // Legacy payloads without envelope are treated as stale once discovered.
    return CacheReadResult(
      state: CacheState.stale,
      data: decoded,
      expiresAt: current.subtract(fallbackTtl),
    );
  }

  /// 4. 清理特定缓存
  static Future<void> removeCache(String key) async {
    if (_prefs != null) {
      await _prefs?.remove('${_boxName}_$key');
    } else {
      await _box?.delete(key);
    }
  }

  /// 5. 清空所有接口缓存 (退出登录时调用)
  static Future<void> clearAll() async {
    if (_prefs != null) {
      // Web 端：只清除 API 相关的 keys，绝不影响用户登录状态 (Token)
      final keys = _prefs?.getKeys() ?? {};
      for (String key in keys) {
        if (key.startsWith(_boxName)) {
          await _prefs?.remove(key);
        }
      }
    } else {
      await _box?.clear();
    }
  }
}
