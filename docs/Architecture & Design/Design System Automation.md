

# 👑 JoyMini UI/UX 资产自动化白皮书 (Design System Automation) v12.0

## 1. 治理愿景与架构定位 (Overview)

在跨国多端应用中，维持 iOS、Android 与 Web 的 UI 视觉 100% 统一是一项极其困难的挑战。传统人工硬编码 UI 参数（Magic Numbers）的做法会导致严重的视觉碎片化与暗黑模式适配遗漏。
本白皮书确立了 JoyMini 的**“UI 资产单向数据流”**与**“代码生成主权”**：所有的颜色、间距、字号均由设计师的 Figma 原文件产出，经由自动化编译引擎直接合成为终端代码，彻底消灭前端的魔法数字。

---

## 2. 自动化编译引擎架构 (Token Generation Engine)

### 2.1 唯一事实来源 (Single Source of Truth)

* **协议输入**：设计师通过 Figma 插件导出标准的 `variables.tokens.json`。该 JSON 包含了全应用的所有基本图元（Primitives）、语义化颜色（Semantic Colors）、间距比例与排版字号。
* **物理隔离**：开发者严禁修改该 JSON 文件，它被视为系统 UI 的唯一“真理”。

### 2.2 Dart 语法树解析器 (`gen_tokens_flutter.dart`)

系统抛弃了繁重的第三方 UI 生成工具，自研了轻量级的 Dart AST (抽象语法树) 编译脚本：

* **色彩映射与边界溢出防御**：
  引擎内置 `_parseCssColorToArgb` 与 `_clamp255` 算法。将 JSON 中的 `rgba(255,255,255,0.5)` 或 `#FFFFFF` 安全、精准地转换为 Flutter 底层识别的 `0x` 16进制物理色值常量。
* **多态主题分发 (Dark/Light Mode)**：
  在生成 `TokensDark` 和 `TokensLight` 类的同时，自动为 `BuildContext` 生成 `TokensX` 扩展。开发者只需调用 `context.textBrandPrimary900`，底层自动根据 `Theme.of(context).brightness` 进行秒级明暗色切换。

---

## 3. 跨端自适应缩放算法 (Dynamic Scaling Factors)

这是 JoyMini 自动化引擎中最核心的**“物理降维打击”**。

在传统开发中，开发者必须时刻牢记给数值加上 `ScreenUtil` 的缩放后缀（如 `16.w`, `14.sp`），一旦遗漏，就会导致 App 在 iPad 或折叠屏上出现严重的 UI 错位与溢出。

**自动注入策略：**
解析脚本 `gen_tokens_flutter.dart` 在读取到 Token 类型时，会进行基于领域的智能后缀挂载：

* 若 `type == 'size'` 或 `'spacing'`，自动拼接 `.w` (宽度等比缩放)。
* 若 `type == 'borderradius'`，自动拼接 `.r` (圆角缩放)。
* 若 `type == 'fontsize'`，自动拼接 `.sp` (字号像素缩放)。

**工程收益**：
编译生成的静态常量天生具备多端自适应能力。开发层调用时，底层已经自动完成了所有的屏幕像素密度（DPI）换算。

---

## 4. 开发者体验 (DX) 与 I/O 防御机制

### 4.1 Tailwind 语义提示器 (`gen_tw_hints.dart`)

* 为了让新加入的开发人员能快速查阅设计系统，引擎利用 `_collectTokens` 递归遍历，生成了 `TwHints` 静态列表。
* 这种类似 Tailwind-CSS 的语义化命名（如 `spacing-10xl`，`text-sm`），极大地降低了前端与设计师的沟通成本。

### 4.2 I/O 幂等写入防线 (`io_utils.dart`)

* **痛点**：如果在自动化脚本 `generate.sh` 中直接进行全量覆写（`writeAsStringSync`），会导致文件的修改时间（mtime）更新，从而触发 Flutter 引擎全局的非必要重新编译与无限 Hot Reload（热重载）死循环。
* **防御决议**：
  引入 `writeFileIfChanged` 方法。在写入磁盘前，先进行内存数据的 Hash 比对。**“内容不变、物理不写”**，死死守住了本地开发环境的编译性能。

---

## 5. 团队 UI 开发红线 (The Golden Rules of UI)

本白皮书生效后，UI 开发流程必须遵守以下铁律（Code Review 强校验）：

1. **绝对禁止魔法数字**：代码中严禁出现如 `SizedBox(height: 24)`、`Color(0xFFFF0000)` 等字面量。必须使用 `context.spacingXl` 或 `context.textBrandPrimary900` 代替。
2. **禁止修改产物**：严禁任何人手动修改 `lib/theme/design_tokens.g.dart`。如需新增颜色，必须由设计师更新 JSON 后，在终端执行 `bash generate.sh` 重新编译生成。
3. **脚本阻断原则**：在 CI/CD 流水线中，`generate.sh` 被配置了 `set -e`。一旦 Token JSON 格式错误或解析失败，流水线立即阻断，严禁带病打包。

---

