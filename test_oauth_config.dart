import 'package:flutter_app/core/services/auth/deep_link_oauth_service.dart';

void main() async {
  print('=== OAuth 配置测试 ===');
  
  // 测试开发环境配置
  const devApiBaseUrl = 'https://dev-api.joyminis.com';
  
  print('1. 检查开发环境 OAuth 配置...');
  final devConfigOk = await DeepLinkOAuthService.checkOAuthConfiguration(devApiBaseUrl);
  print('开发环境配置状态: ${devConfigOk ? '✅ 正常' : '❌ 异常'}');
  
  if (!devConfigOk) {
    print('\n⚠️  OAuth 配置可能有问题：');
    print('1. 检查后端是否运行在 $devApiBaseUrl');
    print('2. 检查后端 /auth/google/login 端点是否可用');
    print('3. 检查 Google Cloud Console 中的 Authorized redirect URIs 配置');
    print('4. 检查后端环境变量 GOOGLE_REDIRECT_URI 是否正确');
  }
  
  // 测试 URL 构建
  print('\n2. 测试 OAuth URL 构建...');
  final testUrl = '$devApiBaseUrl/auth/google/login?callback=joymini%3A%2F%2Foauth%2Fcallback';
  print('生成的 URL: $testUrl');
  
  print('\n3. 测试 Deep Link 监听...');
  DeepLinkOAuthService.initialize();
  print('Deep Link 监听已初始化');
  
  print('\n=== 测试完成 ===');
  print('建议：');
  print('1. 手动访问以下 URL 测试 OAuth 流程：');
  print('   $testUrl');
  print('2. 授权后应该重定向到 joymini://oauth/callback?token=xxx');
  print('3. 如果返回 404，检查后端 /auth/google/callback 端点');
  
  // 清理
  DeepLinkOAuthService.dispose();
}