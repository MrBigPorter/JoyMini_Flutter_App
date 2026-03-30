import 'package:flutter/foundation.dart';
import 'package:flutter_app/core/services/auth/oauth_state_manager.dart';
import 'package:flutter_app/core/store/auth/auth_provider.dart';
import 'package:flutter_app/core/providers/auth_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// OAuth恢复处理器
/// 用于在应用启动时检查并恢复中断的OAuth登录
class OAuthRecoveryHandler {
  OAuthRecoveryHandler._();

  static final OAuthRecoveryHandler _instance = OAuthRecoveryHandler._();
  factory OAuthRecoveryHandler() => _instance;

  /// 检查并恢复中断的OAuth登录
  /// 在应用启动时调用，或者在登录页面初始化时调用
  Future<void> checkAndRecover(Ref ref) async {
    debugPrint('[OAuthRecoveryHandler] Checking for interrupted OAuth login...');
    
    // 检查是否有未过期的Google OAuth ID Token
    final idToken = OAuthStateManager.getIdToken('google');
    if (idToken == null) {
      debugPrint('[OAuthRecoveryHandler] No valid Google OAuth ID Token found');
      return;
    }
    
    debugPrint('[OAuthRecoveryHandler] Found interrupted Google OAuth login, attempting recovery...');
    
    try {
      // 调用后端API验证ID Token
      final result = await ref.read(authLoginGoogleCtrlProvider.notifier).run((
        idToken: idToken,
        inviteCode: null, // 恢复时可能没有邀请码
      ));
      
      debugPrint('[OAuthRecoveryHandler] Backend API call successful');
      
      // 同步token到auth provider
      final auth = ref.read(authProvider.notifier);
      await auth.login(result.tokens.accessToken, result.tokens.refreshToken);
      
      debugPrint('[OAuthRecoveryHandler] Google OAuth recovery completed successfully');
      
      // 清理保存的ID Token
      OAuthStateManager.clear();
      
    } catch (e) {
      debugPrint('[OAuthRecoveryHandler] Google OAuth recovery failed: $e');
      // 清理保存的ID Token（避免重复尝试）
      OAuthStateManager.clear();
    }
  }

  /// 手动触发恢复检查（用于调试）
  static void triggerRecoveryCheck(Ref ref) {
    debugPrint('[OAuthRecoveryHandler] Manual recovery check triggered');
    OAuthRecoveryHandler().checkAndRecover(ref);
  }
}