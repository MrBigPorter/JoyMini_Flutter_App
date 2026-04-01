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

  /// 处理Google OAuth回调
  /// 可以从任何地方调用，不依赖页面context
  ///
  /// [showGlobalLoading] 为 true 时显示全局遮罩。
  /// 从登录页按钮触发时传 false（页面本身已有 loading）；
  /// 从 recovery / 静默流程触发时传 true（默认）。
  static Future<void> handleGoogleOAuthCallback({
    required String idToken,
    String? inviteCode,
    bool showGlobalLoading = true,
  }) async {
    await _processGoogleOAuthToken(
      idToken: idToken,
      inviteCode: inviteCode,
      navigateAfterSuccess: true,
      showGlobalLoading: showGlobalLoading,
    );
  }

  /// 处理 Google OAuth Token 并同步到业务登录态
  /// [navigateAfterSuccess] 为 true 时由本处理器负责跳转到 /home
  /// [showGlobalLoading] 为 true 时显示全局 loading
  static Future<void> _processGoogleOAuthToken({
    required String idToken,
    String? inviteCode,
    required bool navigateAfterSuccess,
    required bool showGlobalLoading,
  }) async {
    if (!_initialized) {
      debugPrint(
        '[GlobalOAuthHandler] Not initialized, cannot handle OAuth callback',
      );
      return;
    }

    if (showGlobalLoading) {
      // 显示全局loading
      _globalContainer.read(globalLoadingProvider.notifier).state = true;
      debugPrint(
        '[GlobalOAuthHandler] Showing global loading for OAuth process',
      );
    }

    try {
      debugPrint(
        '[GlobalOAuthHandler] Handling Google OAuth callback with idToken (length=${idToken.length})',
      );

      // 保存ID Token到全局状态管理器（用于状态恢复）
      OAuthStateManager.saveIdToken('google', idToken);

      // 调用后端API验证ID Token
      final result = await _globalContainer
          .read(authLoginGoogleCtrlProvider.notifier)
          .run((idToken: idToken, inviteCode: inviteCode));

      debugPrint('[GlobalOAuthHandler] Backend API call successful');

      // 同步token到全局auth provider
      final auth = _globalContainer.read(authProvider.notifier);
      await auth.login(
        result.tokens.accessToken,
        result.tokens.refreshToken,
        navigate: false,
      );

      debugPrint('[GlobalOAuthHandler] Token sync completed');

      // 清理保存的ID Token
      OAuthStateManager.clear();

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
          '[GlobalOAuthHandler] Hiding global loading after OAuth process',
        );
      }
    } catch (e, stackTrace) {
      debugPrint('[GlobalOAuthHandler] Google OAuth callback failed: $e');
      debugPrint('[GlobalOAuthHandler] Stack trace: $stackTrace');

      // 清理保存的ID Token（避免重复尝试）
      OAuthStateManager.clear();

      if (showGlobalLoading) {
        // 错误时也隐藏全局loading
        _globalContainer.read(globalLoadingProvider.notifier).state = false;
        debugPrint('[GlobalOAuthHandler] Hiding global loading due to error');
      }

      rethrow;
    }
  }

  /// 检查并恢复中断的OAuth登录
  /// 应用启动或登录页面加载时调用
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

    // 检查是否有未过期的Google OAuth ID Token
    final idToken = OAuthStateManager.getIdToken('google');
    if (idToken == null) {
      debugPrint('[GlobalOAuthHandler] No interrupted OAuth login found');
      return false;
    }

    debugPrint(
      '[GlobalOAuthHandler] Found interrupted Google OAuth login, attempting recovery...',
    );

    try {
      await _processGoogleOAuthToken(
        idToken: idToken,
        inviteCode: null,
        navigateAfterSuccess: navigateAfterSuccess,
        showGlobalLoading: showGlobalLoading,
      );
      debugPrint('[GlobalOAuthHandler] OAuth recovery completed successfully');
      return true;
    } catch (e) {
      debugPrint('[GlobalOAuthHandler] OAuth recovery failed: $e');
      // 清理保存的ID Token（避免重复尝试）
      OAuthStateManager.clear();
      return false;
    }
  }

  /// 重置所有OAuth状态
  static void reset() {
    OAuthStateManager.clear();
    debugPrint('[GlobalOAuthHandler] All OAuth state cleared');
  }
}
