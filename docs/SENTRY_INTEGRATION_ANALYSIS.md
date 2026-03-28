# Sentry Flutter 集成方案分析

## 📋 项目现状

### 当前监控能力
- **Firebase Core**: 已集成 (firebase_core: ^4.3.0)
- **Firebase Auth**: 已集成 (firebase_auth: ^6.2.0)
- **Firebase Performance**: 已添加依赖 (firebase_performance: ^0.11.1+3) ⚠️ **未实际使用**
- **Sentry**: 未集成

### 痛点分析
1. **性能监控缺失**: Firebase Performance 依赖已添加但未实际使用
2. **错误分组困难**: 缺乏智能错误分组能力
3. **Release 管理**: 缺乏版本关联的错误追踪
4. **Source Map**: Web 端错误堆栈难以定位
5. **APM 空白**: 无 Transaction 级别的性能追踪

---

## 🎯 Sentry 核心优势

### 1. 智能错误分组
- 自动识别相同根因的错误
- 支持自定义分组规则
- 减少告警疲劳

### 2. 性能监控 (APM)
- Transaction 追踪
- Database Query 性能
- HTTP 请求监控
- 自定义 Span

### 3. Release 管理
- 版本关联错误
- Commit 关联
- Deploy 通知
- Regression 检测

### 4. Source Map 支持
- Web 端准确堆栈
- 混淆代码还原
- 自动上传

### 5. 丰富的上下文
- User 信息
- Device 信息
- Breadcrumbs
- 自定义 Tags

---

## 📦 技术方案

### 依赖配置

```yaml
# pubspec.yaml
dependencies:
  sentry_flutter: ^8.0.0
  sentry_dio: ^8.0.0  # Dio 集成
  sentry_logging: ^8.0.0  # Logging 集成
```

### 初始化配置

```dart
// lib/main.dart
import 'package:sentry_flutter/sentry_flutter.dart';

Future<void> main() async {
  await SentryFlutter.init(
    (options) {
      options.dsn = 'YOUR_DSN';
      options.environment = AppConfig.env;
      options.release = 'flutter_app@${AppConfig.version}';
      options.tracesSampleRate = 1.0;
      options.profilesSampleRate = 1.0;
      options.enableAutoSessionTracking = true;
      options.attachScreenshot = true;
      options.attachViewHierarchy = true;
    },
    appRunner: () => runApp(
      ProviderScope(child: MyApp()),
    ),
  );
}
```

### Dio 集成

```dart
// lib/core/api/http_client.dart
import 'package:sentry_dio/sentry_dio.dart';

final dio = Dio();
dio.addSentry();
```

### 错误捕获

```dart
// 全局错误捕获
FlutterError.onError = (details) {
  Sentry.captureException(
    details.exception,
    stackTrace: details.stack,
  );
};

// 手动捕获
try {
  // 业务代码
} catch (e, s) {
  Sentry.captureException(e, stackTrace: s);
}
```

### 性能监控

```dart
// Transaction
final transaction = Sentry.startTransaction(
  'processOrder',
  'task',
);

try {
  await processOrder();
  transaction.status = SpanStatus.ok();
} catch (e) {
  transaction.status = SpanStatus.internalError();
  rethrow;
} finally {
  await transaction.finish();
}

// Breadcrumb
Sentry.addBreadcrumb(Breadcrumb(
  message: 'User clicked login',
  category: 'auth',
  level: SentryLevel.info,
  data: {'method': 'google'},
));
```

---

## 🔄 与 Firebase Crashlytics 对比

| 功能 | Sentry | Firebase Crashlytics |
|------|--------|---------------------|
| 错误分组 | ⭐⭐⭐⭐⭐ 智能分组 | ⭐⭐⭐ 基础分组 |
| 性能监控 | ⭐⭐⭐⭐⭐ 完整 APM | ⭐⭐⭐ 基础性能 |
| Release 管理 | ⭐⭐⭐⭐⭐ 完整 | ⭐⭐ 基础 |
| Source Map | ⭐⭐⭐⭐⭐ 完整支持 | ⭐⭐ 有限支持 |
| 免费额度 | ⭐⭐⭐ 5K errors/月 | ⭐⭐⭐⭐⭐ 无限 |
| Google 生态 | ⭐⭐ 独立 | ⭐⭐⭐⭐⭐ 深度集成 |
| 实时性 | ⭐⭐⭐⭐⭐ 实时 | ⭐⭐⭐⭐ 准实时 |

---

## 🚀 实施计划

### Phase 1: 基础集成 (1-2 天)
- [ ] 添加 sentry_flutter 依赖
- [ ] 配置 DSN 和环境
- [ ] 初始化 Sentry
- [ ] 全局错误捕获

### Phase 2: 深度集成 (2-3 天)
- [ ] Dio 集成 (HTTP 监控)
- [ ] 自定义 Breadcrumbs
- [ ] User Context 设置
- [ ] 自定义 Tags

### Phase 3: 性能监控 (2-3 天)
- [ ] 关键业务 Transaction
- [ ] Database Query 监控
- [ ] 自定义 Spans

### Phase 4: Web 优化 (1-2 天)
- [ ] Source Map 上传配置
- [ ] CI/CD 集成
- [ ] Release 自动关联

### Phase 5: 告警配置 (1 天)
- [ ] 告警规则设置
- [ ] 通知渠道配置 (Slack/Email)
- [ ] On-call 流程

---

## 💰 成本分析

### Sentry 定价 (Team Plan)
- **免费**: 5K errors, 10K transactions/月
- **Team ($26/月)**: 50K errors, 100K transactions
- **Business ($80/月)**: 无限 errors, 500K transactions

### 建议
- 初期使用 **免费额度** 验证
- 根据实际数据量选择 Plan
- 可与 Firebase Crashlytics 并行使用

---

## ⚠️ 风险与注意事项

### 1. 性能影响
- Sentry SDK 会增加包体积 (~2MB)
- 网络请求会增加延迟
- 建议: 生产环境降低采样率

### 2. 隐私合规
- 避免发送敏感信息 (密码、Token)
- 配置 beforeSend 过滤
- GDPR 合规检查

### 3. 双重监控
- 可与 Firebase Crashlytics 并行
- 建议: 逐步迁移，最终统一到 Sentry

---

## 📊 成功指标

### 技术指标
- 错误捕获率 > 95%
- 错误分组准确率 > 90%
- 性能监控覆盖率 > 80%

### 业务指标
- MTTR (平均修复时间) 降低 30%
- 线上崩溃率 < 0.1%
- 用户投诉率降低 20%

---

## 📝 总结

### 推荐方案
**Sentry + Firebase Crashlytics 并行**

1. **Sentry**: 主力监控，处理错误分组、性能监控
2. **Firebase**: 备份监控，利用免费额度

### 实施优先级
1. ⭐⭐⭐⭐⭐ 错误监控 (立即)
2. ⭐⭐⭐⭐ 性能监控 (1 周内)
3. ⭐⭐⭐ Release 管理 (2 周内)

### 预期收益
- 更快的问题定位
- 更好的用户体验
- 更低的运维成本