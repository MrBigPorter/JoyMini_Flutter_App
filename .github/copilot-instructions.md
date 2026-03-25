# Lucky Flutter App — Copilot 工作指令

> **重要**: 每次对话先看 `## 🎯 当前任务`，按阶段推进，不做计划外实现。

---

## 🎯 当前任务（每次对话从这里开始）

**阶段**: Phase F1 — Flutter 商业链路闭环  
**上次停留**: Lucky Wheel UX 优化完成（2026-03-25）  
**已完成**:
- [x] 客服分流参数化：`CustomerServiceHelper.startChat()` 支持 `support/business` 场景与可配置 `businessId`
- [x] Lucky Draw API 接入：`my-tickets` / `draw` / `my-results`
- [x] Lucky Draw 页面与路由：券列表、抽奖执行、历史结果（基础骨架）
- [x] Flash Sale 前端态补齐：秒杀价、倒计时、库存、结束态
- [x] 结算透传秒杀标识（如 `flashSaleProductId`，以后端 contract 为准）并统一支付/订单价格文案
- [x] 为以上改动补最小测试（Provider/Widget）与关键错误态
- [x] OAuth 对接基础层：`google/facebook/apple` API + Model + Provider（不含 UI/SDK）
- [x] Admin 对接说明文档：`admin/FLUTTER_OAUTH_INTEGRATION_GUIDE_CN.md`
- [x] 启动 Logo 统一规划文档：`STARTUP_LOGO_UNIFICATION_PLAN.md`
- [x] 自动化测试学习手册：`AUTOMATED_TESTING_MANUAL.md`
- [x] OAuth 登录 UI 闭环：登录页三方按钮 + loading/错误态 + 邀请码透传
- [x] OAuth 平台 SDK 接入：Google/Facebook/Apple（按平台条件显示）
- [x] OAuth 最小测试补齐：Provider 失败态 + 登录页 Widget 分支
- [x] `auth` 字段对齐清理：`avatar/avartar`、`Profile.lastLoginAt` 类型与后端一致

**当前迭代 — Lucky Draw UI 闭环（2026-03-24）**:
- [x] 抽奖结果弹窗：`LuckyDrawResultDialog`，4 种奖品类型不同样式（优惠券/金币/余额/谢谢参与）（2026-03-24）
- [x] 奖品类型图标/徽章：票券列表与结果列表展示 `prizeType` 对应图标与颜色（2026-03-24）
- [x] 票券过期时间显示：`expiredAt` 字段展示，临近过期（24h 内）高亮红色（2026-03-24）
- [x] 无限滚动/加载更多：`luckyDrawTicketsProvider` + `luckyDrawResultsProvider` 支持分页（2026-03-24）
- [x] 订单完成后"获得抽奖券"提示 Banner：在订单结果页展示，点击跳转抽奖页（2026-03-24）
- [x] Socket 推送闭环：`lucky_draw_ticket_issued` 事件处理 → badge +1 + 通知卡片 + 跳转；`group_success` 兜底刷新；FCM `lucky_draw` 冷启动路由；Me 页菜单入口带红点 badge（2026-03-24）
- [x] Lucky Wheel UX 优化：进入页说明卡 / 抽奖中状态分层 / 抽奖后结果动作 / 成功回传刷新 / 小屏自适应 / 最小 Provider+Widget 测试（2026-03-25）
- [x] 修复抽奖结果弹窗不显示问题：修复 `LuckyDrawActionResult.fromJson` 方法处理 `isWin` 字段，添加调试日志跟踪弹窗显示流程（2026-03-25）
- [x] 修复幸运轮动画卡住问题：修复 `_LuckyWheelState._onResult` 动画控制器逻辑，确保动画完成时弹窗正常显示（2026-03-25）
- [x] 修复幸运轮动画不运行问题：修复动画控制器 vsync 问题，在 `_LuckyWheelState` 中创建本地动画控制器确保正确运行（2026-03-25）
- [x] 修复大转盘完全不转问题：修复连续旋转动画设置，添加 `_rotationAnimation` 监听器更新角度（2026-03-25）
- [x] 优化转盘动画流畅度：增加旋转圈数至8-11圈，延长动画时间至5.5秒，增加视觉流畅感（2026-03-25）
- [x] 修复转盘动画完成监听器问题：修复动画状态监听器，确保弹窗在动画完成后立即显示（2026-03-25）
- [x] 完全修复动画根本不运行问题：修复动画控制器启动逻辑，简化监听器管理，移除复杂重置逻辑，确保动画正确运行（2026-03-25）
- [x] 修复导航器状态错误问题：使用安全导航方法（`maybePop`），添加导航器状态检查，防止导航栈为空时崩溃（2026-03-25）

> 最后对齐时间：2026-03-25。完成一项就地打勾并更新时间。

---

## 一、项目全景（Flutter 视角）

| 维度 | 详情 |
|------|------|
| **主应用** | `flutter_happy_app`（Flutter） |
| **Dart/Flutter 管理** | FVM（见 `FVM_README.md`） |
| **路由** | GoRouter（`lib/app/routes/app_router.dart`） |
| **状态管理** | Riverpod（主）+ 局部 Provider 兼容 |
| **网络层** | `lib/core/api/lucky_api.dart` + 统一 `Http` 封装 |
| **实时通信** | Socket + 本地消息库（Chat 场景） |
| **平台目标** | iOS / Android / Web / Desktop（按目录存在） |
| **发布与热更新** | CI + Shorebird（见 `shorebird.yaml` / workflows） |

---

## 二、关键技术约定（Flutter 必须遵守）

### 1) 分层与职责
- UI 在 `lib/app`、`lib/ui`；业务逻辑优先进入 Provider/Notifier，不把复杂逻辑堆在 Widget。
- API 访问统一走 `lib/core/api/lucky_api.dart`，不要在页面中直接拼 URL。
- 新接口必须补齐 `core/models` 类型与 `fromJson/toJson`，避免 `Map<String, dynamic>` 裸奔。

### 2) 路由与参数安全
- 路由统一走 GoRouter：`lib/app/routes/app_router.dart`。
- 复杂参数必须走已注册 codec（`extra_codec.dart` + `RouteArgsRegistry`）。
- 禁止页面内硬编码跳转字符串参数格式；公共跳转逻辑提取到 helper/service。

### 3) 状态管理
- 业务状态默认放 Riverpod（Notifier/Provider），页面仅做渲染与交互分发。
- 一个业务实体仅保留一个“单一事实源”，避免页面局部状态与 Provider 双写。
- 对支付/库存/倒计时类状态，必须保证实时态覆盖初始化态，避免价格错位。

### 4) 聊天与媒体一致性
- `Chat` 发送主链路当前以 REST 为准，Socket 主要负责实时分发与同步。
- 图片/视频/音频 meta 字段必须对齐 `Chat Service.md` 规范。
- `duration` 当前按秒处理；无充分理由不要改毫秒。
- 封面字段优先级保持：`remote_thumb > thumb`。

### 5) 代码生成与资源生成
- 改动 `json_serializable` / Riverpod 注解模型后，必须执行生成流程（`build_runner` 或项目脚本）。
- 改动设计 token / 主题映射后，执行 `tool/generate.sh`（或对应子脚本）并提交产物。
- 禁止手改 `*.g.dart` 生成文件中的业务逻辑。

---

## 三、测试规范（Flutter）

### 测试分层
- **Unit**: 纯 Dart 逻辑（价格计算、参数转换、状态机）。
- **Widget**: 页面交互和渲染分支（空态/错误态/加载态）。
- **Integration**: 关键业务链路（登录、下单、抽奖、聊天入口）。

### 本阶段最低要求
- 新增 API/Provider 必须有最小单测。
- 页面新增关键分支（空态、失败重试、禁用态）必须有 Widget 测试覆盖。
- 修 bug 必须补回归测试，防止二次回归。

### 高频禁令
- 禁止只改 UI 不补状态/接口错误态处理。
- 禁止把异步异常吞掉（必须有 toast/log/fallback 之一）。
- 禁止新增不可测的强耦合逻辑（比如页面直接依赖全局单例且无法 mock）。

---

## 四、业务现状与缺口（Flutter）

### 已具备
- 聊天基础链路可用：会话列表、消息收发、socket 同步、客服入口（当前为单业务入口）。
- 下单支付主链路可用：`OrdersCheckoutParams` + 购买状态管理。

### 当前关键缺口
- 客服 `support/business` 分流未参数化（仍有写死入口）。
- Lucky Draw 在后端已提供接口，Flutter 侧闭环页面与 API 缺失。
- Flash Sale 展示与结算透传未完全对齐，存在前后端价态不一致风险。

---

## 五、实施优先级（Phase F1）

| 方向 | 说明 | 优先级 |
|------|------|--------|
| Lucky Draw 闭环 | API + 页面 + 路由 + 结果展示 | 🔴 高 |
| Chat 分流 | support/business 场景参数化与入口治理 | 🔴 高 |
| Flash Sale 闭环 | 展示态 + 结算透传 + 价格一致性 | 🔴 高 |
| 测试补齐 | Provider/Widget 最小回归 | 🟡 中 |
| 体验增强 | 抽奖提醒、客服上下文、文案统一 | 🟢 低 |

---

## 六、已知风险（Flutter 侧）

| 问题 | 级别 | 当前状态 |
|------|------|----------|
| 客服入口写死 businessId，无法按场景分流 | 🔴 高 | 待处理 |
| 秒杀价展示与结算参数不同步 | 🔴 高 | 待处理 |
| 抽奖接口存在但前端无闭环，活动价值无法落地 | 🔴 高 | 待处理 |
| 媒体 meta 字段不统一导致 Admin/Client 渲染差异 | 🟡 中 | 规范已出，待严格执行 |
| 生成文件未及时更新导致假错误或运行时问题 | 🟡 中 | 持续约束 |

---

## 七、工作原则（每次对话必须遵守）

0. **输出语言**：所有回复、注释、文档一律使用**中文或英文**。严禁出现韩文（한국어）或其他非中英文字符。
1. **先看 `🎯 当前任务` 再编码**，不做阶段外扩散。
2. **每完成一个 checkbox 立即更新本文件**（`[ ]` -> `[x]`），并更新时间。
3. 路由改动必须同步检查 `app_router.dart`、参数 codec、页面入口三处一致。
4. 新增/变更接口必须同时提交：API 封装 + 模型 + 错误态处理。
5. 改动注解模型后必须执行代码生成流程，并提交生成结果。
6. 改动聊天媒体协议时，必须同步核对 `Chat Service.md` 的字段约定。
7. 涉及价格/库存/倒计时的逻辑，必须提供最小回归测试。
8. 平台差异能力（Web/Native）必须做条件隔离，不得硬编码单平台实现。
9. 未验证的假设要在 PR/文档明确标注，不得当作既成事实写入实现。
10. 文档优先以当前仓库代码为准；冲突时先核代码再更新文档。
