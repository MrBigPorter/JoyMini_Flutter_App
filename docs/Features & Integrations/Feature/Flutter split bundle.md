# Flutter 分包现状分析报告

---

## ❌ 结论先行：目前**没有**任何分包

全项目扫描结果：
- `import 'xxx.dart' deferred as xxx` — **0 处**
- `loadLibrary()` — **0 处**
- `deferred_components:` in pubspec.yaml — **不存在**
- Android Dynamic Feature Modules — **未配置**

---

## 一、Flutter 的"分包"到底有几种含义？

| 机制 | 平台 | 原理 | 工程量 |
|------|------|------|-------|
| **Dart 延迟加载** (`deferred import`) | Web 有效 / Mobile 无效 | JS bundle 分割；移动端 AOT 编译成单文件，运行时无法再分割 | 低 |
| **Flutter Deferred Components** | Android only (实验性) | 结合 Play Feature Delivery，动态下载 Dart 代码+资源 | 高 |
| **Android App Bundle (AAB)** | Android | Play Store 按设备自动分发对应 ABI+屏幕密度包 | **极低** |
| **iOS App Thinning** | iOS | App Store 自动裁剪架构和资源，无需改代码 | **零** |

---

## 二、当前构建产物大小分析

> ⚠️ 下面是 Debug 构建，不可直接对比 Release，但架构分布规律一样

### iOS Debug App (431MB)
```
138MB   App.framework          ← 所有 Dart 代码编译结果
 38MB   Flutter.framework      ← Flutter 引擎（不可压缩）
 19MB   libavcodec.framework   ← FFmpeg（视频压缩用）
 11MB   WebRTC.framework       ← WebRTC（视频通话用）
8.5MB   libavfilter.framework  ← FFmpeg
4.6MB   libavformat.framework  ← FFmpeg
4.0MB   FBSDKCoreKit.framework ← Facebook Auth
3.7MB   FirebaseAuth.framework ← Firebase
...
```

### Android Debug APK (397MB)
> Release AAB 上架后 Play Store 会切分，单设备实际下载约 40-80MB

### 最重的原生 SDK（胖子排行）
```
🥇 FFmpeg Kit   ~30-40MB  → 仅 VideoProcessor.dart 用（发送视频时）
🥈 WebRTC       ~10-15MB  → 仅通话功能用
🥉 ML Kit       ~8-12MB   → 仅 KYC 人脸/文字识别用
🏅 Camera       ~3-5MB    → 仅 KYC + 视频录制用
```

---

## 三、为什么 Dart 延迟加载在移动端没用？

```
Web:
  编译结果 → main.dart.js + part_0.js + part_1.js...
  运行时   → 浏览器按需下载 part_*.js ✅ 真正分包

iOS/Android:
  编译结果 → App.framework (iOS) 或 libapp.so (Android) — 单个大文件
  运行时   → 操作系统加载整个文件，Dart VM 无法只加载其中一部分 ❌

Dart 的 deferred import 在移动端编译器层面会被"内联"处理，
loadLibrary() 调用会立即返回，代码实际上已经全部打包进去了。
```

---

## 四、真正有价值的分包方案（按 ROI 排序）

### ✅ 方案 A：Android App Bundle（今天就能做，零改动）

```bash
# 之前（Makefile 里目前没有这个）
flutter build apk               → 一个 fat APK，包含全部 ABI

# 改用 AAB
flutter build appbundle         → 上传到 Play Store
                                   Play Store 按设备分发：
                                   arm64-v8a  约 40-60MB
                                   armeabi-v7a 约 35-50MB
```

**效果**: 用户安装包体积减少 **40-60%**，零工程量。

---

### ✅ 方案 B：APK 按 ABI 分割（不用 Play Store 时的备选）

```bash
flutter build apk --split-per-abi

# 生成三个 APK：
# app-arm64-v8a-release.apk   → 现代 64 位设备 (主流)
# app-armeabi-v7a-release.apk → 旧 32 位设备
# app-x86_64-release.apk      → 模拟器
```

**效果**: 每个 APK 比 fat APK 小 **50-60%**，适合直接分发（不经 Play Store）。

---

### ⚠️ 方案 C：Flutter Deferred Components（工程量大，效果有限）

**适用场景**: 把 KYC 模块（ML Kit + Camera）做成按需下载的 Feature Module

```yaml
# pubspec.yaml 需要新增
flutter:
  deferred-components:
    - name: kyc
      libraries:
        - package:flutter_app/app/page/kyc_verify/kyc_verify_page.dart
      assets:
        - assets/kyc/
```

**限制**:
- Android only（iOS App Store 有 On Demand Resources 但 Flutter 不支持）
- **必须通过 Google Play 分发**（直接分发 APK 无效）
- Flutter 官方标注仍为实验性（experimental）
- 与 Shorebird 兼容性未知

**预估工程量**: 3-5 天 + 测试

---

### ❌ 方案 D：Dart deferred import（对你无效）

```dart
// 这段代码在移动端实际上不起分包作用
import 'package:flutter_app/heavy_feature.dart' deferred as heavyFeature;
await heavyFeature.loadLibrary(); // 在移动端这个调用是 no-op
```

---

## 五、你项目特有的情况：Shorebird

项目已集成 Shorebird (`shorebird.yaml` 存在，app_id 已配置)。

Shorebird 是**代码热更新**机制，与分包是两个不同概念：
- Shorebird: 解决"已安装用户的 Dart 代码更新"问题
- 分包: 解决"首次安装包体积"问题

两者不冲突，但 **Deferred Components + Shorebird 的组合目前没有官方支持文档**，风险较高。

---

## 六、建议行动计划

```
📦 立即可做（今天，零风险）:
  1. Makefile 新增 release-apk-split 命令
     flutter build apk --split-per-abi --release --dart-define-from-file=...
  2. Makefile 新增 release-aab 命令（Play Store 上架用）
     flutter build appbundle --release --dart-define-from-file=...

📦 短期（1天，中等收益）:
  3. Android 开启 minifyEnabled + shrinkResources（目前是 false！）
     预期减少 15-25% 包体积

📦 长期规划（按需，高收益但有成本）:
  4. KYC 模块 Deferred Component（如果通过 Play Store 发布）
  5. FFmpeg 按需加载（如果 WebRTC/KYC 使用量低）
```

---

## 七、为什么 `isMinifyEnabled = false` 是个大问题

```kotlin
// 当前 build.gradle.kts (!!!)
buildTypes {
    release {
        isMinifyEnabled = false     // ← 没有 R8 混淆压缩
        isShrinkResources = false   // ← 没有资源裁剪
    }
}
```

开启后预期效果：
- R8 + ProGuard: Dart 之外的 Java/Kotlin 代码减少 **20-30%**
- 资源裁剪: 去掉未引用资源，减少 **5-10%**
- 总计: Release APK 可能减少 **15-25MB**

⚠️ 注意: 开启前需要先确认 `proguard-rules.pro` 配置正确，否则可能导致运行时崩溃。
