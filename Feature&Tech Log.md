

#  JoyMini 功能点任务与技术实现明细表 (Feature & Tech Log)

## 模块一：身份认证与安全风控体系 (Auth & Security)

### 1. 验证码登录与会话保持

* **任务难点**：OTP（一次性密码）发送、校验、登录的步骤繁琐，中途退出或网络异常容易导致状态卡死。
* **技术落地**：
* **状态机拆解**：在 `auth_provider.dart` 中将流拆分为 `SendOtpCtrl`、`VerifyOtpCtrl`、`AuthLoginOtpCtrl` 三个原子级 AsyncNotifier。
* **无感续命拦截器**：实现 `UnifiedInterceptor`。当接口报 401（Token 过期）时，利用 `QueuedInterceptor` 将所有并发请求放入队列，单线程静默调用 `Http.tryRefreshToken`，成功后原路释放重发，实现用户的“零感知续期”。



### 2. 金融级 KYC 实名认证 (活体 + OCR)

* **任务难点**：防范黑产使用照片/视频绕过实名认证；iOS/Android 硬件调用层级深，容易内存泄漏。
* **技术落地**：
* **硬件级沙盒通讯**：利用 `MethodChannel` 桥接原生系统 (`MainActivity.kt`, `AppDelegate.swift`)。
* **证件扫描去噪**：接入 Google ML Kit (`DocumentScannerHandler.kt`)，利用原生相机实现边缘检测和图像校正，回传临时目录的 `.jpg` 物理路径给 Flutter，规避 OOM。
* **活体防伪拦截**：对接 AWS Amplify Liveness (`LivenessView.swift`)，在 `kyc_verify_logic.dart` 中建立双重风控阈值（`fraudScore > 60` 物理死锁拦截，`>30` 弹窗警示重拍）。



---

## 模块二：首页呈现与商品大厅引擎 (Display & Lobby)

### 3. 动态首页与极限渲染

* **任务难点**：运营需要随时修改首页布局（轮播、金刚区、瀑布流）；商品图片过多导致首屏白屏、滑动卡顿。
* **技术落地**：
* **SWR (Stale-While-Revalidate) 秒开策略**：在 `home_provider.dart` 中，打开 App 瞬间同步读取 `ApiCacheManager` 本地持久化缓存渲染首帧，同时异步拉取最新数据静默更新（0 毫秒白屏）。
* **云端路由排版**：`home_treasures.dart` 通过 Dart 3 的 Switch 表达式解析 `imgStyleType`（1 到 4），自动分发渲染 `Ending` (横滑)、`Recommendation` (网格) 等不同组件。
* **滚动预加载引擎**：自研 `ScrollAwarePreloader`，监听滚动像素位移，提前静默解码屏幕外 15-30 个商品的高清大图。



### 4. 拼团大厅实时同步 (Group Lobby)

* **任务难点**：上千人同时拼团，如果依赖轮询，服务器直接被击穿；如果盲目刷新 UI，列表会疯狂抖动。
* **技术落地**：
* **静默热替换算法**：`group_lobby_logic.dart` 监听 Socket 的 `group_update` 信令。通过 `indexWhere` 定位到具体的商品卡片，比对 `updatedAt` 时间戳，仅对 `currentMembers` 和 `status` 进行**局部原子化重绘**，保持 60FPS。
* **断网自愈补偿**：当网络从断开恢复时，触发 `onSyncNeeded` 信号，强制拉取增量数据校准，杜绝人数对不上的 Bug。



---

## 模块三：交易引擎与资产中枢 (Transaction & Wallet)

### 5. 智能结算与订单创建 (Checkout)

* **任务难点**：计算单买/拼团的复杂价格体系；浮点数精度丢失（0.1+0.2 != 0.3）；用户忘记用优惠券。
* **技术落地**：
* **价格派生隔离**：在 `purchase_state_provider.dart` 中，绝不在 UI 层做加减法。所有的最终金额均由 `PurchaseState` getter 统一计算，并且加入 `groupPrice * 1.5` 的单买价格兜底算子。
* **精度转换锁**：所有金融实体（`payment.dart`, `balance.dart`）强绑定 `JsonNumConverter`。
* **最优资产套利**：`payment_page_logic.dart` 实现静默扫描算法 `_autoMatchBestCoupon`，自动计算并勾选满足门槛且抵扣最多的优惠券；若用户修改购买数量导致不满足门槛，自动触发物理撤回。



### 6. 多渠道充值提现闭环 (Deposit & Withdraw)

* **任务难点**：跳转第三方网页支付（GCash/Maya）容易断连，支付完回不到 App；回执页状态延迟。
* **技术落地**：
* **WebView 劫持与通信**：`payment_webview_mobile.dart` 通过 `shouldOverrideUrlLoading` 拦截后端的 `success_url`，强行关闭网页跳回原生。Web 端（WASM）则通过 `dart:js_interop` 监听 `window.postMessage` 实现跨 Tab 状态同步。
* **30秒自愈轮询**：`deposit_result_page.dart` 建立异步状态机，每 3 秒发起一次状态核对。
* **脏标记刷新 (Dirty Flag)**：提现/充值动作后，不再暴力刷新整个列表。通过操作 `transactionDirtyProvider` 标记，配合 `PageStorageKey`，在用户切回列表时无感刷新并记住滚动位置。



---

## 模块四：订单履约与用户空间 (Order & User Center)

### 7. 复杂订单列表与退款售后

* **任务难点**：万级订单列表滚动内存溢出；切换账号时看到上个账号的订单；订单卡片状态过多。
* **技术落地**：
* **状态机分页控制器**：重写 `PageListViewPro` (`list.dart`)，将加载、重试、骨架屏状态全部交由 `PageListController` 托管，彻底解耦 UI。
* **鉴权绑定自毁缓存**：`order_list.dart` 中的 `orderListCacheProvider` 强制 `watch(authProvider)`。登出或切号时，Riverpod 会物理炸毁该缓存 Map，实现 0 串流风险。
* **DDD 逻辑分治**：订单卡片拆分为 UI 渲染、数据模型 (`order_item.dart`) 和 逻辑处理 (`OrderItemLogic`)，退款/邀请等操作完全静态化代理。



---

## 模块五：底层基座与工程化链 (Infrastructure & DevOps)

### 8. 跨端适配与设计对齐 (Design & Compatibility)

* **任务难点**：Flutter Web 编译时找不到原生网络库报错；各端 UI 间距不统一。
* **技术落地**：
* **条件导出隔离 (Conditional Export)**：通过 `http_adapter_factory.dart`，在编译期物理隔离 `dart:io` 和 `dart:html`，让 Web 和 App 共用同一套 Dio 逻辑而不崩溃。
* **设计令牌自动化**：实现 `gen_tokens_flutter.dart`。通过执行 shell 脚本，直接将 Figma 的 JSON 设计稿编译为带 `.w` (宽度缩放)、`.sp` (字体缩放) 属性的 Dart 静态类，实现代码生成 UI 规范，禁绝开发者手写魔术数字。



### 9. 热更新与自动化发布流水线 (CI/CD)

* **任务难点**：频繁打测试包耗费人工；线上出现阻断性 Bug 需要紧急修复，但应用商店审核太慢。
* **技术落地**：
* **全自动工作流**：编写 `full_deploy.yml`。提交代码后触发 GitHub Actions 自动打包，通过 `curl` 机器人向 Telegram 发送带环境标签和下载二维码的图文报告。
* **Shorebird 补丁引擎**：部署 `hotfix_patch.yml`。一行命令 `shorebird patch android --force` 将 Dart 补丁直接推送到全球用户的手机内存中，用户下一次重启 App 瞬间完成 Bug 修复，绕过商店审核。



