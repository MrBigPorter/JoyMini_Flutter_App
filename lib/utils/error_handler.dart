import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../ui/toast/radix_toast.dart';

/// 统一错误处理器
/// 提供用户友好的错误提示和自动重试机制
class ErrorHandler {
  // 私有构造函数，防止实例化
  ErrorHandler._();

  /// 处理错误并显示用户友好的提示
  static void handle(
    dynamic error, {
    StackTrace? stackTrace,
    String? context,
    bool showToast = true,
    VoidCallback? onRetry,
  }) {
    // 1. 记录错误日志
    _logError(error, stackTrace, context);

    // 2. 转换为用户友好的错误消息
    final userMessage = getUserFriendlyMessage(error);

    // 3. 显示 Toast 提示
    if (showToast) {
      RadixToast.error(userMessage);
    }

    // 4. 上报错误（如果需要）
    _reportError(error, stackTrace, context);
  }

  /// 获取用户友好的错误消息
  static String getUserFriendlyMessage(dynamic error) {
    if (error is AppError) {
      return error.userMessage;
    }

    if (error is SocketException) {
      return '网络连接失败，请检查网络设置';
    }

    if (error is TimeoutException) {
      return '请求超时，请稍后重试';
    }

    if (error is DioException) {
      return _handleDioError(error);
    }

    if (error is FormatException) {
      return '数据格式错误，请稍后重试';
    }

    if (error is TypeError) {
      return '数据处理异常，请稍后重试';
    }

    // 默认错误消息
    return '操作失败，请重试';
  }

  /// 处理 Dio 错误
  static String _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return '网络连接超时，请稍后重试';
      
      case DioExceptionType.connectionError:
        return '网络连接失败，请检查网络设置';
      
      case DioExceptionType.badResponse:
        return _handleStatusCode(error.response?.statusCode);
      
      case DioExceptionType.cancel:
        return '请求已取消';
      
      default:
        return '网络请求失败，请稍后重试';
    }
  }

  /// 处理 HTTP 状态码
  static String _handleStatusCode(int? statusCode) {
    switch (statusCode) {
      case 400:
        return '请求参数错误';
      case 401:
        return '登录已过期，请重新登录';
      case 403:
        return '没有权限执行此操作';
      case 404:
        return '请求的资源不存在';
      case 500:
        return '服务器内部错误，请稍后重试';
      case 502:
      case 503:
      case 504:
        return '服务器繁忙，请稍后重试';
      default:
        return '请求失败，请稍后重试';
    }
  }

  /// 记录错误日志
  static void _logError(dynamic error, StackTrace? stackTrace, String? context) {
    if (kDebugMode) {
      debugPrint('❌ [ErrorHandler] ${context ?? "Error"}: $error');
      if (stackTrace != null) {
        debugPrint('StackTrace: $stackTrace');
      }
    }
  }

  /// 上报错误到监控系统
  static void _reportError(dynamic error, StackTrace? stackTrace, String? context) {
    // 待办: 集成 Sentry 或其他错误监控服务
    // Sentry.captureException(error, stackTrace: stackTrace);
  }
}

/// 应用错误模型
class AppError implements Exception {
  final String code;
  final String message;
  final String userMessage;
  final dynamic originalError;
  final StackTrace? stackTrace;

  const AppError({
    required this.code,
    required this.message,
    required this.userMessage,
    this.originalError,
    this.stackTrace,
  });

  @override
  String toString() => 'AppError(code: $code, message: $message)';
}

/// 重试助手
class RetryHelper {
  /// 执行带重试的异步操作
  static Future<T> retry<T>(
    Future<T> Function() action, {
    int maxRetries = 3,
    Duration delay = const Duration(seconds: 1),
    bool Function(dynamic error)? shouldRetry,
  }) async {
    int attempt = 0;
    
    while (true) {
      try {
        return await action();
      } catch (e) {
        attempt++;
        
        // 检查是否应该重试
        final canRetry = shouldRetry?.call(e) ?? _defaultShouldRetry(e);
        
        if (attempt >= maxRetries || !canRetry) {
          rethrow;
        }
        
        // 等待后重试
        await Future.delayed(delay * attempt);
        
        if (kDebugMode) {
          debugPrint('🔄 [RetryHelper] Retrying attempt $attempt/$maxRetries');
        }
      }
    }
  }

  /// 默认的重试判断逻辑
  static bool _defaultShouldRetry(dynamic error) {
    // 网络错误可以重试
    if (error is SocketException || error is TimeoutException) {
      return true;
    }
    
    // Dio 错误
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
        case DioExceptionType.connectionError:
          return true;
        default:
          return false;
      }
    }
    
    return false;
  }
}

/// 错误处理扩展
extension ErrorHandlerExtension on Future {
  /// 自动处理错误并显示 Toast
  Future<T?> withErrorHandling<T>({
    String? context,
    bool showToast = true,
    VoidCallback? onRetry,
  }) async {
    try {
      return await this as T;
    } catch (e, stackTrace) {
      ErrorHandler.handle(
        e,
        stackTrace: stackTrace,
        context: context,
        showToast: showToast,
        onRetry: onRetry,
      );
      return null;
    }
  }

  /// 自动重试并处理错误
  Future<T?> withRetry<T>({
    int maxRetries = 3,
    Duration delay = const Duration(seconds: 1),
    String? context,
    bool showToast = true,
  }) async {
    try {
      return await RetryHelper.retry<T>(
        () async => await this as T,
        maxRetries: maxRetries,
        delay: delay,
      );
    } catch (e, stackTrace) {
      ErrorHandler.handle(
        e,
        stackTrace: stackTrace,
        context: context,
        showToast: showToast,
      );
      return null;
    }
  }
}