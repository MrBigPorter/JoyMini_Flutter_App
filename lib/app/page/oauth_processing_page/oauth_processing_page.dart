import 'package:flutter/material.dart';
import 'package:flutter_app/common.dart';
import 'package:flutter_app/core/services/auth/global_oauth_handler.dart';
import 'package:flutter_app/core/store/auth/auth_provider.dart';
import 'package:flutter_app/ui/toast/radix_toast.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../routes/app_router.dart';

class OauthProcessingPage extends StatefulWidget {
  const OauthProcessingPage({super.key});

  @override
  State<OauthProcessingPage> createState() => _OauthProcessingPageState();
}

class _OauthProcessingPageState extends State<OauthProcessingPage> {
  bool _started = false;

  // 华为设备优化：缩短等待时间，提高轮询频率
  static const Duration _completionWindow = Duration(seconds: 4);
  static const Duration _pollInterval = Duration(milliseconds: 100);

  @override
  void initState() {
    super.initState();
    _startProcessing();
  }

  Future<void> _startProcessing() async {
    if (_started) return;
    _started = true;

    try {
      // Deep Link OAuth 体系下，token 已通过 /oauth/callback 路由写入 authProvider，
      // 直接轮询认证状态即可，无需 recovery 逻辑。
      final completed = await _waitForCompletionWindow();
      if (!mounted) return;

      if (completed) {
        _safeGo('/home');
      } else {
        RadixToast.error('OAuth session expired, please sign in again.');
        _safeGo('/login');
      }
    } catch (e) {
      if (!mounted) return;
      final message = e.toString().replaceFirst('Exception: ', '');
      RadixToast.error(
        message.isEmpty ? 'OAuth failed, please try again.' : message,
      );
      _safeGo('/login');
    }
  }

  void _safeGo(String path) {
    if (!isAppRouterReady) {
      debugPrint(
        '[OauthProcessingPage] Router not ready, skip navigation to $path',
      );
      return;
    }
    appRouter.go(path);
  }

  Future<bool> _waitForCompletionWindow() async {
    final int maxSteps =
        _completionWindow.inMilliseconds ~/ _pollInterval.inMilliseconds;

    for (int i = 0; i < maxSteps; i++) {
      if (!mounted) return false;

      final isAuthenticated = GlobalOAuthHandler.container
          .read(authProvider)
          .isAuthenticated;
      if (isAuthenticated) {
        return true;
      }

      // Deep Link OAuth系统不需要恢复逻辑，所有状态由后端管理
      // 直接检查认证状态即可

      await Future<void>.delayed(_pollInterval);
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 30.w,
              height: 30.w,
              child: CircularProgressIndicator(
                strokeWidth: 3.w,
                valueColor: AlwaysStoppedAnimation<Color>(
                  context.utilityBrand500,
                ),
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              'Processing Google Sign-In...',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
                color: context.textSecondary700,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'This may take a few seconds',
              style: TextStyle(
                fontSize: 12.sp,
                color: context.textSecondary700.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
