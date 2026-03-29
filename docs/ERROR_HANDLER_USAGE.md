# 统一错误处理器使用指南

## 📋 概述

`ErrorHandler` 是一个统一的错误处理系统，提供用户友好的错误提示和自动重试机制。

## 🚀 核心功能

### 1. 统一错误处理

```dart
import 'package:flutter_happy_app/utils/error_handler.dart';

// 基本用法
try {
  await someApiCall();
} catch (e, stackTrace) {
  ErrorHandler.handle(
    e,
    stackTrace: stackTrace,
    context: 'API调用',
  );
}
```

### 2. 使用扩展方法（推荐）

```dart
// 自动处理错误并显示 Toast
await someApiCall().withErrorHandling(context: '加载数据');

// 自动重试并处理错误
await someApiCall().withRetry(
  maxRetries: 3,
  context: '加载数据',
);
```

### 3. 自定义重试逻辑

```dart
await RetryHelper.retry(
  () async => await apiCall(),
  maxRetries: 3,
  delay: Duration(seconds: 2),
  shouldRetry: (error) {
    // 只重试网络错误
    return error is SocketException || error is TimeoutException;
  },
);
```

## 📝 支持的错误类型

| 错误类型 | 用户友好消息 |
|---------|-------------|
| `SocketException` | 网络连接失败，请检查网络设置 |
| `TimeoutException` | 请求超时，请稍后重试 |
| `DioException.connectionTimeout` | 网络连接超时，请稍后重试 |
| `DioException.connectionError` | 网络连接失败，请检查网络设置 |
| `DioException.badResponse (401)` | 登录已过期，请重新登录 |
| `DioException.badResponse (500)` | 服务器内部错误，请稍后重试 |
| `FormatException` | 数据格式错误，请稍后重试 |
| `TypeError` | 数据处理异常，请稍后重试 |

## 🎯 使用场景

### 场景 1: API 调用

```dart
// ❌ 旧方式
try {
  final data = await api.getData();
} catch (e) {
  debugPrint('Error: $e');
  RadixToast.error('加载失败');
}

// ✅ 新方式
final data = await api.getData().withErrorHandling(context: '加载数据');
```

### 场景 2: 需要重试的操作

```dart
// ❌ 旧方式
int retryCount = 0;
while (retryCount < 3) {
  try {
    await uploadFile();
    break;
  } catch (e) {
    retryCount++;
    if (retryCount >= 3) rethrow;
    await Future.delayed(Duration(seconds: retryCount));
  }
}

// ✅ 新方式
await uploadFile().withRetry(maxRetries: 3, context: '上传文件');
```

### 场景 3: 自定义错误处理

```dart
try {
  await riskyOperation();
} catch (e, stackTrace) {
  ErrorHandler.handle(
    e,
    stackTrace: stackTrace,
    context: '危险操作',
    showToast: true, // 是否显示 Toast
    onRetry: () {
      // 重试回调
      riskyOperation();
    },
  );
}
```

## 🔧 高级用法

### 创建自定义错误

```dart
throw AppError(
  code: 'INSUFFICIENT_BALANCE',
  message: 'User balance is insufficient',
  userMessage: '余额不足，请充值后再试',
);
```

### 条件重试

```dart
await apiCall().withRetry(
  maxRetries: 3,
  shouldRetry: (error) {
    // 只重试网络错误，不重试业务错误
    if (error is AppError) return false;
    return error is SocketException;
  },
);
```

## 📊 错误监控

错误处理器会自动记录错误日志，并预留了错误上报接口：

```dart
// 在 ErrorHandler._reportError 中集成 Sentry
static void _reportError(dynamic error, StackTrace? stackTrace, String? context) {
  Sentry.captureException(error, stackTrace: stackTrace);
}
```

## ⚠️ 注意事项

1. **不要吞掉错误**: 使用 `withErrorHandling` 时，错误会被处理但不会抛出，返回值为 `null`
2. **重试次数**: 默认最多重试 3 次，可根据业务需求调整
3. **重试延迟**: 重试间隔会递增（1s, 2s, 3s...），避免频繁请求
4. **调试模式**: 只在 debug 模式下打印详细日志

## 🎉 迁移指南

### 步骤 1: 导入

```dart
import 'package:flutter_happy_app/utils/error_handler.dart';
```

### 步骤 2: 替换 try-catch

```dart
// 旧代码
try {
  await apiCall();
} catch (e) {
  debugPrint('Error: $e');
  RadixToast.error('操作失败');
}

// 新代码
await apiCall().withErrorHandling(context: '操作');
```

### 步骤 3: 添加重试（可选）

```dart
// 需要重试的场景
await apiCall().withRetry(maxRetries: 3, context: '操作');
```

## 📚 相关文档

- [RadixToast 使用指南](../lib/ui/toast/radix_toast.dart)
- [Dio 拦截器配置](../lib/core/network/unified_interceptor.dart)