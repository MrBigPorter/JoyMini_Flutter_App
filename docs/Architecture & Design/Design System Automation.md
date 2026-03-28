# 👑 JoyMini UI/UX Asset Automation Whitepaper (Design System Automation) v12.0

## 1. Governance Vision and Architecture Positioning (Overview)

In cross-national multi-platform applications, maintaining 100% visual unity across iOS, Android, and Web is an extremely difficult challenge. Traditional manual hardcoding of UI parameters (Magic Numbers) leads to severe visual fragmentation and dark mode adaptation遗漏.
This whitepaper establishes JoyMini's **"UI Asset Unidirectional Data Flow"** and **"Code Generation Sovereignty"**: all colors, spacing, font sizes are produced by设计师's Figma source files, compiled through automated compilation engine directly into terminal code,彻底消灭前端的魔法数字.

---

## 2. Automated Compilation Engine Architecture (Token Generation Engine)

### 2.1 Single Source of Truth

* **Protocol Input**: Designers导出 standard `variables.tokens.json` through Figma plugin. This JSON contains all basic primitives, semantic colors, spacing ratios, and typography font sizes for the entire application.
* **Physical Isolation**: Developers严禁修改 this JSON file, it is被视为 the唯一 "truth" of system UI.

### 2.2 Dart Syntax Tree Parser (`gen_tokens_flutter.dart`)

The system抛弃了繁重的 third-party UI generation tools,自研了 lightweight Dart AST (Abstract Syntax Tree) compilation script:

* **Color Mapping and Boundary Overflow Defense**:
  Engine内置 `_parseCssColorToArgb` and `_clamp255` algorithms.将 JSON中的 `rgba(255,255,255,0.5)` or `#FFFFFF` safely, accurately converted to Flutter底层识别的 `0x` hexadecimal物理色值常量.
* **Polymorphic Theme Distribution (Dark/Light Mode)**:
  When generating `TokensDark` and `TokensLight` classes, automatically generates `TokensX` extension for `BuildContext`. Developers只需调用 `context.textBrandPrimary900`,底层自动根据 `Theme.of(context).brightness`进行 millisecond-level明暗色切换.

---

## 3. Cross-Platform Adaptive Scaling Algorithm (Dynamic Scaling Factors)

This is JoyMini automation engine's most核心的**"物理降维打击"**.

In traditional development, developers must时刻牢记给数值加上 `ScreenUtil`的缩放后缀 (e.g., `16.w`, `14.sp`),一旦遗漏,就会导致 App在 iPad or折叠屏上出现严重的 UI错位与溢出.

**Automatic Injection Strategy:**
Parsing script `gen_tokens_flutter.dart` when reading Token type, performs domain-based intelligent suffix mounting:

* If `type == 'size'` or `'spacing'`, automatically拼接 `.w` (width proportional scaling).
* If `type == 'borderradius'`, automatically拼接 `.r` (corner radius scaling).
* If `type == 'fontsize'`, automatically拼接 `.sp` (font size pixel scaling).

**Engineering Benefits**:
Compiled static constants天生具备 multi-platform adaptive capability. When developers call,底层已经自动完成了所有的 screen pixel density (DPI) conversion.

---

## 4. Developer Experience (DX) and I/O Defense Mechanism

### 4.1 Tailwind Semantic Hints (`gen_tw_hints.dart`)

* To让 new developers能 quickly查阅 design system, engine利用 `_collectTokens`递归遍历,生成了 `TwHints`静态列表.
* This类似 Tailwind-CSS的 semantic naming (e.g., `spacing-10xl`, `text-sm`), greatly reduces communication cost between frontend and designers.

### 4.2 I/O Idempotent Write Defense (`io_utils.dart`)

* **Pain Point**: If直接进行全量覆写 (`writeAsStringSync`) in automation script `generate.sh`,会导致文件的修改时间 (mtime)更新,从而触发 Flutter引擎全局的非必要重新编译与无限 Hot Reload死循环.
* **Defense Decision**:
  Introduce `writeFileIfChanged` method. Before writing to disk,先进行内存数据的 Hash比对.**"内容不变、物理不写"**,死死守住了 local development environment的编译性能.

---

## 5. Team UI Development Red Lines (The Golden Rules of UI)

After this whitepaper takes effect, UI development流程必须遵守以下铁律 (Code Review强校验):

1. **Absolute Prohibition of Magic Numbers**:严禁在代码中出现如 `SizedBox(height: 24)`, `Color(0xFFFF0000)`等字面量.必须使用 `context.spacingXl` or `context.textBrandPrimary900`代替.
2. **Prohibition of Modifying Artifacts**:严禁任何人手动修改 `lib/theme/design_tokens.g.dart`.如需新增颜色,必须由设计师更新 JSON后,在终端执行 `bash generate.sh`重新编译生成.
3. **Script Blocking Principle**: In CI/CD pipeline, `generate.sh` is configured with `set -e`.一旦 Token JSON格式错误或解析失败, pipeline立即阻断,严禁带病打包.

---