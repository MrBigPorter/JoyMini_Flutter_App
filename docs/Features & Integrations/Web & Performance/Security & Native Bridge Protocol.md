

# 👑 JoyMini 安全合规与原生桥接协议 (Security & Native Bridge Protocol) v12.0

## 1. 治理愿景与架构定位 (Overview)

JoyMini 的账户体系直接挂钩资产与真实社交关系。本协议旨在规范 Flutter 引擎与底层操作系统（Android/iOS）硬件能力的安全交互。
核心目标为：**“打破沙盒提取硬件算力，物理级阻断黑产伪造，零内存渗漏（0 Memory Leak）跨端通信。”**

---

## 2. 金融级生物风控流水线 (Biometric KYC Pipeline)

单纯依靠前端上传图片极易被“黑产改包”或“相册注入”攻破。JoyMini 实施了基于原生摄像头的强制接管。

### 2.1 证件扫描与边缘物理降噪 (Google ML Kit / VisionKit)

* **架构落脚点**：Android `DocumentScannerHandler.kt` / iOS `DocumentScanner.swift`
* **策略决议**：
* **剥离 Flutter 渲染**：彻底放弃在 Dart 层调用 Camera 插件扫码。通过 `MethodChannel('com.porter.joyminis/liveness')` 唤起系统级的高性能扫描仪。
* **Android 端**：锁定 `SCANNER_MODE_FULL`，由 Google Play Services 底层提供透视校正与边缘裁切。
* **iOS 端**：调用苹果原生 `VNDocumentCameraViewController`。


* **内存沙盒隔离**：扫描产出高清图片后，严禁在原生内存中长期持有 `UIImage/Bitmap`。必须写入系统临时目录（`temporaryDirectory`）并生成 UUID 命名空间，仅将**物理路径（String）**通过对讲机（`flutterResult`）回传给 Dart 层，杜绝 OOM (内存溢出)。

### 2.2 3D 活体防伪拦截 (AWS Amplify Liveness)

* **架构落脚点**：Android `LivenessActivity.kt` / iOS `LivenessView.swift`
* **交互桥接**：
* **声明式 UI 桥接**：在 iOS 端，将 AWS 提供的 SwiftUI 组件 `FaceLivenessDetectorView` 包装进 `UIHostingController`，实现从 UIKit (AppDelegate) 到 SwiftUI 的完美跨界融合。
* **状态回调闭环**：活体检测的结果（Success / Error / Cancel）被严格映射为 `pendingResult?.success` 或 `.error`，确保 Flutter 侧的 `await` 能够绝对闭环，不会导致线程永久挂起。



### 2.3 欺诈分级熔断矩阵 (Fraud Score Matrix)

* **架构落脚点**：`KycVerifyLogic` (`kyc_verify_logic.dart`)
* OCR 识别后，云端返回 `fraudScore`（欺诈评分）。在逻辑层建立绝对不可绕过的物理拦截防线：
* **死线阻断 (Score > 60)**：物理拒绝，系统弹出红色拦截面版，强制要求重新使用原件拍摄（拦截复印件/屏幕翻拍）。
* **警示线 (Score > 30)**：触发 `_showFraudWarningDialog`（Cupertino 底部行动栏），提示用户照片模糊或存在疑点，增加黑产批量自动注册的阻力。



---

## 3. 原生通信架构与防渗漏规约 (Native Bridge Anti-Leak)

`MethodChannel` 是 Flutter 与原生的命门，处理不当会造成严重的内存泄漏（Zombie Objects）。

### 3.1 iOS 弱引用生命周期护盾 (Weak Reference Shield)

* **痛点**：在 `AppDelegate.swift` 中注册 `setMethodCallHandler` 时，如果直接闭包捕获 `self` 或 `controller`，会导致 Flutter 引擎无法被释放。
* **强制规范**：
```swift
// 必须采用 [weak self, weak controller] 打破循环引用
livenessChannel.setMethodCallHandler({ [weak self, weak controller] (call, result) in
    guard let self = self, let controller = controller else { return }
    // ... 业务逻辑 ...
})

```



### 3.2 Android 结果句柄的“用完即焚” (Result GC)

* **痛点**：如果 `MethodChannel.Result` 被多次调用（如多次触发扫描），或者调用后未清空，会导致 `MissingPluginException` 或引擎崩溃。
* **强制规范**：
  在 `MainActivity.kt` 与 `DocumentScannerHandler.kt` 中，无论是 `success()`、`error()` 还是 `cancel` 分支，执行完毕后的首行代码必须是：
```kotlin
pendingResult = null // 释放句柄，防止回调复用与内存泄露

```



---

## 4. 硬件权限与系统层声明 (Hardware Permissions)

出海 App 上架 Google Play / App Store 时，权限声明不当会直接遭到拒审。JoyMini 实施了**“最小化且精确的权限基座”**。

### 4.1 Android `AndroidManifest.xml` 护城河

* **组件防劫持 (Exported = false)**：除了主入口 `MainActivity`，所有自建的硬件 Activity（如 `.LivenessActivity`）强制声明为 `android:exported="false"`，物理隔绝外部恶意 App 的 Intent 劫持唤起。
* **锁屏唤醒穿透**：针对音视频来电（CallKit），精准注入 `USE_FULL_SCREEN_INTENT`、`DISABLE_KEYGUARD` 与 `directBootAware="true"`，确保在手机息屏甚至刚开机未解锁时，依然能强力弹出来电界面。

### 4.2 iOS `Info.plist` 权限自证

* **VOIP 与后台保活**：`UIBackgroundModes` 强制注册 `voip` 与 `remote-notification`，配合 AppDelegate，确立音视频通话在 App 退入后台时的最高存活特权。
* **合规说明 (Usage Description)**：对于 Camera、Microphone 的调用，必须提供强业务相关的英文释义（如 *"JoyMini needs access to the microphone for audio/video calls..."*），防止因“权限滥用嫌疑”被苹果机审秒拒。

---

## 5. 安全与原生开发红线 (The Iron Rules for Security)

凡涉及底层与安全的修改，所有研发人员必须死守以下红线：

1. **凭证隔离红线**：严禁将任何第三方 SDK（AWS、Firebase）的 `SecretKey` 或 `SessionID` 硬编码在 Dart 源码中。必须由后端动态下发，随用随传。
2. **MethodChannel 并发阻断红线**：在调用 `startScan` 或活体时，Dart 层必须上锁（如使用 `isLoading`）。严禁在原生层返回结果前，允许用户进行第二次点击触发，防止通道阻塞崩溃。
3. **敏感信息脱敏红线**：在处理原生层回调的银行卡号或身份证号并呈现在回执/UI上时，必须强制经过 `_maskedAccount` 处理（仅保留前后4位）。严禁 UI 层直接渲染明文。

---

