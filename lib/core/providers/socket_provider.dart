import 'package:flutter/cupertino.dart';
import 'package:flutter_app/core/store/auth/auth_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_app/core/services/socket/socket_service.dart';

import '../api/http_client.dart';

// 1. 获取 SocketService 单例
final service = SocketService();

final socketServiceProvider = Provider<SocketService>((ref) {
  //  1. 打印 Provider 被触发的日志
  debugPrint("🔌 [SocketProvider] Provider building/refreshing...");

  // 监听 Token
  final token = ref.watch(authProvider.select((state) => state.accessToken));
  debugPrint("🔌 [SocketProvider] Current token state: ${token != null ? "Present (${token.substring(0, 5)}...)" : "NULL"}");

  //  2. 打印拿到的 Token 情况 (只打前几位，保护隐私)
  if (token != null && token.isNotEmpty) {
    debugPrint("🔌 [SocketProvider] Token available: ${token.substring(0, 10)}... calling init");

    // 调用初始化
    service.init(token: token);
  } else {
    debugPrint("🔌 [SocketProvider] Token is empty or null, calling disconnect");
    service.disconnect();
  }

  // 3. 监听Socket连接状态变化
  ref.onDispose(() {
    debugPrint("🔌 [SocketProvider] Provider disposed");
    service.dispose();
  });

  // 4. 设置Token刷新回调
  service.onTokenRefreshRequest = () async {
    debugPrint("🔄 [SocketProvider] Socket requesting token refresh...");
    try {
      final bool success = await Http.tryRefreshToken(Http.rawDio);
      if(success){
        debugPrint("✅ [SocketProvider] Token refresh successful, getting new token...");
        // B. 刷新成功后，从 Http 缓存拿新 Token
        final newToken = await Http.getToken();
        debugPrint("✅ [SocketProvider] New token obtained: ${newToken?.substring(0, 10)}...");
        return newToken;
      }else{
        debugPrint("❌ [SocketProvider] Token refresh failed, performing logout");
        // C. 刷新失败，强制登出
        await Http.performLogout();
        return null;
      }
    } catch (e, stackTrace) {
      debugPrint("❌ [SocketProvider] Token refresh error: $e");
      debugPrint("❌ [SocketProvider] Stack trace: $stackTrace");
      return null;
    }
  };

  debugPrint("🔌 [SocketProvider] Provider setup completed");
  return service;
});
