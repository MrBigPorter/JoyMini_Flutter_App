# Flutter Facebook OAuth 对接指南（CN）

> 适用范围：`flutter_happy_app`（Flutter App + Flutter Web）。
> 目标：独立完成 Facebook 登录接入与常见问题排查。

---

## 1. 先掌握这 5 件事

1. 知道 Facebook 的“client id”就是 **App ID**。
2. 知道前端只放 `FACEBOOK_WEB_APP_ID`，不放 `App Secret`。
3. 会在 Meta 控制台配置域名与 OAuth 重定向。
4. 会把 `accessToken + userId` 提交到后端 `/api/v1/auth/oauth/facebook`。
5. 会排查域名不匹配、弹窗失败、字段不一致问题。

---

## 2. 接口契约（后端）

- 登录接口：`POST /api/v1/auth/oauth/facebook`

标准请求体：

```json
{
  "accessToken": "EAAB...",
  "userId": "10200123456789",
  "inviteCode": "ABCD12"
}
```

兼容请求体（后端归一化）：

```json
{
  "accessToken": "EAAB...",
  "userID": "10200123456789"
}
```

登录成功统一流程：保存 token -> 拉取 profile -> 进入首页。

---

## 3. Flutter 代码落点

- 能力层：`lib/core/services/auth/oauth_sign_in_service.dart`
- 登录页：`lib/app/page/login_page.dart`
- API：`lib/core/api/lucky_api.dart`
- Provider：`lib/core/providers/auth_provider.dart`

Web 侧关键开关：

- `FACEBOOK_WEB_APP_ID`
- `FACEBOOK_WEB_SDK_VERSION`（例如 `v19.0`）

---

## 4. Meta 控制台配置（最关键）

### 4.1 哪里拿 App ID

Meta for Developers -> 你的应用 -> Settings -> Basic -> **App ID**

### 4.2 必配项

- 添加 `Facebook Login` 产品
- 配置 App Domains
- 配置有效 OAuth 重定向 URI（按你后端/前端回调方案）
- 本地与测试域名都要覆盖（例如 `localhost`、dev 域名）

> 常见失败基本都在这里：域名未加入、回调 URI 不匹配、应用状态限制。

---

## 5. 平台边界

- 前端：只用 `App ID` 发起授权。
- 后端：如需校验 token，使用 `FACEBOOK_APP_ID` / `FACEBOOK_APP_SECRET`。
- 禁止在客户端放 `App Secret`。

---

## 6. 常见错误与处理

### 6.1 弹窗后失败 / 无法授权

- 检查 `FACEBOOK_WEB_APP_ID` 是否正确。
- 检查 Meta 控制台域名与回调 URI。
- 检查应用是否限制为开发模式且测试用户未加入。

### 6.2 后端报用户信息校验失败

- 检查是否传了 `accessToken` 和 `userId`。
- 检查字段是否误用 `userID`（后端虽兼容，但建议统一 `userId`）。

### 6.3 Web 无按钮

- 检查 `FACEBOOK_WEB_APP_ID` 是否为空。
- 检查按钮显示逻辑是否被平台开关禁用。

---

## 7. 运行与联调

```bash
cd /Volumes/MySSD/work/dev/flutter_happy_app
fvm flutter run -d chrome \
  --dart-define=FACEBOOK_WEB_APP_ID=your_facebook_app_id \
  --dart-define=FACEBOOK_WEB_SDK_VERSION=v19.0
```

联调时建议日志关注：

- Web 平台是否已初始化 Facebook SDK
- `login()` 返回状态（success/cancelled/failed）
- 后端返回的错误码与错误信息

---

## 8. 最小回归清单

- Facebook 按钮按配置正确显示/隐藏。
- 点击授权可成功回调并登录。
- 取消授权不应打断页面流程。
- `accessToken + userId` 提交后可拿到业务 token。
- 失败场景有明确提示文案。

