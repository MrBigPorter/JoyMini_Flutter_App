import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/routes/app_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/global_loading_provider.dart';
import '../../store/auth/auth_provider.dart';

/// 全局OAuth处理器 - 不依赖页面状态，处理所有OAuth回调
/// 解决Native端OAuth登录页面销毁后context无效的问题
class GlobalOAuthHandler {
  GlobalOAuthHandler._();

  // 全局ProviderContainer引用（从main.dart注入）
  static late ProviderContainer _globalContainer;

  // 是否已初始化
  static bool _initialized = false;

  @visibleForTesting
  static void Function()? debugOnRecoveryCheckStarted;

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
      throw StateError(
        'GlobalOAuthHandler not initialized. Call initialize() first.',
      );
    }
    return _globalContainer;
  }

  /// 检查并恢复中断的OAuth登录
  /// 应用启动或登录页面加载时调用
  /// 注意：Deep Link OAuth系统不需要恢复逻辑，所有状态由后端管理
  static Future<bool> checkAndRecoverInterruptedOAuth({
    bool navigateAfterSuccess = true,
    bool showGlobalLoading = true,
  }) async {
    debugOnRecoveryCheckStarted?.call();

    if (!_initialized) {
      debugPrint(
        '[GlobalOAuthHandler] Not initialized, cannot check for recovery',
      );
      return false;
    }

    debugPrint('[GlobalOAuthHandler] Checking for interrupted OAuth login...');
    
    // Deep Link OAuth系统不需要恢复逻辑，所有状态由后端管理
    debugPrint('[GlobalOAuthHandler] Deep Link OAuth system - no recovery needed');
    return false;
  }

  /// 处理 Deep Link OAuth 回调（后端统一 OAuth）
  /// 用于处理 /oauth/callback?token=...&refreshToken=...&state=... 的回调
  static Future<void> handleDeepLinkOAuthCallback({
    required String token,
    required String refreshToken,
    required String state,
    String provider = 'google', // 默认 Google，可根据需要扩展
    bool navigateAfterSuccess = true,
    bool showGlobalLoading = true,
  }) async {
    if (!_initialized) {
      debugPrint(
        '[GlobalOAuthHandler] Not initialized, cannot handle Deep Link OAuth callback',
      );
      return;
    }

    if (showGlobalLoading) {
      // 显示全局loading
      _globalContainer.read(globalLoadingProvider.notifier).state = true;
      debugPrint(
        '[GlobalOAuthHandler] Showing global loading for Deep Link OAuth process',
      );
    }

    try {
      debugPrint(
        '[GlobalOAuthHandler] Handling Deep Link OAuth callback for provider: $provider',
      );
      debugPrint('[GlobalOAuthHandler] Token length: ${token.length}');
      debugPrint('[GlobalOAuthHandler] State: $state');

      // TODO: 验证 state 参数（防 CSRF）
      // 需要从 sessionStorage 获取存储的 state 进行验证
      // 暂时跳过验证，但记录警告
      debugPrint('[GlobalOAuthHandler] WARNING: State validation not implemented yet');

      // 同步token到全局auth provider
      final auth = _globalContainer.read(authProvider.notifier);
      await auth.login(
        token,
        refreshToken,
        navigate: false,
      );

      debugPrint('[GlobalOAuthHandler] Deep Link OAuth token sync completed');

      if (navigateAfterSuccess) {
        // 导航到首页（使用全局appRouter）
        debugPrint('[GlobalOAuthHandler] Navigating to home page');
        appRouter.go('/home');
      }

      if (showGlobalLoading) {
        if (navigateAfterSuccess) {
          // 导航后再收起 loading，避免登录页出现闪断感
          await Future<void>.delayed(const Duration(milliseconds: 120));
        }
        _globalContainer.read(globalLoadingProvider.notifier).state = false;
        debugPrint(
          '[GlobalOAuthHandler] Hiding global loading after Deep Link OAuth process',
        );
      }
    } catch (e, stackTrace) {
      debugPrint('[GlobalOAuthHandler] Deep Link OAuth callback failed: $e');
      debugPrint('[GlobalOAuthHandler] Stack trace: $stackTrace');

      if (showGlobalLoading) {
        // 错误时也隐藏全局loading
        _globalContainer.read(globalLoadingProvider.notifier).state = false;
        debugPrint('[GlobalOAuthHandler] Hiding global loading due to error');
      }

      rethrow;
    }
  }

  /// 重置所有OAuth状态
  static void reset() {
    debugPrint('[GlobalOAuthHandler] All OAuth state cleared');
  }
}
