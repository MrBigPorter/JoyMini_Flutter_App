# Flutter PWA 实现指南

> 基于 JoyMini 项目实战，覆盖"为什么、是什么、怎么做"三个问题。

---

## 一、为什么要做 PWA？

### 用一句话解释
> 让网页 App 拥有原生 App 的体验：可安装到桌面、离线可用、收到推送通知。

### 具体好处

| 问题 | 没有 PWA | 有了 PWA |
|------|---------|---------|
| 用户每次都要打开浏览器，找网址 | ✅ 必须 | ❌ 直接从桌面 icon 启动 |
| 网络断了什么也看不到 | ✅ 白屏 | ❌ 有离线提示页，不崩溃 |
| 没有 App Store，没法推送 | ✅ 无推送 | ❌ Firebase 推送正常工作 |
| 浏览器地址栏、工具栏占屏幕 | ✅ 占位 | ❌ 全屏独立窗口，像原生 |
| 每次加载都要重新下载所有资源 | ✅ 慢 | ❌ Service Worker 缓存，秒开 |

### 什么场景最适合 PWA？
- 电商 App（JoyMini 这种）：用户不一定愿意装 App，但 PWA 一键"安装"，零门槛
- 海外市场：很多用户手机存储不足，不愿意装 App
- 内部工具 / B 端系统：不用上架审核，直接部署

---

## 二、PWA 是什么样的？

### 用户视角

1. **普通用户**：打开网站，Chrome 地址栏弹出"添加到主屏幕"提示，点击后桌面多了一个 JoyMini 图标
2. **安装后**：从图标启动，没有地址栏，没有浏览器工具栏，就像打开 App
3. **断网时**：不会白屏崩溃，而是显示一个品牌化的离线提示页
4. **有更新时**：顶部出现一个横幅"有新版本，点击重载"

### 技术视角（三个核心组件）

```
PWA = manifest.json + Service Worker + HTTPS
        ↓                ↓
    "我是一个App"    "我能离线运行"
```

**1. `manifest.json`** — App 的身份证
```json
{
  "name": "JoyMini",           // 完整名称
  "short_name": "JoyMini",     // 桌面图标下方显示的名字
  "start_url": "/",            // 从图标启动时打开哪个页面
  "display": "standalone",     // standalone = 全屏，没有浏览器 UI
  "theme_color": "#FF5722",    // 手机状态栏颜色
  "icons": [...]               // 各尺寸图标
}
```

**2. Service Worker (SW)** — 网络代理层，运行在后台
```
用户请求 → Service Worker → 有缓存? → 直接返回缓存
                         → 没有?  → 去网络取，顺便缓存
                         → 断网?  → 返回离线页面
```

**3. HTTPS** — 必须条件（SW 只在安全域名下工作）

---

## 三、Flutter PWA 的特殊性

Flutter Web 与普通网页 PWA 有一个关键区别：

```
普通网页 PWA：  你自己写 Service Worker 缓存 HTML/JS/CSS
Flutter Web：   Flutter 构建时自动生成 flutter_service_worker.js
                你只需要配置，不需要手写缓存逻辑
```

### Flutter 自动生成的内容
运行 `flutter build web` 后，`build/web/` 目录里会有：
- `flutter_service_worker.js` — 自动缓存所有 Flutter 资源（wasm/js/字体/图片）
- `flutter_bootstrap.js` — 注册上面的 SW

这意味着：**Flutter 应用的"离线缓存"是免费的**，你不用写一行 SW 代码就能实现。

---

## 四、怎么做（JoyMini 的完整方案）

### 4.1 文件结构

```
web/
├── manifest.json          ← App 身份证（需要改品牌）
├── index.html             ← PWA meta 标签（需要补全）
├── pwa_sw.js              ← 自定义 SW（处理离线回退）
├── offline.html           ← 断网时显示的页面
├── firebase-messaging-sw.js  ← Firebase 推送 SW（已有，不冲突）
└── icons/
    ├── Icon-192.png
    ├── Icon-512.png
    ├── Icon-maskable-192.png  ← Android 自适应图标
    └── Icon-maskable-512.png

lib/
├── utils/
│   ├── pwa_helper.dart        ← Flutter 侧工具类（统一入口）
│   ├── pwa_helper_web.dart    ← Web 实现（JS Interop）
│   └── pwa_helper_stub.dart   ← Native 空实现
└── components/
    └── pwa_banners.dart       ← 安装引导条 + 更新提示条
```

---

### 4.2 Step 1：配置 manifest.json

**最关键的字段：**

```json
{
  "name": "JoyMini",
  "short_name": "JoyMini",
  "description": "...",
  "start_url": "/",
  "scope": "/",
  "display": "standalone",
  "background_color": "#F8F9FA",
  "theme_color": "#FF5722",
  "icons": [
    { "src": "icons/Icon-192.png", "sizes": "192x192", "purpose": "any" },
    { "src": "icons/Icon-512.png", "sizes": "512x512", "purpose": "any" },
    { "src": "icons/Icon-maskable-192.png", "sizes": "192x192", "purpose": "maskable" },
    { "src": "icons/Icon-maskable-512.png", "sizes": "512x512", "purpose": "maskable" }
  ],
  "shortcuts": [
    { "name": "Flash Sale", "url": "/flash-sale", "icons": [...] }
  ]
}
```

**注意事项：**
- `start_url` 用 `/` 不要用 `.`（相对路径在某些浏览器会有问题）
- `purpose: "maskable"` 图标会被裁剪成圆形/圆角，**安全区域**要在图标中心 80% 以内
- `shortcuts` 是长按图标出现的快捷菜单（Android Chrome 支持）

---

### 4.3 Step 2：补全 index.html 的 PWA meta

```html
<!-- 视口：viewport-fit=cover 支持 iPhone 刘海屏 -->
<meta name="viewport" content="width=device-width, initial-scale=1.0,
      viewport-fit=cover">

<!-- 状态栏主题色（Android Chrome 地址栏颜色） -->
<meta name="theme-color" content="#FF5722">

<!-- iOS Safari 安装后全屏运行 -->
<meta name="apple-mobile-web-app-capable" content="yes">
<meta name="apple-mobile-web-app-status-bar-style" content="default">
<meta name="apple-mobile-web-app-title" content="JoyMini">

<!-- iOS 桌面图标 -->
<link rel="apple-touch-icon" sizes="192x192" href="icons/Icon-192.png">

<!-- 链接 manifest -->
<link rel="manifest" href="manifest.json">
```

**为什么 iOS 需要单独处理？**
Safari 不完全支持 W3C PWA 标准，需要 `apple-mobile-web-app-*` 这组私有 meta。

---

### 4.4 Step 3：自定义 Service Worker（离线回退）

Flutter 已经有自己的 SW，我们的 `pwa_sw.js` 只补一件事：**导航请求断网时返回 offline.html**。

```javascript
// pwa_sw.js

const CACHE_NAME = 'joymini-shell-v1';
const OFFLINE_URL = '/offline.html';

// 安装时预缓存应用外壳
self.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open(CACHE_NAME).then(cache =>
      cache.addAll(['/offline.html', '/manifest.json', '/icons/Icon-192.png'])
    ).then(() => self.skipWaiting())
  );
});

// 激活时清理旧版本缓存
self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys().then(names =>
      Promise.all(names
        .filter(n => n !== CACHE_NAME && n.startsWith('joymini-'))
        .map(n => caches.delete(n))
      )
    ).then(() => self.clients.claim())
  );
});

// 拦截请求：导航请求断网时回退到 offline.html
self.addEventListener('fetch', (event) => {
  if (event.request.method !== 'GET') return;
  if (event.request.mode === 'navigate') {
    event.respondWith(
      fetch(event.request).catch(() => caches.match(OFFLINE_URL))
    );
  }
});
```

**SW 版本更新策略：**
- 改了 `pwa_sw.js` 内容 → 浏览器检测到文件变化 → 下载新 SW → 等待旧页面关闭 → 激活
- 想立即激活：SW 调用 `self.skipWaiting()`，然后前端提示用户刷新页面

---

### 4.5 Step 4：在 index.html 注册 SW

```html
<script>
  // 捕获安装提示事件
  let deferredPrompt = null;
  window.addEventListener('beforeinstallprompt', (e) => {
    e.preventDefault();             // 阻止浏览器自动弹框
    deferredPrompt = e;             // 保存，稍后手动触发
    window.__pwaInstallReady = true; // 通知 Flutter
  });

  // 暴露给 Flutter 调用
  window.triggerPwaInstall = function() {
    if (deferredPrompt) {
      deferredPrompt.prompt();
      deferredPrompt = null;
      return true;
    }
    return false;
  };

  // 注册自定义 SW
  if ('serviceWorker' in navigator) {
    navigator.serviceWorker.register('/pwa_sw.js').then(reg => {
      // 监听 SW 更新
      reg.addEventListener('updatefound', () => {
        reg.installing.addEventListener('statechange', () => {
          if (reg.installing?.state === 'installed' && navigator.serviceWorker.controller) {
            window.__pwaUpdateReady = true; // 通知 Flutter 有新版本
          }
        });
      });
    });
  }
</script>
```

---

### 4.6 Step 5：Flutter 侧工具类

**设计思路：**
```
PwaHelper（公开 API）
    ↓ kIsWeb?
    ├── YES → PwaHelperWeb（JS Interop，读取 window 上的信号）
    └── NO  → PwaHelperPlatform（空实现，native 直接 return false）
```

**核心 API：**
```dart
// 检查是否可以安装
if (PwaHelper.canInstall) { ... }

// 弹出安装引导
await PwaHelper.promptInstall();

// 检查是否有更新
if (PwaHelper.updateAvailable) { ... }

// 应用更新（触发页面刷新）
PwaHelper.applyUpdate();

// 是否已经以 PWA 模式运行
bool isPwa = PwaHelper.isInstalledPwa;
```

**JS Interop 关键写法（Dart 读取 JS window 属性）：**
```dart
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'package:web/web.dart' as web;

// 读属性
final v = (web.window as JSObject).getProperty('__pwaInstallReady'.toJS);
if (!v.isUndefinedOrNull) {
  bool result = (v as JSBoolean).toDart;
}

// 调方法
final result = (web.window as JSObject)
    .callMethod<JSBoolean>('triggerPwaInstall'.toJS);
```

**条件导入（Web vs Native）：**
```dart
// main.dart
import 'utils/pwa_helper_web.dart'
    if (dart.library.io) 'utils/pwa_helper_stub.dart';

// dart.library.io 在 native 平台（iOS/Android）存在 → 用 stub
// dart.library.io 在 Web 不存在 → 用 web 实现
```

---

### 4.7 Step 6：UI 组件

**安装引导条 `PwaInstallBanner`：**
- 挂载在首页顶部（SliverToBoxAdapter）
- 初始化时检查 `PwaHelper.canInstall`，符合条件才显示
- 动画滑入，用户可关闭

**更新提示条 `PwaUpdateBanner`：**
- 挂载在 app.dart 全局 builder 顶部（全屏常驻）
- 检测到 `PwaHelper.updateAvailable` 时显示
- 点击"Reload"触发 `PwaHelper.applyUpdate()`

---

### 4.8 Step 7：构建与发布

```bash
# 开发调试
flutter run -d chrome

# 生产构建（推荐 offline-first 策略）
flutter build web --pwa-strategy=offline-first

# pwa-strategy 选项：
#   offline-first  → 优先用缓存（推荐）
#   none           → 不生成 SW（禁用 PWA 缓存）
```

**部署要求：**
- ✅ 必须 HTTPS（本地 localhost 例外）
- ✅ 正确的 `Content-Type` 响应头
- ✅ `manifest.json` 可访问

---

## 五、SW 与推送通知共存方案

JoyMini 同时有 Firebase 推送 + 自定义 SW，两者**不冲突**：

```
firebase-messaging-sw.js  → 注册在 /firebase-cloud-messaging-push-scope
pwa_sw.js                 → 注册在 / (根 scope)
flutter_service_worker.js → 由 Flutter 构建时自动注册
```

三个 SW 独立工作，互不干扰。关键是 `pwa_sw.js` 里要跳过 Flutter 的 SW 请求：
```javascript
// 不要拦截 Flutter 自己的 SW
if (url.pathname.includes('flutter_service_worker')) return;
```

---

## 六、PWA Checklist（上线前确认）

```
必须项
[ ] HTTPS 部署
[ ] manifest.json 可访问（返回 200，Content-Type: application/json）
[ ] 至少有 192x192 和 512x512 两个图标
[ ] start_url 可访问
[ ] display 设置为 standalone 或 fullscreen

推荐项
[ ] 有 maskable 图标（Android 圆形图标适配）
[ ] 有 theme_color（状态栏颜色）
[ ] 有离线回退页（SW 捕获导航失败）
[ ] 在 Chrome DevTools > Application > Manifest 检查无报错
[ ] 在 Lighthouse 跑 PWA 审计（目标 90+ 分）
```

---

## 七、常见问题

**Q：为什么 iOS 的安装体验不一样？**
A：苹果不支持 `beforeinstallprompt` 事件，用户只能手动点 Safari 分享 → "添加到主屏幕"。我们的安装引导条在 iOS Safari 下需要用文字提示引导用户手动操作。

**Q：SW 更新后用户什么时候能用到新版本？**
A：默认等所有旧标签页关闭后才激活。我们用 `skipWaiting()` + `clients.claim()` 强制立即接管，然后通过 `PwaUpdateBanner` 提示用户刷新，保证体验可控。

**Q：Flutter 的 SW 和我自定义的 SW 会冲突吗？**
A：不会。Flutter SW 负责 `/flutter_service_worker.js` 范围的 Flutter 资源，我们的 `pwa_sw.js` 只处理导航回退和应用外壳。在 `fetch` 事件里跳过 Flutter SW 相关路径即可。

**Q：`dart:js_interop` 在 iOS/Android 上会报错吗？**
A：不会，因为所有调用都在 `kIsWeb` 判断后面，native 构建时这部分代码是死代码，会被 tree-shake 掉。

---

## 八、相关文件速查

| 文件 | 作用 |
|------|------|
| `web/manifest.json` | App 身份证，图标/颜色/名称/快捷方式 |
| `web/index.html` | PWA meta 标签、Install Prompt 脚本 |
| `web/pwa_sw.js` | 自定义 SW，离线回退逻辑 |
| `web/offline.html` | 断网时的品牌化提示页 |
| `web/firebase-messaging-sw.js` | Firebase 推送通知 SW（独立 scope） |
| `lib/utils/pwa_helper.dart` | Flutter PWA 工具类（统一入口） |
| `lib/utils/pwa_helper_web.dart` | Web JS Interop 实现 |
| `lib/utils/pwa_helper_stub.dart` | Native 空实现 |
| `lib/components/pwa_banners.dart` | 安装引导条 + 更新提示条 UI |
| `lib/main.dart` | 注册 PwaHelperWeb（Web 启动时） |
| `lib/app/app.dart` | 全局挂载 PwaUpdateBanner |
| `lib/app/page/home_page.dart` | 首页挂载 PwaInstallBanner |

---

## 九、这 4 个文件为什么能实现（通俗版）

你可以把它理解成 4 层：**浏览器能力层 -> Flutter 桥接层 -> Flutter UI 层 -> 页面挂载层**。

### 9.1 总流程（先看这个）

```text
用户打开页面
  -> 浏览器执行 index.html，注册 pwa_sw.js
  -> 浏览器把安装/更新状态放到 window 上
  -> Flutter 启动，PwaHelper 读取 window 状态
  -> pwa_banners.dart 根据状态显示提示条
  -> app.dart / home_page.dart 决定提示条显示位置
```

只要这条链路通了，PWA 安装引导 + 更新提醒 + 离线回退就会生效。

### 9.2 `web/pwa_sw.js`：为什么它能做离线回退？

- Service Worker 是浏览器原生标准能力，不是 Flutter 私有功能。
- 它能拦截导航请求（`fetch` + `request.mode === 'navigate'`）。
- 当网络失败时，直接返回缓存里的 `offline.html`。
- 所以即使 Flutter 页面来不及渲染，浏览器层也能兜底，避免白屏。

一句话：`pwa_sw.js` 是**网络请求兜底层**，先于 Flutter UI 生效。

### 9.3 `lib/components/pwa_banners.dart`：为什么它能显示安装/更新提示？

- 这个文件只负责 UI，不直接处理浏览器事件。
- 它通过 `PwaHelper` 读取两个信号：
  - `canInstall`（是否可安装）
  - `updateAvailable`（是否有新版本）
- 点击按钮后再调用：
  - `promptInstall()` 触发浏览器安装弹窗
  - `applyUpdate()` 触发页面刷新以应用新 SW

一句话：`pwa_banners.dart` 是**展示层**，依据状态决定展示什么。

### 9.4 `lib/app/app.dart`：为什么全局挂 `PwaUpdateBanner`？

- 更新提醒属于全局状态，不应该只在某一页出现。
- 放在 `MaterialApp.router` 外层 builder 后，任意路由都能看到。
- 用户在商品页、订单页、聊天页都能收到“有新版本”提醒。

一句话：放在 `app.dart` 是为了**全局可见**。

### 9.5 `lib/app/page/home_page.dart`：为什么首页挂 `PwaInstallBanner`？

- 安装引导适合在首屏触达，转化高、打扰小。
- 用 `SliverToBoxAdapter` 放在首页顶部，不破坏现有滚动结构。
- 用户只在合适时机看到一次安装引导，不会全局反复干扰。

一句话：放在 `home_page.dart` 是为了**体验策略更合理**。

### 9.6 一张图记住

```text
web/pwa_sw.js                 -> 能力层（离线/缓存）
lib/utils/pwa_helper*.dart    -> 桥接层（浏览器状态 -> Flutter）
lib/components/pwa_banners.dart -> UI层（安装/更新提示）
lib/app/app.dart + home_page.dart -> 挂载层（显示位置）
```

这就是“为什么它可以实现”的根因：
**浏览器负责能力，Flutter 负责呈现，二者通过 `PwaHelper` 对接。**

---

## 十、理解这 6 点，就算真正掌握 PWA（通俗版）

如果你只记住一堆 API 名字，还是会忘。真正掌握 PWA 的标准是：**你知道它为什么生效、坏了怎么查、更新怎么控**。

| 必懂点 | 通俗比喻 | 最小验证（1 分钟可做） |
|------|------|------|
| `manifest.json` 是 App 身份证 | 像给网站办“身份证 + 工牌”，系统才知道它是可安装 App | Chrome DevTools -> Application -> Manifest，看名称、图标、颜色是否正确 |
| Service Worker 是“门卫” | 所有请求都先过门卫，断网时门卫把你带去离线页 | 断网后刷新页面，确认能进 `offline.html` 而不是白屏 |
| 安装提示不是随时都有 | 像“系统发放的邀请函”，条件不满足就不会发 | Console 看 `beforeinstallprompt` 是否触发，`window.__pwaInstallReady` 是否变 `true` |
| Flutter 只负责 UI，不负责浏览器底层能力 | 浏览器是发动机，Flutter 是仪表盘 | 暂时隐藏 Banner，离线回退依然生效，说明底层能力独立 |
| 更新机制是“双版本交接” | 新门卫先上岗候补，旧门卫下班后再接管 | 改 `pwa_sw.js` 后重新部署，检查 `window.__pwaUpdateReady` 是否变 `true` |
| 排障要看链路，不要只看页面 | 像查水管：源头(浏览器事件) -> 中间(PwaHelper) -> 终点(UI) | 按顺序检查：`window` 信号 -> `PwaHelper` 返回值 -> Banner 是否显示 |

### 十一字口诀（记忆版）

**有身份、能拦截、可安装、会更新、能排障。**

### 什么时候算“完全掌握”？

满足下面 3 条，就可以认为你已经掌握 PWA：

1. 你能独立解释：为什么这个网页可以“像 App 一样被安装”。
2. 你能独立定位：安装不弹、离线不生效、更新不提示各自该查哪里。
3. 你能独立实现：从 0 配出一个最小可用 PWA（manifest + SW + 安装提示）。

