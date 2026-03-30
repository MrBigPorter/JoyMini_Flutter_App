import 'package:flutter/foundation.dart'; // 必须引入
import 'package:flutter_app/core/config/app_config.dart';

class OAuthConfig {
  OAuthConfig._();

  static String get apiBaseUrl => AppConfig.apiBaseUrl;

  /// 🛠️ 改造：根据平台返回不同的 Callback
  static String get callbackUrl {
    if (kIsWeb) {
      // H5 端：返回当前网页的 Origin（例如 https://h5.joyminis.com/auth-callback）
      return '${Uri.base.origin}/oauth-callback';
    }
    // App 端：返回专属协议暗号
    return 'joymini://oauth/callback';
  }

  /// 构建带邀请码的 OAuth URL
  static String buildOAuthUrl(String provider, {String? inviteCode}) {
    // 使用 Uri 编码更安全
    final base = '$apiBaseUrl/api/v1/auth/$provider/login';
    final params = {
      'callback': callbackUrl,
      if (inviteCode != null && inviteCode.isNotEmpty) 'inviteCode': inviteCode,
    };
    return Uri.parse(base).replace(queryParameters: params).toString();
  }
}