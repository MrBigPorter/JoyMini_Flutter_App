
---

# 👑 JoyMini 极客级工程化与交付规约 (DevOps & Engineering Playbook) v12.0

## 1. 概述 (Overview)

随着 JoyMini 业务复杂度的几何级增长，依赖开发人员本地环境手动打包极易引入**“环境污染、版本错乱、产物泄露”**等致命风险。
本规约旨在确立 JoyMini 的**自动化、防御性与零宕机交付（Zero-Downtime Delivery）**标准，将从代码合并到上线的全流程托管至 DevOps 引擎，实现“提交即交付”。

---

## 2. 自动化集成与交付流水线 (CI/CD Pipeline)

核心承载基座：`full_deploy.yml` (GitHub Actions)。

### 2.1 触发路由与环境分发策略

* **测试环境 (Test)**：只要代码 Merge/Push 到 `test` 分支，流水线自动触发，挂载 `test.json` 环境变量。
* **生产环境 (Prod)**：严禁直接 Push 触发。必须通过向代码库打 `v*` 标签（如 `v1.2.0`）触发正式环境构建，挂载 `prod.json`。

### 2.2 绝对一致性基座 (Environment Determinism)

* **FVM 版本强锁**：通过解析 `fvm_config.json`，强制 Runner 节点（打包机）使用 `3.41.4` 版本的 Flutter SDK。杜绝“我的电脑上能跑，打包机上报错”的玄学问题。
* **原子化版本自增**：在构建阶段注入脚本 `perl -pi -e "s/^version: .*/version: $NEW_VERSION/g" pubspec.yaml`，利用 `github.run_number` 自动生成单调递增的 Build 号（如 `1.0.0+42`），彻底消灭人工修改版本号引发的合并冲突。

### 2.3 闭环触达与智能清理

* **可视化 Telegram 报表**：部署成功后，流水线调用 `curl` 自动生成包含 QR 码（利用 QuickChart API）和 Markdown 表格的战报发送至 TG 研发群。测试人员扫码即装，秒级感知产物状态。
* **Self-Hosted 硬盘防线**：在 `always()` 阶段强制执行 `rm -rf build/` 等指令。在自有 Mac 节点上物理清理数百 MB 的历史构建缓存，防止打包机 OOM（Out Of Memory）宕机。

---

## 3. Shorebird 动态热修复引擎 (Hot-Patching Architecture)

移动端分发最大的痛点是 App Store/Google Play 漫长的审核周期。针对线上 P0 级资损 Bug，JoyMini 引入 Shorebird 构建**“旁路修复通道”**。

核心承载基座：`hotfix_patch.yml` 与 `shorebird.yaml`。

### 3.1 触发与安全授权

* **手动调度 (workflow_dispatch)**：热更流水线严禁自动化触发，必须由核心开发者在 GitHub Actions 面板手动点选 `test` 或 `prod` 环境，以防误发测试代码到生产环境。

### 3.2 增量下发与指令规范

* **环境对称对齐**：执行热更时，脚本强制注入 `--dart-define-from-file` 参数。确保热更补丁的 API_BASE 与原生包的环境配置达到 100% 物理对称。
* **静默生效**：补丁文件编译后推送到 Shorebird 服务器，客户端 App 在下一次启动时利用原生 Hook 在底层静默下载替换 Dart AOT 快照，实现对用户的“零打扰修复”。

---

## 4. 跨端编译物理隔离规约 (Cross-Platform Isolation)

Flutter 虽为跨端框架，但其底层调用的硬件接口截然不同。为了让同一套代码能同时编译为 Web (WASM) 和 Native (Android/iOS) 应用，确立以下隔离规范：

### 4.1 网络底层适配器分流

* **痛点**：如果在文件中直接 `import 'dart:io'`，Web 端编译将直接报错崩溃。
* **解决方案**：通过条件导出机制实现 `http_adapter_factory.dart`：
```dart
export 'adapter_stub.dart'
    if (dart.library.io) 'adapter_io.dart'
    if (dart.library.html) 'adapter_web.dart';

```


* **效果**：Dio 网络请求层被彻底架空，在编译期间自动路由到对应平台的底层驱动（Http/XHR），保证了业务层网络调用 API 的纯净。

### 4.2 Web 端后台唤醒守护

* **问题**：WASM 应用一旦关闭 Tab 就会失去所有网络连接，无法接收推送。
* **应对**：在 Web 根目录下强行注入 `firebase-messaging-sw.js` (Service Worker)。接管浏览器的 Background 线程，实现 Web 端的离线强触达。

---

## 5. UI 资产全自动化管线 (Design Token Engine)

前端工程化最难的是治理“魔法数字（Magic Numbers）”与“颜色散落”。JoyMini 通过 AST 解析彻底机器化了这一流程。

核心承载基座：`gen_tokens_flutter.dart` 与 `generate.sh`。

### 5.1 从 Figma 到代码的单向数据流

* **禁止手写**：开发者严禁在代码中直接写死 `Color(0xFFFF0000)` 或 `height: 16`。
* **机器合成**：通过执行 `bash generate.sh`，系统会读取设计师导出的 `variables.tokens.json`，自动深度遍历解析。

### 5.2 智能适配后缀与防卡顿 I/O

* **物理缩放因子**：脚本自动为解析出的常量附加上 `.w`（宽度等比）、`.h`（高度）、`.sp`（字体）、`.r`（圆角）的后缀代码。开发者直接使用 `context.textBrandPrimary900` 即可获得具备跨端自适应能力的完美样式。
* **幂等写入防线 (`io_utils.dart`)**：系统在生成 `design_tokens.g.dart` 前，会先对比内存内容的 Hash 值。只有当 JSON 真正改变时才执行物理覆写，杜绝因文件修改时间（mtime）变动触发的 Flutter 无限热重载死循环。

---

## 6. DevOps 运维级红线 (The DevOps Iron Rules)

1. **密钥隔离红线**：严禁将任何 `.jks` (安卓签名)、`key.properties` 提交到 Git 仓库。所有签名凭证必须存放于 GitHub Secrets 中，流水线运行时动态注入，运行完毕后使用 `rm -f` 立刻焚毁。
2. **多端环境不污染红线**：所有针对 `dart:js_interop` 的调用必须被约束在单独的文件中，并在出口处建立 Web / App 条件引入。一旦发现有人在跨端公用 Widget 里乱用 `dart:html` 导致 App 端编译失败，代码拒绝 Merge。
3. **Shorebird 环境锁定红线**：执行 `shorebird patch` 必须使用与原始 release 完全一致的 FVM 版本和 `define` 配置。若配置不对称，轻则修复失败，重则导致客户端大面积闪退。

---

