# Flutter 登录对接精华版（OAuth + Email OTP）

> 仅保留 Flutter 实施必需信息：接口契约、平台配置边界、H5 开关策略、最小回归。  
> 代码优先：以 `admin/auth/*.ts` 实际实现为准。

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
| `/api/v1/auth/oauth/google` | POST | `{ idToken, inviteCode? }` |
| `/api/v1/auth/oauth/facebook` | POST | `{ accessToken, userId, inviteCode? }` |
| `/api/v1/auth/oauth/apple` | POST | `{ idToken, code?, inviteCode? }` |
| `/api/v1/auth/email/send-code` | POST | `{ email }` |
| `/api/v1/auth/email/login` | POST | `{ email, code }` |

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

- Google：`GOOGLE_WEB_CLIENT_ID` 非空 -> 按钮可用
- Facebook：`FACEBOOK_WEB_APP_ID` 非空 -> 按钮可用
- Apple：Web 仍后置（暂不开放）

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

---

## 7. 最小回归（提交前必须跑）

```bash
cd /Volumes/MySSD/work/dev/flutter_happy_app
./tool/test_login_regression.sh
```

重点覆盖：
- OAuth/Email 模型解析
- 登录页按钮分支与模式切换
- 商业链路回归（防连带破坏）

---

## 8. 本文档维护原则

- 只保留当前可执行信息，不保留历史设计推演。
- 新增登录方式时，仅更新本文件和对应代码，不再新增平行“登录文档”。
