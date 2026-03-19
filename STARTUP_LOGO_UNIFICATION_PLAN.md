# 启动 Logo 统一规划（App / Web）

> 目标：把 JoyMini 启动阶段的视觉统一成“一套品牌、跨端一致、可持续维护”。

---

## 0. 文档使用方式

- 产品/设计看：第 2、3、5 章（目标与验收）
- 开发看：第 1、4、6 章（现状与执行）
- 新人学习看：第 7 章（掌握哪些就能明白）

---

## 1. 现状诊断（基于当前代码）

### 1.1 Android

- `android/app/src/main/res/drawable/launch_background.xml`
  - 当前为纯白背景层，Logo 位图层还是注释状态。
- `android/app/src/main/res/drawable-v21/launch_background.xml`
  - 当前使用 `?android:colorBackground`，仍是默认背景策略。
- `android/app/src/main/res/values/styles.xml`
  - `LaunchTheme` 通过 `windowBackground` 指向 `launch_background`。

结论：Android 冷启动视觉仍接近默认模板，品牌识别弱。

### 1.2 iOS

- `ios/Runner/Base.lproj/LaunchScreen.storyboard`
  - 使用 `LaunchImage` 居中展示 + 白色背景。
- `ios/Runner/Assets.xcassets/LaunchImage.imageset/*`
  - 启动图资源已存在，但与 Web loader 视觉规范未明确统一。

结论：iOS 有品牌图，但规范未和 Web/Android 对齐。

### 1.3 Web

- `web/index.html`
  - 已有自定义 loader（`app_icon.png` + 呼吸动画 + 文案）。
  - 启动完成后通过 MutationObserver 渐隐移除。

结论：Web 启动体验已品牌化，但与 Native 没有同一份设计规范约束。

### 1.4 总体问题

- 多端“各自实现”，没有统一的启动视觉规范文档。
- 资源链路分散（Android XML / iOS Storyboard / Web HTML）。
- 缺少统一验收标准，容易出现“都改了但看起来不一致”。

---

## 2. 统一目标（To-Be）

### 2.1 品牌目标

- 同一品牌资产源（同一套 Logo 文件与导出规则）。
- 同一视觉语言：背景色、Logo 尺寸占比、文案策略、过渡时长。

### 2.2 技术目标

- Native 启动页优先走自动化生成（减少手改 XML/Storyboard）。
- Web loader 与 Native 启动页按同规范对齐。
- 深浅色模式策略明确（至少保证不突兀、不反差崩坏）。

### 2.3 体验目标

- 冷启动首屏有品牌识别。
- 首帧过渡自然，无明显闪白和跳变。
- 多端启动“看起来像同一个产品”。

---

## 3. 统一品牌策略（同一套资产，多端一致）

### 3.1 资产策略

- 主 Logo：统一来源（建议复用 `assets/images/app_icon.png` 的设计源）。
- 启动专用导出：
  - 方图（Web / Android 12 icon 场景）
  - 居中图（iOS/Android 启动页）
- 命名与版本：统一命名，升级时只替换源文件并重生成。

### 3.2 视觉参数（建议先定死）

- 背景色：`#F8F9FA`（与当前 Web 启动背景一致）
- Logo 占比：短边约 22%~28%
- 文案策略：
  - Native 系统启动页不放文案（更稳）
  - Web loader 可保留短文案（如 "JoyMini is starting..."）
- 过渡时长：300ms~500ms 渐隐

### 3.3 平台边界

- Android/iOS 系统启动页：仅展示品牌，不放业务状态。
- Web loader：可以轻量动画，但避免复杂动画导致首屏阻塞。

---

## 4. 分阶段落地计划（可直接排期）

## 4.1 今天可做（D1）

- 明确并冻结启动视觉规范（背景色/尺寸/文案/动画时长）。
- 整理统一资产源文件与导出规范（设计 + 开发对齐）。
- 产出“点位清单”：
  - Android：`launch_background.xml` / `styles.xml`
  - iOS：`LaunchScreen.storyboard` / `LaunchImage.imageset`
  - Web：`web/index.html` loader 样式与文案

交付物：
- 一页规范（可放本文件附录）
- 资源清单（文件名 + 尺寸 + 用途）

## 4.2 本周收口（W1）

- Native 统一：
  - 引入并配置 `flutter_native_splash` 生成资源（Android + iOS）。
  - 减少手工维护 XML/Storyboard 的频率。
- Web 对齐：
  - 对齐 loader 背景色、logo 比例、文案与渐隐节奏。
- 回归验证：
  - Android（冷/热启动）
  - iOS（冷启动）
  - Web（首次加载/二次加载）

交付物：
- 跨端一致的启动视觉
- 一次性回归记录（截图/录屏）

---

## 5. 验收标准（避免“看起来改了但不一致”）

### 5.1 视觉一致性

- 三端背景色一致或在规范允许范围内。
- Logo 比例与居中位置一致（允许平台级微差）。
- 启动页无明显像素拉伸、裁切异常。

### 5.2 体验稳定性

- 冷启动无明显闪白。
- 首帧切换不突兀（渐隐 300~500ms）。
- 低网速场景下 Web loader 不抖动、不跳变。

### 5.3 可维护性

- 资源来源可追溯（知道改哪个源文件）。
- 生成步骤可复现（命令和说明齐全）。
- 后续换 Logo 不需要多端重复手改。

---

## 6. 任务清单（执行版）

- [ ] 冻结启动视觉规范
- [ ] 确认统一 Logo 资产与导出参数
- [ ] Native 通过工具生成启动资源
- [ ] Web loader 样式与文案对齐
- [ ] 三端回归截图与录屏留档
- [ ] 更新团队文档（含命令与注意事项）

---

## 7. 掌握哪些就可以明白（学习清单）

把下面 7 点掌握，就能完整理解“为什么要这样规划、为什么这样改最稳”。

### 1) 启动阶段有两层：系统层 + Flutter 层

- 系统层：App 进程刚拉起时展示（Android/iOS Launch Screen）。
- Flutter 层：引擎初始化后才绘制第一帧。

自测：你能解释为什么“只改 Flutter 页面”不会改变系统启动画面。

### 2) Android 启动页由 Theme + Drawable 决定

- 核心文件：`styles.xml` + `launch_background.xml`。

自测：你能说出 `LaunchTheme.windowBackground` 指向哪个文件。

### 3) iOS 启动页由 Storyboard + Asset 决定

- 核心文件：`LaunchScreen.storyboard` + `LaunchImage.imageset`。

自测：你能指出 iOS 启动图是哪个资源名（`LaunchImage`）。

### 4) Web 启动页本质是 HTML/CSS/JS Loader

- 核心文件：`web/index.html`。

自测：你能解释 loader 何时移除（Flutter 节点出现后渐隐）。

### 5) 一致性来自“统一规范”，不是“长得差不多”

- 要统一：背景色、Logo 比例、动效时长、文案策略。

自测：你能给出 1 套具体参数并让设计/开发都按它执行。

### 6) 自动化生成能降低维护成本

- 工具：`flutter_native_splash`（Native 启动资源生成）。

自测：你能描述“换 Logo 时为什么要优先改源文件再重生成”。

### 7) 验收必须跨端、跨场景

- 至少验证：Android 冷/热启动、iOS 冷启动、Web 首次/二次加载。

自测：你能列出一份完整回归清单并解释每项的意义。

---

## 8. 快速命令（后续执行时使用）

```bash
cd /Volumes/MySSD/work/dev/flutter_happy_app
fvm flutter pub get
fvm flutter pub run flutter_native_splash:create
```

> 说明：上面命令用于 Native 启动资源生成。执行前请先完成第 3 章视觉参数确认，避免反复返工。

