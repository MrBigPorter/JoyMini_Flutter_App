import 'dart:async';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'app/app.dart';
import 'app/app_startup.dart';
import 'app/bootstrap.dart';
import 'core/services/auth/global_oauth_handler.dart';
import 'utils/pwa_helper_web.dart'
    if (dart.library.io) 'utils/pwa_helper_stub.dart';

void main() {
  // 第一道防线：捕捉 Flutter UI 渲染层的报错
  FlutterError.onError = (FlutterErrorDetails details) {
    debugPrint(' [Flutter 致命错误]: ${details.exceptionAsString()}');
  };

  // 必须在 runZonedGuarded 之前初始化绑定，
  // 这样 FlutterNativeSplash.preserve 才能在最早时机接管 Splash 生命周期。
  final binding = WidgetsFlutterBinding.ensureInitialized();

  // 保留系统 Splash，直到 runApp 完成后我们手动移除，消除黑白屏 gap。
  // Web 平台无原生 Splash，跳过。
  if (!kIsWeb) {
    FlutterNativeSplash.preserve(widgetsBinding: binding);
  }

  // 第二道防线：黑匣子，捕捉所有异步、插件报错
  runZonedGuarded(() async {
    // binding 已在外部初始化，此处为空操作，保留以防其他代码依赖调用顺序
    WidgetsFlutterBinding.ensureInitialized();

    // PWA: Register web implementation on web platform
    if (kIsWeb) registerPwaHelperWeb();

    try {
      // 1. 系统初始化 (无返回值，纯副作用)
      await AppBootstrap.initSystem();

      // 2. 加载初始配置 (获取 Overrides)
      final overrides = await AppBootstrap.loadInitialOverrides();

      // 3. 创建状态容器
      final container = ProviderContainer(overrides: overrides);
      AppBootstrap.setupInterceptors(container);

      // 初始化全局OAuth处理器（解决Native端OAuth页面销毁问题）
      GlobalOAuthHandler.initialize(container);
      debugPrint(' [架构日志] 全局OAuth处理器已初始化');

      // 后台触发 DB 初始化 + 数据预热，不阻塞 runApp。
      // 预热完成时机（~200ms）远早于用户第一次点击聊天 tab（操作需 1-3s），
      // 因此聊天秒开体验完全保留。
      unawaited(
        container.read(appStartupProvider.future).then((_) {
          debugPrint(' [架构日志] 后台数据预热完毕');
        }).catchError((Object e) {
          debugPrint(' [架构日志] AppStartup 初始化出现异常: $e');
        }),
      );

      // 4. 启动 UI：立即渲染首帧，消除数据屏障白屏！
      runApp(
        UncontrolledProviderScope(
          container: container,
          child: EasyLocalization(
            supportedLocales: const [Locale('en'), Locale('tl')],
            path: 'assets/locales',
            fallbackLocale: const Locale('en'),
            child: ScreenUtilInit(
              designSize: const Size(375, 812),
              minTextAdapt: true,
              splitScreenMode: true,
              builder: (context, child) => const MyApp(),
            ),
          ),
        ),
      );
    } finally {
      // 无论初始化是否成功，都必须移除 Splash，防止永久卡死。
      if (!kIsWeb) {
        FlutterNativeSplash.remove();
      }
    }
  }, (error, stackTrace) {
    debugPrint(' [全局拦截到的崩溃异常]: $error');
    debugPrint(' [异常堆栈]: $stackTrace');
  });
}

