// Web平台专用实现
// 条件导入：仅在Web平台编译

import 'dart:html' as html;

/// Web平台专用方法实现
class DeepLinkOAuthServiceWeb {
  /// 获取 window.origin
  static String getWindowOrigin() {
    return html.window.location.origin;
  }

  /// 存储 state 到 sessionStorage
  static void storeStateInSession(String provider, String state) {
    try {
      html.window.sessionStorage['oauth_state_$provider'] = state;
    } catch (e) {
      // sessionStorage可能不可用（隐私模式）
      // 静默失败，不影响主要功能
    }
  }

  /// 重定向到 URL（当前窗口）
  static void redirectToUrl(String url) {
    html.window.location.href = url;
  }

  /// 验证 state 参数
  static bool validateState(String provider, String receivedState) {
    try {
      final storedState = html.window.sessionStorage['oauth_state_$provider'];
      if (storedState == null) {
        return false;
      }
      
      final isValid = storedState == receivedState;
      
      // 验证后清理
      html.window.sessionStorage.remove('oauth_state_$provider');
      
      return isValid;
    } catch (e) {
      return false;
    }
  }

  /// 从 URL 参数获取 token
  static Map<String, String>? getTokenFromUrl() {
    try {
      final uri = html.window.location;
      final search = uri.search ?? '';
      
      if (search.isEmpty) return null;
      
      // 手动解析URL参数
      final searchString = search.startsWith('?') ? search.substring(1) : search;
      final params = Uri.splitQueryString(searchString);
      
      final token = params['token'];
      final refreshToken = params['refreshToken'];
      final state = params['state'];
      final provider = params['provider'];
      
      if (token != null && provider != null && state != null) {
        // 验证 state
        if (!validateState(provider, state)) {
          return null;
        }
        
        return {
          'token': token,
          'refreshToken': refreshToken ?? '',
          'provider': provider,
        };
      }
      
      return null;
    } catch (e) {
      return null;
    }
  }

  /// 清理 URL 参数（避免token泄露）
  static void cleanUrl() {
    try {
      // 移除URL中的token参数
      final uri = html.window.location;
      final search = uri.search ?? '';
      
      if (search.contains('token=') || search.contains('state=')) {
        // 创建不带参数的URL
        final cleanUrl = '${uri.origin}${uri.pathname}';
        html.window.history.replaceState({}, '', cleanUrl);
      }
    } catch (e) {
      // 静默失败
    }
  }
}
