import 'package:flutter/foundation.dart';

/// 简化版OAuth状态管理器
/// 只用于临时存储ID Token，避免页面销毁时丢失
class OAuthStateManager {
  OAuthStateManager._();

  static String? _currentIdToken;
  static String? _currentProvider;
  static DateTime? _lastUpdateTime;

  /// 保存ID Token
  static void saveIdToken(String provider, String idToken) {
    _currentProvider = provider;
    _currentIdToken = idToken;
    _lastUpdateTime = DateTime.now();
    debugPrint('[OAuthStateManager] Saved idToken for $provider (length=${idToken.length})');
  }

  /// 获取保存的ID Token
  static String? getIdToken(String provider) {
    if (_currentProvider == provider && _currentIdToken != null) {
      // 检查是否过期（5分钟内有效）
      if (_lastUpdateTime != null && 
          DateTime.now().difference(_lastUpdateTime!) < const Duration(minutes: 5)) {
        debugPrint('[OAuthStateManager] Returning saved idToken for $provider');
        return _currentIdToken;
      } else {
        debugPrint('[OAuthStateManager] Saved idToken for $provider has expired');
        clear();
      }
    }
    return null;
  }

  /// 清理保存的状态
  static void clear() {
    _currentIdToken = null;
    _currentProvider = null;
    _lastUpdateTime = null;
    debugPrint('[OAuthStateManager] Cleared all state');
  }

  /// 检查是否有指定provider的未过期ID Token
  static bool hasValidIdToken(String provider) {
    return getIdToken(provider) != null;
  }
}
