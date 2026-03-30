import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 全局Loading状态Provider
/// 用于控制全局的loading显示，不依赖页面context
/// 可以在任何地方（包括main.dart）控制loading状态
final globalLoadingProvider = StateProvider.autoDispose<bool>((ref) => false);

/// 全局Loading消息Provider（可选）
/// 可以显示自定义的loading消息
final globalLoadingMessageProvider = StateProvider.autoDispose<String?>((ref) => null);

/// 全局Loading控制器
/// 提供便捷的方法来控制全局loading
class GlobalLoadingController {
  const GlobalLoadingController(this.ref);
  final Ref ref;

  /// 显示全局loading
  void show({String? message}) {
    ref.read(globalLoadingProvider.notifier).state = true;
    if (message != null) {
      ref.read(globalLoadingMessageProvider.notifier).state = message;
    }
  }

  /// 隐藏全局loading
  void hide() {
    ref.read(globalLoadingProvider.notifier).state = false;
    ref.read(globalLoadingMessageProvider.notifier).state = null;
  }

  /// 执行异步操作时显示loading
  Future<T> withLoading<T>(
    Future<T> Function() action, {
    String? message,
  }) async {
    show(message: message);
    try {
      return await action();
    } finally {
      hide();
    }
  }
}

/// 全局Loading控制器的Provider
final globalLoadingControllerProvider = Provider<GlobalLoadingController>((ref) {
  return GlobalLoadingController(ref);
});