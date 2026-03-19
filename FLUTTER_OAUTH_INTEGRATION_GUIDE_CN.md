# Flutter 登录对接精华版（OAuth + Email OTP）

> 仅保留 Flutter 实施必需信息：接口契约、平台配置边界、H5 开关策略、最小回归。  
> 代码优先：以 `admin/auth/*.ts` 实际实现为准。

---

## 0. 本次更新（2026-03-19）

- 已确认后端兼容 Flutter H5 的 OAuth 字段差异：
  - Google：支持 `idToken` 或 `credential`
  - Facebook：支持 `userId` 或 `userID`
- 已确认后端启用 `CORS_ORIGIN` 白名单（Flutter Web 需加入运行域名/端口）。
- 已补充 Google Web 官方基线：
  - Web 不支持 `GoogleSignIn.authenticate()`，需避免调用。
  - 官方推荐交互入口是 `renderButton`。
  - `attemptLightweightAuthentication()` 适合作为 One Tap/FedCM 轻量尝试，不建议作为唯一点击登录入口。
- 结论：后端兼容层已到位，当前优先事项是 Flutter Web 登录链路按官方方案收敛。

---

## 1. 当前状态（2026-03-19）

- 后端已支持：
  - OAuth：`google` / `facebook` / `apple`
  - Email OTP：`email/send-code` / `email/login`
- Flutter 已完成：
  - OAuth API/Model/Provider/UI 基础闭环
  - H5 按能力显示按钮（未配置时按钮禁用/隐藏，避免 MissingPlugin）
  - `auth` 字段对齐：`avatar/avartar` 兼容、`Profile.lastLoginAt` 时间戳对齐
- Flutter 待持续增强：
  - Email OTP 体验细节（文案、错误码映射、倒计时体验）
  - H5 Apple 登录（当前后置）

---

## 2. 接口契约（必须对齐）

### 2.1 登录接口

| 接口 | 方法 | 请求体 |
|------|------|--------|
| `/api/v1/auth/oauth/google` | POST | `{ idToken, inviteCode? }`（兼容 `{ credential }`） |
| `/api/v1/auth/oauth/facebook` | POST | `{ accessToken, userId, inviteCode? }`（兼容 `userID`） |
| `/api/v1/auth/oauth/apple` | POST | `{ idToken, code?, inviteCode? }` |
| `/api/v1/auth/email/send-code` | POST | `{ email }` |
| `/api/v1/auth/email/login` | POST | `{ email, code }` |

### 2.4 后端已做的 H5 兼容（2026-03-19）

- Google：`idToken` 和 `credential` 二选一都可。
- Facebook：`userId` 与 `userID` 都可，后端统一归一化。
- CORS：后端启用 `CORS_ORIGIN` 白名单，Flutter Web 需把运行域名加入该变量。

> 注意：兼容字段只是降低前端接入成本，不建议前端长期依赖多种字段写法。

### 2.5 请求体示例（可直接联调）

Google（标准写法）

```json
{
  "idToken": "eyJ...",
  "inviteCode": "ABCD12"
}
```

Google（H5 兼容写法）

```json
{
  "credential": "eyJ..."
}
```

Facebook（标准写法）

```json
{
  "accessToken": "EAAB...",
  "userId": "10200123456789"
}
```

Facebook（H5 兼容写法）

```json
{
  "accessToken": "EAAB...",
  "userID": "10200123456789"
}
```

### 2.2 会话接口

| 接口 | 方法 | 请求体 |
|------|------|--------|
| `/api/v1/auth/refresh` | POST | `{ refreshToken }` |
| `/api/v1/auth/profile` | GET | Bearer Token |

### 2.3 返回关键字段

- 所有登录成功都应回到统一流程：`tokens.accessToken` + `tokens.refreshToken`。
- OAuth 返回 `provider`。
- Email 登录可能包含 `email`、`countryCode: "EMAIL"`。
- `send-code` 在非生产可能返回 `devCode`（生产不可依赖）。

---

## 3. Flutter 对接落点（单一事实源）

- API：`lib/core/api/lucky_api.dart`
- Model：`lib/core/models/auth.dart`
- Provider：`lib/core/providers/auth_provider.dart`
- 登录页：`lib/app/page/login_page.dart`
- 平台能力：`lib/core/services/auth/oauth_sign_in_service.dart`
- 配置：`lib/core/config/app_config.dart`

---

## 4. 平台配置边界（最重要）

### 4.1 客户端应该放什么

- 放：`client_id` / `app_id`（公开标识）
- 不放：`client_secret` / 私钥

### 4.2 后端应该放什么

- 至少：`GOOGLE_CLIENT_ID`、`APPLE_CLIENT_ID`
- 后端负责 token 最终校验与签发业务 JWT

### 4.3 App 端

- Google：`google-services.json` / `GoogleService-Info.plist`
- Facebook：Android/iOS 平台配置
- Apple：iOS/macOS capability

### 4.4 H5 端（当前策略）

- Google：`GOOGLE_WEB_CLIENT_ID` 非空 -> 允许展示入口（不代表实现方式已符合官方标准）
- Facebook：`FACEBOOK_WEB_APP_ID` 非空 -> 按钮可用
- Apple：Web 仍后置（暂不开放）

后端 CORS 需要包含 Flutter Web 实际运行域名（示例）：

```bash
CORS_ORIGIN=http://localhost:3000,http://127.0.0.1:3000,http://localhost:5173,http://127.0.0.1:5173,http://localhost:64979,https://admin.joyminis.com,https://dev.joyminis.com
```

> 若 Flutter Web 用随机端口调试，请同步追加到 `CORS_ORIGIN`，否则浏览器会被 CORS 拦截。

### 4.5 Google Web 官方标准方案（必须对齐）

`官方推荐主链路`
1. 调用 `GoogleSignIn.instance.initialize(clientId: ...)`，并确保全页面仅初始化一次。
2. 使用 `renderButton` 作为用户点击登录入口。
3. 从认证事件拿到 `GoogleSignInAccount` 后读取 `idToken`，提交 `/api/v1/auth/oauth/google`。

`关键解释`
- `authenticate()` 在 Web 会抛 `UnimplementedError`，这是插件设计，不是业务代码 bug。
- `attemptLightweightAuthentication()` 内部是 One Tap/FedCM `id.prompt()` 轻量触发，回调时序不保证等价于“按钮点击即成功返回”。
- 因此 Web 端建议：`renderButton` 负责主交互，One Tap 只做增强能力。

运行示例：

```bash
cd /Volumes/MySSD/work/dev/flutter_happy_app
fvm flutter run -d chrome \
  --dart-define=GOOGLE_WEB_CLIENT_ID=your-google-web-client-id.apps.googleusercontent.com \
  --dart-define=FACEBOOK_WEB_APP_ID=your_facebook_app_id \
  --dart-define=FACEBOOK_WEB_SDK_VERSION=v19.0
```

---

## 5. 登录流程统一规则

1. 调第三方 SDK 或 Email OTP 接口。
2. 调后端登录接口（OAuth/Email）。
3. 统一保存 token。
4. 统一拉取 `/auth/profile`。
5. 进入首页。

> 不允许每种登录方式各搞一套登录后逻辑。

---

## 6. 风险与处理

- `MissingPluginException` / `UnimplementedError`：
  - 原因：Web 调用了未配置/未支持插件能力
  - 处理：使用能力开关 + 按钮禁用/隐藏
- Facebook/H5 授权失败：
  - 检查 `FACEBOOK_WEB_APP_ID` 与平台控制台域名回调配置
- Google 401/audience mismatch：
  - 前端 Web client id 与后端 `GOOGLE_CLIENT_ID` 对齐
- Email OTP 失败：
  - 处理频控、过期、错误码提示，不吞异常

### 6.1 Google Web 日志分级（联调基线）

`正常提示（可记录，不作为故障）`
- `FedCM mode supported`
- `enable_itp_optimization ...`
- `cancel_protect_start` / `cancel_protect_end`

`风险信号（需优先修复）`
- `google.accounts.id.initialize() is called multiple times`
- 同次登录存在并发触发（重复点击/重复请求）
- 长时间无 SignIn 事件并最终 timeout

### 6.2 `origin_mismatch` 快速排查（Error 400）

该错误是 Google Cloud OAuth 配置问题，不是后端登录接口问题。

`必须检查`
1. 当前运行 origin（例如 `http://localhost:4000`）是否加入该 Web Client 的 **Authorized JavaScript origins**。
2. `GOOGLE_WEB_CLIENT_ID` 对应的是否是 **Web application** 类型的 OAuth Client。
3. 协议/域名/端口是否完全一致（`http` vs `https`、`localhost` vs `127.0.0.1`、端口号）。
4. 本地调试常见 origin 是否全部加入：
   - `http://localhost:4000`
   - `http://127.0.0.1:4000`
   - `http://localhost:3000`
   - `http://127.0.0.1:3000`

`注意`
- JavaScript origin 只填源，不要带路径（不要写 `/login`）。
- 控制台改完通常需等待 1-5 分钟生效，建议无痕窗口复测。

### 6.3 Google Web 运行期自检（建议保留）

为减少联调反复，建议在 debug 日志固定打印：
- 当前 `window.location.origin`
- 当前 `GOOGLE_WEB_CLIENT_ID` 前 10-12 位（脱敏）
- `initialize` 是否命中 only-once 守卫

最小诊断结论映射：
- `origin_mismatch` -> 先查 Google Cloud JavaScript origins
- `initialize() is called multiple times` -> 查前端重复初始化/多入口触发
- 长时间无 SignIn 事件 -> 查 `authenticationEvents` 监听时机与并发触发

---

## 7. 迁移计划（先文档对齐，再代码落地）

### Phase A：最小改动止血 ✅ 已完成（2026-03-19）

1. ✅ 保证 Google initialize 全页面 only-once（sessionStorage + localStorage 双存储守卫）。
2. ✅ 增加登录 in-flight 锁（`_socialOauthInFlight`），loading 期间禁止重复触发。
3. ✅ `OauthSignInService.signInWithGoogle()` 加并发请求级复用，防止同时发起多个登录流。

### Phase B：官方标准化收敛 ✅ 已完成（2026-03-19）

1. ✅ 新增平台条件按钮封装：`google_web_button.dart` / `_stub` / `_web`（`dart.library.js_interop` 条件导出）。
2. ✅ Web 主入口切换为 `renderButton`（GIS SDK 官方按钮）：凭据通过 `authenticationEvents` 流推送，绕过 `attemptLightweightAuthentication` 不稳定链路。
3. ✅ 登录页新增 `_initGoogleWebAuth()` + `_handleGoogleWebAccount()`：直接监听 `authenticationEvents` 流，拿到 `idToken` 后复用现有 Provider + token 保存链路。
4. ✅ Native 保持原有自定义按钮 + `signInWithGoogle()` 链路不变。
5. ✅ 后端契约不变：`idToken → /api/v1/auth/oauth/google`。

### 验收标准

1. 日志不再出现重复 initialize 警告。
2. 点击 Google 后可在合理时间内成功登录或明确失败（无静默卡死）。
3. 热重载后首次点击、连续点击、刷新后首次点击都可稳定返回。

---

## 8. 后端是否还需要改（结论）

短结论：**当前这批 Flutter H5 问题，后端已做必要兼容，不需要继续改后端核心逻辑。**

优先排查顺序（90% 问题在这里）：

1. `CORS_ORIGIN` 是否包含 Flutter Web 当前域名和端口。
2. Google Web Client ID 是否与后端 `GOOGLE_CLIENT_ID` 一致（避免 audience mismatch）。
3. Facebook 控制台里的域名/回调配置是否与当前 Web 域名一致。
4. 前端请求体是否命中后端支持字段（`idToken|credential`、`userId|userID`）。

仅当以上都正确仍失败，再考虑新增后端日志字段或 provider 级诊断增强。

---

## 9. 最小回归（提交前必须跑）

```bash
cd /Volumes/MySSD/work/dev/flutter_happy_app
./tool/test_login_regression.sh
```

重点覆盖：
- OAuth/Email 模型解析
- 登录页按钮分支与模式切换
- 商业链路回归（防连带破坏）

---

## 10. 本文档维护原则

- 只保留当前可执行信息，不保留历史设计推演。
- 新增登录方式时，仅更新本文件和对应代码，不再新增平行“登录文档”。

---

## 11. 对接经验总结（新手可读）

这次 Google/Facebook/Apple + Web 对接的核心经验，可以记成一句话：

`先配对平台，再保证单一登录链路，再做错误定位。`

### 11.1 先搞清楚“哪类问题”

`配置问题（最常见）`
- 典型报错：`origin_mismatch`、`audience mismatch`。
- 处理方向：Google Cloud/Facebook 控制台配置，不是先改业务代码。

`实现问题`
- 典型现象：按钮不显示、点击后无回调、重复初始化告警。
- 处理方向：前端平台分支、初始化时机、事件监听时机。

### 11.2 Web Google 登录的正确心智模型

1. `initialize` 只应成功执行一次（其余命中 guard 跳过）。
2. Web 主入口用 `renderButton`，不要把自定义按钮当唯一入口。
3. 最终凭据从 `authenticationEvents` 流拿，拿到 `idToken` 再调后端登录。

### 11.3 这次最容易踩坑的点

1. `origin_mismatch`：当前 origin 不在 Google Web Client 白名单。
2. `initialize() called multiple times`：多入口初始化或热重载时状态未守卫。
3. 条件导出选错：Web 误走 stub，导致按钮区域为空。
4. 把“取消登录”当错误弹窗：取消应静默处理，避免打扰用户。

### 11.4 新手可直接照抄的排查顺序（3 分钟版）

1. 看浏览器报错是不是 `origin_mismatch`；如果是，先改控制台 origin。
2. 看日志有没有 `initialize() called multiple times`；有就先清重复初始化。
3. 看是否收到 `SignIn` 事件；没有则查监听时机和按钮入口。
4. 收到 `idToken` 但登录失败，再查后端接口和 token 校验。

### 11.5 推荐保留的调试日志（开发环境）

- 当前 `origin`（例如 `http://localhost:4000`）
- `GOOGLE_WEB_CLIENT_ID` 脱敏头部 + 长度
- 初始化触发源（`trigger`）
- 是否命中初始化 guard（`skipped – storage guard hit`）
- 是否收到 `SignIn` 事件

### 11.6 给新同学的最小实践清单

- [ ] 先确认 `.env`/`dart-define` 的 `GOOGLE_WEB_CLIENT_ID` 不为空。
- [ ] 先确认 Google Cloud Console 的 JavaScript origins 已包含当前端口。
- [ ] Web 端只保留一条主登录链路（官方按钮 + events）。
- [ ] 对取消登录静默处理，对配置错误给明确提示。
- [ ] 成功后统一走：保存 token -> 拉 profile -> 进入首页。

### 11.7 掌握这些，就可以“完全接入 Google 登录”

如果你是新同学，只要把下面 6 件事吃透，就能独立完成从 0 到可上线的 Google 登录对接。

1. `平台配置能力`
   - 知道 App 和 Web 分别要配什么：
     - App：`google-services.json` / `GoogleService-Info.plist`
     - Web：`GOOGLE_WEB_CLIENT_ID`
   - 知道客户端不放 `client_secret`。

2. `Google Cloud Console 配置`
   - 会创建并识别 Web 类型 OAuth Client。
   - 会配置 **Authorized JavaScript origins**，并保证与实际运行 origin 完全一致。
   - 看到 `origin_mismatch` 时能第一时间定位到控制台配置。

3. `Flutter 端标准登录链路`
   - 会用 `GoogleSignIn.instance.initialize(...)` 初始化（只初始化一次）。
   - 知道 Web 端主入口是 `renderButton`，不是 `authenticate()`。
   - 会从 `authenticationEvents` 拿 `GoogleSignInAccount`，再提取 `idToken`。

4. `业务对接链路`
   - 会把 `idToken`（及可选 `inviteCode`）提交到 `/api/v1/auth/oauth/google`。
   - 会在登录成功后统一执行：保存 token -> 拉取 `/auth/profile` -> 进入首页。

5. `故障诊断能力`
   - 会看 3 类关键日志：
     - `origin` / `clientIdHead`
     - `initialize trigger` 与 `storage guard`
     - `SignIn` 事件是否到达
   - 能区分“配置错误”与“代码时序错误”。

6. `回归验证能力`
   - 会验证 4 个场景：首次登录、连续点击、热重载后首次点击、取消登录。
   - 会确认无静默卡死、无重复初始化告警、失败有明确提示。

达到以上 6 项，就可以认为你已经具备“完整接入 Google 登录”的独立能力。

