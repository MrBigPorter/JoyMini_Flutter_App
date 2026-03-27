# Flutter OAuth 对接总览（CN）

> 本文档改为“总览 + 导航”。
> 平台细节已拆分到独立文档，避免主文档过长难维护。

---

## 0. 阅读顺序（新同学建议）

1. 先看本文档（共享链路与文件落点）。
2. 按平台看专项文档：
   - Google：`FLUTTER_OAUTH_GOOGLE_INTEGRATION_CN.md`
   - Facebook：`FLUTTER_OAUTH_FACEBOOK_INTEGRATION_CN.md`
3. 再回到业务回归脚本执行验证。

---

## 1. 当前状态（2026-03-19）

- 后端已支持：`google` / `facebook` / `apple` / `email otp`。
- Flutter 已完成：OAuth API/Model/Provider/UI 主链路闭环。
- Web 端策略：按配置显示入口，缺配置时禁用或隐藏。

---

## 2. 共享接口契约（必须统一）

### 2.1 OAuth 登录接口

| 接口 | 方法 | 请求体 | 说明 |
|------|------|--------|------|
| `/api/v1/auth/oauth/google` | POST | `{ idToken, inviteCode? }` | 兼容 `{ credential }` |
| `/api/v1/auth/oauth/facebook` | POST | `{ accessToken, userId, inviteCode? }` | 兼容 `userID` |
| `/api/v1/auth/oauth/apple` | POST | `{ idToken, code?, inviteCode? }` | iOS/macOS 为主 |

### 2.2 会话接口

| 接口 | 方法 | 请求体 |
|------|------|--------|
| `/api/v1/auth/refresh` | POST | `{ refreshToken }` |
| `/api/v1/auth/profile` | GET | Bearer Token |

### 2.3 统一成功流程

1. 第三方授权成功后，提交 OAuth 登录接口。
2. 保存 `tokens.accessToken` 与 `tokens.refreshToken`。
3. 拉取 `/api/v1/auth/profile`。
4. 进入首页。

> 禁止每种登录方式各写一套“登录后逻辑”。

---

## 3. 代码单一事实源（Flutter）

- API：`lib/core/api/lucky_api.dart`
- Model：`lib/core/models/auth.dart`
- Provider：`lib/core/providers/auth_provider.dart`
- 登录页：`lib/app/page/login_page.dart`
- 平台能力：`lib/core/services/auth/oauth_sign_in_service.dart`
- 运行配置：`lib/core/config/app_config.dart`

---

## 4. 平台配置边界（共享原则）

- 客户端放：`client_id` / `app_id`。
- 客户端不放：`client_secret`。
- 后端负责：第三方 token 校验与业务 JWT 签发。

Web 联调时，后端 `CORS_ORIGIN` 必须覆盖前端实际 origin（协议 + 域名 + 端口）。

---

## 5. 专项文档导航

### 5.1 Google（Web + App）

请查看：`FLUTTER_OAUTH_GOOGLE_INTEGRATION_CN.md`

包含：
- Google Cloud Console 配置（Authorized JavaScript origins）
- Web 官方标准链路（`renderButton` + `authenticationEvents`）
- `origin_mismatch` / 重复初始化 / 无 SignIn 事件排查
- 新手“完全掌握”能力清单

### 5.2 Facebook（Web + App）

请查看：`FLUTTER_OAUTH_FACEBOOK_INTEGRATION_CN.md`

包含：
- App ID 获取路径（Meta 控制台）
- Web SDK 参数与域名/回调配置
- `accessToken + userId` 请求体对齐
- 常见授权失败排查

---

## 6. 最小回归

```bash
cd /Volumes/MySSD/work/dev/flutter_happy_app
./tool/test_login_regression.sh
```

建议最少覆盖：
- 按配置展示按钮分支（显示/隐藏）。
- 第三方登录成功后 token 落盘与 profile 拉取。
- 取消授权与失败提示分支。

---

## 7. 维护规则

- 本文档只保留共享规则与导航。
- 平台实现细节只写在专项文档，不在这里重复。
- 新增平台登录时，新增对应专项文档并在这里登记导航。

---

最后对齐时间：2026-03-19
