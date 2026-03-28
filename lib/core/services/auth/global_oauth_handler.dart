import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/routes/app_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/global_loading_provider.dart';
import '../../store/auth/auth_provider.dart';
import '../auth/oauth_state_manager.dart';

/// 全局OAuth处理器 - 不依赖页面状态，处理所有OAuth回调
/// 解决Native端OAuth登录页面销毁后context无效的问题
class GlobalOAuthHandler {
  GlobalOAuthHandler._();

  // 全局ProviderContainer引用（从main.dart注入）
  static late ProviderContainer _globalContainer;
  
  // 是否已初始化
  static bool _initialized = false;

  /// 初始化全局处理器
  static void initialize(ProviderContainer container) {
    _globalContainer = container;
    _initialized = true;
    debugPrint('[GlobalOAuthHandler] Initialized with global container');
  }

  /// 检查是否已初始化
  static bool get isInitialized => _initialized;

  /// 获取全局容器（安全访问）
  static ProviderContainer get container {
    if (!_initialized) {
      throw StateError('GlobalOAuthHandler not initialized. Call initialize() first.');
    }
    return _globalContainer;
  }

  /// 处理Google OAuth回调
  /// 可以从任何地方调用，不依赖页面context
  static Future<void> handleGoogleOAuthCallback({
    required String idToken,
    String? inviteCode,
  }) async {
    if (!_initialized) {
      debugPrint('[GlobalOAuthHandler] Not initialized, cannot handle OAuth callback');
      return;
    }

    // 显示全局loading
    _globalContainer.read(globalLoadingProvider.notifier).state = true;
    debugPrint('[GlobalOAuthHandler] Showing global loading for OAuth process');

    try {
      debugPrint('[GlobalOAuthHandler] Handling Google OAuth callback with idToken (length=${idToken.length})');
      
      // 保存ID Token到全局状态管理器（用于状态恢复）
      OAuthStateManager.saveIdToken('google', idToken);
      
      // 调用后端API验证ID Token
      final result = await _globalContainer.read(authLoginGoogleCtrlProvider.notifier).run((
        idToken: idToken,
        inviteCode: inviteCode,
      ));

      debugPrint('[GlobalOAuthHandler] Backend API call successful');
      
      // 同步token到全局auth provider
      final auth = _globalContainer.read(authProvider.notifier);
      await auth.login(result.tokens.accessToken, result.tokens.refreshToken);
      
      debugPrint('[GlobalOAuthHandler] Token sync completed');
      
      // 清理保存的ID Token
      OAuthStateManager.clear();
      
      // 导航到首页（使用全局appRouter）
      debugPrint('[GlobalOAuthHandler] Navigating to home page');
      
      // 隐藏全局loading（路由跳转后会由页面自动清理）
      _globalContainer.read(globalLoadingProvider.notifier).state = false;
      debugPrint('[GlobalOAuthHandler] Hiding global loading before navigation');
      
      appRouter.go('/home');
      
    } catch (e, stackTrace) {
      debugPrint('[GlobalOAuthHandler] Google OAuth callback failed: $e');
      debugPrint('[GlobalOAuthHandler] Stack trace: $stackTrace');
      
      // 清理保存的ID Token（避免重复尝试）
      OAuthStateManager.clear();
      
      // 错误时也隐藏全局loading
      _globalContainer.read(globalLoadingProvider.notifier).state = false;
      debugPrint('[GlobalOAuthHandler] Hiding global loading due to error');
      
      rethrow;
    }
  }

  /// 检查并恢复中断的OAuth登录
  /// 应用启动或登录页面加载时调用
  static Future<void> checkAndRecoverInterruptedOAuth() async {
    if (!_initialized) {
      debugPrint('[GlobalOAuthHandler] Not initialized, cannot check for recovery');
      return;
    }

    debugPrint('[GlobalOAuthHandler] Checking for interrupted OAuth login...');
    
    // 检查是否有未过期的Google OAuth ID Token
    final idToken = OAuthStateManager.getIdToken('google');
    if (idToken == null) {
      debugPrint('[GlobalOAuthHandler] No interrupted OAuth login found');
      return;
    }
    
    debugPrint('[GlobalOAuthHandler] Found interrupted Google OAuth login, attempting recovery...');
    
    try {
      await handleGoogleOAuthCallback(idToken: idToken, inviteCode: null);
      debugPrint('[GlobalOAuthHandler] OAuth recovery completed successfully');
    } catch (e) {
      debugPrint('[GlobalOAuthHandler] OAuth recovery failed: $e');
      // 清理保存的ID Token（避免重复尝试）
      OAuthStateManager.clear();
    }
  }

  /// 重置所有OAuth状态
  static void reset() {
    OAuthStateManager.clear();
    debugPrint('[GlobalOAuthHandler] All OAuth state cleared');
  }
}