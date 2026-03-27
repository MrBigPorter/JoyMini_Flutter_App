# Flutter Google OAuth 对接指南（CN）

> 适用范围：`flutter_happy_app`（Flutter App + Flutter Web）。
> 目标：让新同学可独立完成 Google 登录对接、排障、回归验证。

---

## 1. 先掌握这 6 件事

达到以下 6 项，即可认为“完整掌握 Google 登录对接”：

1. 会配置 `GOOGLE_WEB_CLIENT_ID`（Web）与 App 平台基础文件。
2. 会在 Google Cloud Console 配置 **Authorized JavaScript origins**。
3. 知道 Web 端主入口是 `renderButton`，不是 `authenticate()`。
4. 会从 `authenticationEvents` 获取 `GoogleSignInAccount` 并提取 `idToken`。
5. 会把 `idToken` 提交到 `/api/v1/auth/oauth/google` 并完成 token 落盘。
6. 会排查 `origin_mismatch`、重复 `initialize`、无 SignIn 事件等问题。

---

## 2. 接口契约（后端）

- 登录接口：`POST /api/v1/auth/oauth/google`
- 请求体（标准）：

```json
{
  "idToken": "eyJ...",
  "inviteCode": "ABCD12"
}
```

- 请求体（兼容）：

```json
{
  "credential": "eyJ..."
}
```

- 成功后统一流程：保存 `tokens.accessToken` / `tokens.refreshToken` -> 拉取 `/api/v1/auth/profile`。

---

## 3. Flutter 代码落点

- 能力层：`lib/core/services/auth/oauth_sign_in_service.dart`
- 登录页：`lib/app/page/login_page.dart`
- API：`lib/core/api/lucky_api.dart`
- Model：`lib/core/models/auth.dart`
- Provider：`lib/core/providers/auth_provider.dart`

---

## 4. Web 标准实现（官方对齐）

1. 调 `GoogleSignIn.instance.initialize(clientId: ...)`，且全页面 only-once。
2. Web UI 用官方按钮 `renderButton`。
3. 用 `GoogleSignIn.instance.authenticationEvents` 监听认证事件。
4. 收到 `GoogleSignInAuthenticationEventSignIn` 后取 `idToken`。
5. 调后端接口完成业务登录。

> `authenticate()` 在 Web 不支持，调用会抛 `UnimplementedError`。

---

## 5. Google Cloud Console 必配项

### 5.1 拿到 Web Client ID

- Google Cloud Console -> APIs & Services -> Credentials -> OAuth 2.0 Client IDs
- 选择 **Web application** 类型
- 拿到 client id（填入 `GOOGLE_WEB_CLIENT_ID`）

### 5.2 配置 Authorized JavaScript origins

必须包含实际运行 origin（协议 + 域名 + 端口完全一致）：

- `http://localhost:4000`
- `http://127.0.0.1:4000`
- `http://localhost:3000`
- `http://127.0.0.1:3000`
- 以及你的 dev/prod 域名

注意：
- 只填 origin，不带路径（不要 `/login`）。
- 修改后建议等待 1-5 分钟再测试。

---

## 6. 最常见错误与处理

### 6.1 `Error 400: origin_mismatch`

- 本质：Google Console 配置问题。
- 动作：检查当前 `window.location.origin` 是否在 Authorized JavaScript origins。

### 6.2 `google.accounts.id.initialize() is called multiple times`

- 本质：重复初始化。
- 动作：确认初始化 only-once 守卫生效；排查多入口触发。

### 6.3 点击后无结果（无 SignIn 事件）

- 本质：事件监听时机/入口并发问题。
- 动作：确认 `authenticationEvents` 在点击前已监听；避免多入口并发触发。

---

## 7. 运行与联调

示例：

```bash
cd /Volumes/MySSD/work/dev/flutter_happy_app
fvm flutter run -d chrome \
  --dart-define=GOOGLE_WEB_CLIENT_ID=your-google-web-client-id.apps.googleusercontent.com
```

建议在 debug 日志固定打印：

- `origin`
- `clientIdHead`（脱敏）
- 初始化触发源 `trigger`
- 是否命中 `storage guard`
- 是否收到 `SignIn` 事件

---

## 8. 最小回归清单

- 首次打开登录页 -> Google 按钮可见。
- 点击按钮 -> 能弹出 Google 授权。
- 成功后可登录并进入首页。
- 取消登录不弹错误（静默处理）。
- 热重载后首次点击仍可登录。

回归脚本入口：

```bash
cd /Volumes/MySSD/work/dev/flutter_happy_app
./tool/test_login_regression.sh
```

---

## 9. 给新同学的 3 分钟排查顺序

1. 先看是否 `origin_mismatch`（优先改控制台）。
2. 再看是否重复 `initialize`。
3. 再看是否收到 `SignIn` 事件。
4. 收到 `idToken` 仍失败再查后端。

