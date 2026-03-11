
```markdown
# 📜 Lucky IM Project Grand Master Log (v4.0 - v6.6.0)

## 🛸 第十一章：企业级环境隔离与 OTA 闪电热更 (Enterprise Isolation & OTA Updates) **[v6.6.0 NEW]**

*本章标志着项目架构从“跑通即可”的荒野时代，正式迈入“绝对一致、动态干预”的工业级深水区。我们引入了 FVM 锁死编译环境，重构了去伪存真的 CI/CD 校验链，并利用 Shorebird 实现了无需商店审核的毫秒级空中补丁（OTA）下发。*


* **[Environment] FVM 绝对环境隔离 (Absolute Isolation)**:
  * **路径提权与引擎锁死**: 彻底终结了“在我电脑上明明没问题”的玄学 Bug。通过在 Self-hosted Runner 中执行 `echo "/opt/homebrew/bin" >> $GITHUB_PATH`，强行注入宿主机 FVM 路径，并严格依据 `.fvm/fvm_config.json` 执行 `fvm install`。确保云端与本地编译引擎达到 100% 的物理级一致性。

* **[CI/CD] 刮骨疗毒与智能路由 (Strict Validation & Smart Routing)**:
  * **斩断“假绿灯”骗局**: 彻底重构了 Firebase 分发阶段的代码。剔除了试图掩盖报错的 `|| true` 与 `|| echo` 容错代码，改用 `find build -name "*release.apk" | head -n 1` 精准寻址。一旦未检测到核心产物，立即执行 `exit 1` 抛出红灯，重建了对流水线 100% 的信任闭环。
  * **动态环境路由 (Environment Routing)**: 抛弃了极易引发生产事故的手动配置切换。流水线现能动态监听 Git 事件：Push `test` 分支强制注入 `test.json`；打 `v*` 标签强制注入 `prod.json`。
  * **版本自增闭环 (Auto Versioning)**: 引入 Perl 脚本解析 `pubspec.yaml`，并自动拼接 GitHub Run Number（如 `v1.0.0+33`），实现云端构建版本号的无人值守自增。

* **[OTA] Shorebird 引擎植入与补丁独立工作流 (Hot Update Patching)**:
  * **底层母体引擎注入**: 将基础流水线中的 Android 编译指令全面替换为 `shorebird release android`。在打包阶段同步向云端注册代码快照 (Snapshot) 与更新引擎 (Updater)，为后续的空中支援预留物理接口。
  * **独立防呆突击队 (Hotfix Patch Workflow)**: 专门开辟了 `hotfix_patch.yml` 独立工作流。强制采用 `workflow_dispatch` 手动触发，并要求操作者显式指定环境 (`test`/`prod`)。一旦执行，极小体积的补丁将瞬间推送到 Shorebird 云端，客户端下次冷启动即可实现 Bug 灰飞烟灭。

* **[Distribution] Fat APK 降维打击战略 (Universal APK Fallback)**:
  * **绕过 Google Play 风控墙**: 面对 Firebase 针对 AAB 格式必须关联 Google Play 开发者账号的死锁限制，果断实施“降维打击”。在 `7b` 阶段显式注入 `--artifact apk` 参数，迫使 Shorebird 输出包含所有 CPU 架构 (`arm64`, `x86` 等) 及热更底座的 **Fat APK (全能胖包，约 400MB)**。以暂时的体积妥协，换取了测试团队“扫码即装”的绝对分发速度。

---

## 🚀 第十章：DevOps 自动化与云端分发 (The DevOps & Cloud Distribution Era) **[v6.5.0]**

*本章标志着 Lucky IM 彻底终结了“手动编译、人工上传”的原始农耕时代。我们通过 GitHub Actions 与 Cloudflare Pages、Firebase 以及 Telegram 的深度集成，在压榨本地物理机极限算力的前提下，建立了一套涵盖 Web 与 Android 双端的分钟级全自动交付流水线。*

* **[Automation] GitHub Actions 全自动交付 (CI/CD Pipeline)**:
  * **流水线合龙**: 实现了从 `git push` 到 Cloudflare Pages 自动发布的完整闭环。采用 `subosito/flutter-action` 容器化环境，规避了本地开发环境差异导致的打包偏移。
  * **环境初始化自愈**: 攻克了 CI 环境下 `exit code 64` 的用法报错。通过显式执行 `flutter config --enable-web` 强制唤醒虚拟机的 Web 构建能力，解决了原生参数解析引擎的“冷启动”绝症。

* **[Distribution] 后端网关接力架构 (Nginx Gateway Relay)**:
  * **职责解耦**: 确立了“前端托管、后端路由”的混合架构。Flutter 静态产物托管于 Cloudflare 全球 CDN，而流量入口始终锁定在后端目录下的 `nginx.conf`。
  * **动态页保护**: 确保了 `/share.html` 等动态桥接页依然精准命中 NestJS 后端，同时将根路径 `/` 优雅反向代理至 Cloudflare 节点，实现了“静态加速”与“动态控制”的完美平衡。

* **[Security] 权限提权与 Secret 隔离 (Permission & Secret Management)**:
  * **403 权限破壁**: 修复了 `Resource not accessible by integration` 的 GitHub 权限死锁。通过在 Workflow 中显式声明 `permissions: deployments: write`，授予了临时 `GITHUB_TOKEN` 写入部署记录的权限。
  * **生产配置注入**: 实现了 `--dart-define-from-file=lib/core/config/env/prod.json` 的自动化注入，确保云端构建产物与生产环境域名配置字符级对齐，杜绝了硬编码导致的 API 访问漂移。

* **[Performance] 物理机单轨提速策略 (Self-hosted Single-Track Optimization)**:
  * **跨 Job 合并**: 针对本地 MacBook Air 算力中心，彻底摒弃了云端常用的多 Job 拆分策略。将 H5 与 Android 编译合并为单一 `build-all` 任务，实现了一次拉取代码、一次依赖下载，硬生生省下跨环境初始化的开销。
  * **Gradle 内存破解**: 抛弃云端防 OOM 的 `daemon=false` 设定，注入 `org.gradle.jvmargs` 开启 4GB 最大堆内存并保留守护进程，让本地 Mac 发挥常驻内存的编译优势，将双端出包时间压缩至 10 分钟级别。

* **[Distribution] Firebase 移动端极速分发 (Android App Distribution)**:
  * **无头自动化上传**: 利用 Firebase CLI，通过 `--token` 静默认证，精准将 191MB+ 的 APK 推送至指定的 `admin` 测试群组，彻底告别手动拖拽。
  * **容错假死豁免**: 针对 `firebase-tools` 在 Mac 环境下偶发的“成功上传但抛出 Exit Code 2”的系统级 Bug，引入了 `|| true` 强行通过指令，保证流水线绝不因非致命错误而中断标红。

* **[Notification] Telegram 动态战报与双轨闭环 (Dynamic QR Report)**:
  * **备用降落伞 (Artifacts)**: 引入 `upload-artifact@v4` 将 APK 同步归档在 GitHub 服务器 7 天，保留免登录、纯暴力的备用下载通道。
  * **扫码即装体验**: 提取 Firebase 的永久邀请链接，调用 `quickchart.io` 免费接口实时渲染二维码图片。通过 Telegram Bot API 的 `sendPhoto` 接口搭配 `if: always()` 守护指令，将二维码海报直推开发者手机，打通了“Push 即出码”的终极体验。

---

## 🛡️ 第九章：VoIP 极限防御与全端互通 (The VoIP Defense Era) **[v6.2.0 - v6.4.0]**

* **[Audio] 焦点抢占防御与硬件无缝路由 (Audio Focus & Hardware Routing)**:
  * **10086 系统打断防御 (Interruption Daemon)**: 彻底解决了视频通话中途遭遇原生系统电话（如 10086 / 闹钟）打断后，导致的“被动永久哑巴”绝症。通过监听 `AudioSession.instance.interruptionEventStream`，在 `event.begin == false`（原生电话挂断瞬间）执行核武级复苏：`await session.setActive(true)`，强行夺回麦克风底层物理控制权，实现通话自愈。
  * **AirPods 热插拔自适应 (Routing Daemon)**: 攻克了外设（蓝牙/有线耳机）插拔时的通道错乱与 UI 脱节问题。通过监听 `devicesChangedEventStream`，一旦侦测到外部设备接入 (`hasExternalAudio`)，底层通道自动转移，并通过 `onSpeakerStateChanged` 即时反向通知状态机，强行熄灭 UI 层扬声器图标，实现底层硬件与 UI 的绝对同步。
  * **音频会话极简配置 (AudioSession Minimalism)**: 避免了重度配置与 WebRTC 底层 C++ 音频引擎发生焦点争夺。移除了导致“失声”的冗余安卓属性和 iOS 路由策略，采用最精简稳健的 `avAudioSessionMode: AVAudioSessionMode.voiceChat`。

* **[Keep-Alive] 锁屏破壁与系统提权 (Lock-Screen Wakeup)**:
  * 机制: 彻底重构了 Android 的弹窗唤醒逻辑。将 `AndroidManifest.xml` 的启动模式修正为 `launchMode="singleInstance"`，配合物理级权限（悬浮窗、允许后台活动），成功突破了国产安卓（华为/小米等）严苛的锁屏/后台封杀，实现 100% 亮屏弹窗。

* **[Signal] 信令防抖与并发仲裁 (Signal Arbitrator)**:
  * 竞态防御: 解决了 FCM（保活通道）与 Socket（极速通道）同时到达导致的“信令影分身”与 UI 暴击问题。
  * 实现: 引入全局单例 `CallArbitrator`，基于 Session ID 建立 3.5 秒的全局防抖锁（Global Cooldown）。同一通电话绝对不接管第二次，成功拦截所有并发垃圾信令。
  * 诈尸误杀防御: 攻克了“旧电话挂断延迟秒杀新电话”的并发时序错乱。在挂断逻辑 (`hangUp`) 与发起逻辑中强制核对 SessionID，名字对不上直接将旧系统信号踢飞，形成防误杀护盾。

* **[Hardware] 硬件预热死锁规避 (Hardware Warm-up Defense)**:
  * 修复坑点: 攻克了华为/荣耀手机锁屏接听瞬间抢夺摄像头引发的 `CameraAccessException (-38)` 崩溃黑屏惨案。
  * 双端分治: 实施时序平台分流。iOS 保持极速拉起；Android 端在 `acceptCall` 中强制引入 1000ms 延迟，等待屏幕唤醒与底层硬件通电解封后，再安全挂载摄像头。

* **[Codec] 硬件编码降级与 SDP 伪装 (SDP Munging)**:
  * 修复坑点: 攻克了国内老旧机型（华为）H.264 硬件视频编码器等级极低（Level 1 限制），导致发送 720P 画面时底层崩溃、疯狂报 `mapFormat: no mediaType information` 及绿屏/黑屏的问题。
  * 核武操作: 实施底层的 SDP 偷梁换柱 (`_forceVP8`)。截获 Offer/Answer，在发往网络前用 `replaceAll` 强行禁用 H.264，逼迫双端底层回退到极其稳定的 VP8 软件编码器；同时本地 `setLocalDescription` 喂入原味 SDP 以防本地引擎解析崩溃。
  * 安卓解码器假死电击疗法: 彻底根治了 Android 退后台再回前台导致的画面永久冻结假死。通过深度监听 `AppLifecycleState.resumed`，触发“物理起搏器”：先置空 `srcObject` 再重新赋值，并瞬间拨动视频轨 `enabled` 开关，强迫系统级硬件解码器重启并重新请求关键帧。

* **[Memory] IPC 截断防御机制 (IPC Truncation Defense)**:
  * 修复坑点: 攻克了“接通后 1 秒离奇自动挂断”的世纪大坑。安卓系统原生层在通过 Intent Extras 向 Flutter 传递呼叫数据时，会因数据过大而强制丢弃巨型 SDP 文本，导致状态机拿到空数据引发防御性挂断。
  * 实现: 建立“内存级保险箱”。在信令刚到达 `CallDispatcher` 时，直接将完整的 CallEvent 存入 Dart 静态内存 (`currentInvite`)。用户接听时优先从内存提取 SDP，彻底绕开 Android 原生 IPC 通信的物理大小限制！

* **[Render] 画板自愈机制与时序阻断 (Renderer Self-Healing & Timing)**:
  * 修复坑点: 修复了主叫方（`startCall`）因忘记初始化 `RTCVideoRenderer` 导致有数据无画面的黑屏问题。
  * 实现: 在 `_initLocalMedia` 获取摄像头时引入自愈护盾：检测到画板为 null 时当场执行 `initialize()`。
  * Web 端双向失明防御: 彻底治愈了 Flutter Web 端接通必黑屏的绝症。强制在 `acceptCall` 阶段 `await Future.wait([local.initialize(), remote.initialize()])`，必须等待 HTML 底层 `<video>` 物理坑位挂载完毕，再让状态机放行视频流注入，达成 0ms 时序差。

* **[WebRTC] 无缝网络重连与防撞车 (ICE Restart & Glare Conflict)**:
  * 唯一重连指挥官: 攻克了 4G/WiFi 切换时，双端同时发送 Offer 导致的 `have-local-offer` 信令暴毙崩溃。 确立了强制规矩：仅允许主叫方 (`_isCaller`) 主动发起 ICE Restart，被叫方无权主动发 Offer 仅能回传 Answer。
  * 伪装信令拦截器: 挫败了 FCM 推送通道/后端自作聪明的“信令背刺”。在 `onIncomingInvite` 中精准拦截带有 `isRenegotiation` 标志且 Session 一致的假 Invite 信令，当场解包转化为 Answer 回传，防止重连简历被当成垃圾丢弃。
  * 真空期防御与智能解锁: 解决了断网瞬间收集“无网废弃 IP”导致永久卡死的盲区。通过 Socket 监听器建立 2 秒缓冲：死等新网卡彻底握手成功再收集 IP；同时监听 `disconnect` 瞬间砸碎防抖锁，确保错失的信令能无限次重试直到隧道打通。
  * 底层 C++ 方言强制唤醒: 攻克了 flutter_webrtc 在 Android 端忽视 `iceRestart: true` 指令的历史遗留 Bug。采用上古约束格式 `optional: [{'IceRestart': true}]` 强行命令 C++ 引擎收集新网络 IP。

---

## 🎥 第八章：实时音视频与跨端融合 (The RTC Era) **[v6.1.0]**

* **[RTC] 全栈实时引擎**: 基于 `flutter_webrtc` 构建点对点 (P2P) 通话链路。集成 Google STUN 与后端 TURN 服务确保 4G/5G 跨网穿透成功率。
* **[Signal] 高一致性信令**: 定义标准 SDP 交换流程，并在 `CallController` 引入 `_iceCandidateQueue` 缓冲队列，彻底攻克 ICE Candidate 提前到达导致的连接失败问题。
* **[UX] 悬浮窗与画中画**: 采用 `OverlayEntry` 实现全局悬浮窗 (`CallOverlay`)，支持边界限制拖拽，并独立监听通话状态实现结束后“幽灵窗口”自毁。
* **[Platform] 跨平台防御**: iOS 启用 Background Modes 结合 AVAudioSession 保活；在挂断逻辑中建立严格的多级销毁流 (`Timer -> Socket -> Overlay -> Stream -> PeerConnection -> Renderer`)，杜绝内存/摄像头泄漏。

---

## 👑 第七章：权力治理与信息流转 (Governance & Flow) **[v6.0.0]**

* **[Governance] 入群审批系统**: 引入 `joinNeedApproval` 开关与审批闭环。当管理员收到信令时触发状态机毫秒级同步红点，实现“审核中 -> 成员房”无缝切换。
* **[Database] 事务一致性守卫**: 在 `handleJoinRequest` 实施“先清理、后更新”策略（`deleteMany` + `upsert`），彻底消灭退群重申导致的 Prisma 主键冲突与数据库死锁。
* **[RBAC] 轻量级权限矩阵**: 基于 `OWNER/ADMIN/MEMBER` 体系，在后端设 `_checkPermission`，前端注 `canManage` 动态驱动 UI。
* **[Interact] 消息流转体系**: 封装通用选人组件，实现消息转发时 `meta` 属性（如媒体比例、原作者）的无损分发。并采用 `extraCodec` 彻底解决 Web 刷新路由参数丢失。
* **[Notice] 交互式全局通知 (Interactive Notification)**: 废弃原生生硬弹窗，基于 `BotToast` 构建应用内跨页面卡片 (`global_handler_ui`)。实现带有头像的好友申请提醒，并支持“一键直达”申请列表，极大缩短交互路径。
* **[Defense] 极端竞态防御**: 拦截系统通知类消息（type 99）触发的已读上报，攻克用户被踢瞬间丢失权限导致的 403 崩溃。

---

## 🛡️ 第六章：社交基建与性能优化 (Foundation Era) **[v4.0 - v5.0]**

* **[Social] 拼音搜索引擎**: 集成 `lpinyin`，实现联系人的本地拼音首字母/全拼极速索引。
* **[Perf] 接口风暴止血**: 优化会话列表，将请求数由 N+1 直接降为 1。
* **[UI] 现代化输入框**: `ModernChatInputBar`。
* **[LBS] 地图服务**: Web 端优化地图快照缓存 (`AutomaticKeepAliveClientMixin`) 减少内存抖动。

---

## 💎 第五章：后端解耦与触达 (Backend Era) **[v5.2.1]**

* **[Arch] 事件驱动**: 引入 `@nestjs/event-emitter` 实现后端模块解耦。
* **[FCM] 全平台触达**: 打通 Android (High Importance) 与 Web (Service Worker) 离线推送机制。

---

## 🏅 第四章：全能媒体与零感交互 (Media Era) **[v5.3.1]**

* **[Streaming] 全链路流式缓冲**: 客户端 Range 头 + Nginx 代理配置，实现大视频点击即播。
* **[Cache] 三级播放策略**: 内存 -> 本地 Asset -> 网络 URL。
* **[Web] 物理隔离**: Web 端使用 Canvas 截帧、Blob URL 文件处理、右键菜单屏蔽，并自动清理死链 Blob。
* **[Audio] 物理级语音交互 (Voice Recording UX)**: 重构了录音链路。在 `RecordingOverlay` 中引入 `IgnorePointer` 穿透修复手势冲突；并在 `VoiceRecordButton` 实施双端隔离（Web 端点击发送，移动端长按录制+上滑 50px 阈值取消）。
* **[Video] 全局播放互斥锁 (Global Playback Lock)**: 引入 `ValueNotifier<String?> _playingMsgId` 建立全局唯一播放锁。点开新视频时自动静音/暂停旧视频，杜绝信息流中的“大合唱”现象并防止 OOM 内存雪崩。

---

## 🥉 第三章：高可靠流水线与数据防御 (Reliability Era)

* **[Engine] 五级跳管道**: Parse -> Persist -> Process -> Upload -> Sync。
* **[Defense] 数据库合并防御**: 本地高清资产优先。服务端回包 Sync 时强制保留发送时的 `localPath` 和 `previewBytes`。
* **[Retry] 离线自动重发**: 网络恢复瞬间利用 `OfflineQueueManager` 自动冲刷失败队列。

---

## 🥈 第二章：全局一致性与状态感知 (Consistency Era) **[v5.3.0 - v5.3.1]**

* **[Zero-State] 自愈防线**: 列表页强制 `_fetchList`，房间页引入核弹级清零 `forceClearUnread`。
* **[Read] 实时已读回执**: 500ms 防抖 (Debounce) 已读上报。
* **[UX] 乐观 UI 预先插入 (Optimistic UI)**: 在发起单聊 (`create_direct_chat_dialog`) 成功后，绕过 Socket 等待，强制在本地伪造 `Conversation` 对象压入列表并瞬间跳转，实现真正的“零延迟”视觉欺骗与交互体感。

---

## 🏆 第一章：极致视觉与黄金参数 (The Visual Revolution) **[v5.3.2 - v5.3.3]**

* **[Tuning] 黄金参数**: Preload Window: 15 / Item Height: 300.0 / Look-Back: 15 / LoadMore Threshold: 2000。
* **[Image] 视觉兜底**: 利用 `AppCachedImage` 引入 Stack 物理堆叠，搭配 `BlurHash` 实现无白屏渐进加载。
* **[Time] NTP 高精校准**: `ServerTimeHelper` 确保全量逻辑时间戳绝对对齐。

---

## ⚖️ 架构铁律 (The Iron Rules - v6.6.0)

*这是项目的最高准则，任何代码提交不得违反。*

1. **数据类型严谨原则**: 后端 API 返回的时间戳必须统一转换为 number (毫秒)，严禁在 DTO 中直接返回 Date 对象。
2. **审批幂等原则**: 涉及状态变更的后端逻辑必须在单次事务中先清理潜在冲突记录。
3. **UI 状态同步原则**: 所有的红点计数与状态变更必须收口于 ChatGroup Provider，禁止 UI 层维护独立计数器。
4. **Web 分享安全原则**: Web 端处理图片分享时，必须确保 mimeType 正确，并对跨域图片采取隐藏或降级策略。
5. **权限权威原则**: 所有群组变更操作必须经过后端 `_checkPermission` 与前端 `canManage` 校验。
6. **异步拦截原则**: 所有 Handler/Controller 必须包含 `_isDisposed`/`mounted` 检查，严禁页面销毁后执行异步回调。
7. **系统消息免报原则**: 类型为 99 的系统通知严禁触发已读上报 (`markAsRead`)。
8. **路由参数安全原则**: 复杂对象传递必须实现 `BaseRouteArgs` 并注册 `extraCodec`。
9. **路径相对化原则**: 数据库持久化严禁存储绝对路径，必须通过 `AssetManager` 运行时还原。
10. **数据防御原则**: merge 操作必须优先保留本地的高清资产路径。
11. **单向数据流**: UI 只读 DB，Pipeline/Repo 负责写 DB。
12. **服务端权威原则**: 当服务端返回 `unread=0` 时，本地必须无条件强制清零。
13. **指纹对齐原则**: 跨页面复用媒体缓存，URL 和 Headers 必须字符级匹配。
14. **视觉兜底原则**: 图片加载必须使用 Stack 垫片，严禁白屏。
15. **时间统一原则**: 所有逻辑判断必须使用 `ServerTimeHelper.now()`。
16. **Web 环境隔离**: 非 `kIsWeb` 保护下，严禁调用 `dart:io`。
17. **插件隔离原则**: 任何涉及原生能力的插件，必须使用平台判定，严禁在不支持的平台上执行初始化。
18. **ICE 缓存原则**: WebRTC 信令处理中，严禁在 SetRemoteDescription 完成前直接添加 ICE Candidate，必须使用队列缓存。
19. **资源释放原则**: 视频通话结束时，必须显式调用 `MediaStreamTrack.stop()` 并置空 `srcObject`，严防指示灯残留。
20. **跨进程大对象免疫 (IPC Payload Immunity)**: 严禁依赖移动端原生层（Intent）传递超大文本（SDP），必须在 Dart 内存层建立单例拦截。
21. **硬件编码降级 (Codec Fallback)**: 面对国内深度定制安卓机硬件编码器残废陷阱，必须强制将发送配置回退至 VP8 软解。
22. **硬件预热规避 (Hardware Warm-up)**: 安卓端在锁屏被 CallKit 唤醒接听时，严禁同步瞬间抢夺摄像头，必须给予 1 秒底层解封延迟。
23. **重协商唯一指挥官 (Renegotiation Commander)**: 物理网络切换触发 ICE Restart 时，全局状态机必须校验 `_isCaller`，唯有主叫方拥有重连发起权。
24. **解码器物理唤醒 (Codec Defibrillator)**: 生命回复 `resumed` 时，严禁信任原生渲染管线。必须强制对 `srcObject` 实施“剥离再挂载”及轨道的瞬断重启。
25. **DOM 就绪阻断 (DOM Readiness Blocking)**: Web 端渲染前必须通过 `await Future.wait` 强制等待双端画板底层物理节点构建完毕，防秒接黑屏。
26. **底层 C++ 强校验约定**: 调用 Android 端 `createOffer` 强制重连时，必须回退使用老式字典约束 `optional: [{'IceRestart': true}]`。
27. **音频焦点强制夺回原则 (Audio Focus Preemption)**: 遭遇系统级高优先级音频（如电话/闹钟）打断并结束后，严禁被动等待，必须通过 `session.setActive(true)` 强行向系统重新申请焦点，防止麦克风永久静音假死。
28. **硬件路由自适应约束 (Adaptive Audio Routing)**: 严禁仅在初始化阶段绑定音频路由，必须部署全局守护进程实时监听 `devicesChangedEventStream`。一旦侦测到外设热插拔，必须立即触发通道切换并反向同步 UI。
29. **全局媒体互斥锁 (Global Media Lock)**: 列表页中严禁多媒体文件并发播放。必须引入全局监听（如 `_playingMsgId`），触发新播放时强制中止旧任务，防止音频重叠与 OOM。
30. **外部部署权限显式声明原则 (Explicit Deployment Permissions)**: 自动化流水线严禁使用默认低权令牌。必须在 Workflow 级别显式声明 `deployments: write`，以打通 GitHub 与外部服务（如 Cloudflare）的通信闭环。
31. **CI 构建环境预热原则 (CI Build Priming)**: 在 CI 执行 Web 构建前，必须显式调用 `flutter config --enable-web`。严禁在未确认环境能力的条件下执行复杂的渲染参数指令，防止 Shell 级参数解析崩溃。
32. **网关入口收口原则 (Gateway Entry Consolidation)**: 即使采用云端自动部署，流量入口必须始终锁定在后端 Nginx 手中。严禁绕过后端目录下的 `nginx.conf` 直接访问静态源，确保 SSL 卸载、动态拦截（`/share.html`）与静态分发的物理链路绝对一致。
33. **单轨流水线原则 (Single-Track Pipeline)**: 针对 Self-hosted 物理机构建，严禁使用云端常见的多 Job 拆分逻辑。必须将多端编译（Web + Android）合入单一 Job，以规避重复执行 `checkout` 与环境初始化的时间黑洞。
34. **Firebase CLI 假死豁免原则 (CLI Exit Code Exemption)**: 在 macOS 环境下执行 `appdistribution:distribute` 时，必须在命令末尾强行追加 `|| true`，以豁免工具链内部 Bug 导致的 Exit Code 2 误报，确保流水线顺畅流转。 *(注：由于引入新校验标准，此规则在 v6.6.0 已被强制废除，参见规则 38)*
35. **双轨闭环与战报必达原则 (Always-on Notification & Artifacts)**: 自动化配置中必须包含 `actions/upload-artifact` 兜底下载通道；同时 Telegram 通知步骤必须附加 `if: always()` 守护指令，确保无论成功与否，战报与扫码海报必须 100% 触达开发者手机。
36. **密钥过河拆桥原则 (Token Revocation Security)**: 严禁将任何明文 API Key（包括 Telegram Token、Firebase 令牌等）提交或遗留在代码与外发对话中。一旦发生潜在泄露，必须立即利用提供方后台接口执行撤销 (`/revoke`) 操作，并在 GitHub Secrets 中重置。

**[👇 以下为 v6.6.0 企业级环境与热更战役新增铁律 👇]**

37. **绝对环境隔离原则 (Absolute Environment Isolation)**: 凡涉及云端或物理机 CI 执行环境，严禁使用全局配置的 Flutter 引擎。必须显式注入并执行 `fvm install`，一切编译基准必须与根目录 `.fvm/fvm_config.json` 强绑定。
38. **假绿灯零容忍原则 (Zero Tolerance for Fake Success)**: 在关键分发阶段（如 Firebase 上传），严禁使用 `|| true` 或 `|| echo` 试图掩饰系统报错。必须通过代码精确提取产物特征并验证，一旦发现异常，必须当场执行 `exit 1` 中断流水线暴露问题。
39. **架构降维分发原则 (Architecture Fallback Distribution)**: 面对外部平台（如 Google Play）账号联调阻断 AAB 上传时，禁止停工等待。必须在 Shorebird 构建阶段显式声明 `--artifact apk`，产出含全架构 CPU 指令的 Fat APK 进行强行突围测试，优先保证业务闭环。
40. **热更基石与补丁独立原则 (OTA Patch Independence)**: 常规发版必须跟随主分支 CI 流程生成 Base 产物。任何试图下发 Shorebird Patch 的操作，严禁自动化挂载。必须通过独立的 `hotfix_patch.yml` 并限定 `workflow_dispatch` 纯手动触发，防范未经测试的补丁污染生产环境。
41. **智能配置路由原则 (Smart Config Routing)**: 流水线中严禁人工干预修改环境变量。必须通过对 `$GITHUB_REF` 的自动判别（Branch `test` vs Tag `v*`），实现 `test.json` 与 `prod.json` 的无感注入与动态编译，消除人为切错环境的严重事故风险。

```