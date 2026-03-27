# 🛡️ JoyMini 项目：GitHub Actions 密钥配置手册

这份文档记录了项目中所有配置在 GitHub `Settings -> Secrets -> Actions` 中的密钥。这些变量支撑了项目的 **多环境（Test/Prod）自动签名**、**Firebase 分发**、**Shorebird 热更新**以及 **Telegram 通知**。

## 1. Android 签名密钥 (Android Signing)
用于生产环境和测试环境的 APK 签名。

| 变量名 | 类别 | 说明 |
| :--- | :--- | :--- |
| **`ANDROID_KEYSTORE_BASE64`** | 文件 (Base64) | **正式版** `upload-keystore.jks` 的编码。用于 `main` 分支发布。 |
| **`DEBUG_KEYSTORE_BASE64`** | 文件 (Base64) | **测试版** `debug.keystore` 的编码。用于 `test` 分支打包。 |
| **`ANDROID_KEY_ALIAS`** | 字符串 | 正式签名的别名 (Alias)，通常为 `upload`。 |
| **`ANDROID_KEY_PASSWORD`** | 密码 | 正式签名私钥的密码。 |
| **`ANDROID_STORE_PASSWORD`** | 密码 | 正式 Keystore 文件的库密码。 |

---

## 2. 环境配置文件 (Core Configs)
这些文件在打包前会被 CI 脚本还原到物理路径。

| 变量名 | 还原路径 | 说明 |
| :--- | :--- | :--- |
| **`GOOGLE_SERVICES_JSON`** | `android/app/google-services.json` | Firebase 核心配置文件，包含 API Key 和项目 ID。 |
| **`LOCAL_PROPERTIES`** | `./local.properties` | 包含 Facebook App ID、Client Token 等敏感的原生配置。 |
  IOS_G_SERVICES_PROD (新！iOS 正式版 Plist 内容)
  IOS_G_SERVICES_TEST (新！iOS 测试版 Plist 内容)
---

## 3. Firebase 体系 (Firebase Ecosystem)
用于应用监控、崩溃分析及测试包分发。

| 变量名 | 说明 |
| :--- | :--- |
| **`FIREBASE_SERVICE_ACCOUNT_JSON`** | Firebase 服务账号密钥 (JSON)，用于 CI 自动上传包到分发平台。 |
| **`FIREBASE_TOKEN`** | Firebase CLI 登录令牌。 |
| **`FIREBASE_ANDROID_APP_ID_PROD`** | 正式版 Android App 在 Firebase 上的唯一标识。 |
| **`FIREBASE_ANDROID_APP_ID_TEST`** | 测试版 Android App 在 Firebase 上的唯一标识。 |
| **`FIREBASE_IOS_APP_ID_PROD`** | 正式版 iOS App 在 Firebase 上的唯一标识。 |
| **`FIREBASE_IOS_APP_ID_TEST`** | 测试版 iOS App 在 Firebase 上的唯一标识。 |
| **`FIREBASE_INVITE_LINK`** | 用于邀请测试人员下载测试包的公开链接。 |

---

## 4. 自动化与基础设施 (Infra & Deployment)

| 变量名 | 说明 |
| :--- | :--- |
| **`SHOREBIRD_TOKEN`** | **Shorebird** 官方令牌。用于执行热更新 Patch 和 Release。 |
| **`CF_ACCOUNT_ID`** | **Cloudflare** 账户 ID，用于部署项目的 H5 网页版。 |
| **`CF_API_TOKEN`** | **Cloudflare** API 令牌，授权 CI 往 Pages/Workers 推送代码。 |

---

## 5. 即时通讯通知 (Notifications)

| 变量名 | 说明 |
| :--- | :--- |
| **`TELEGRAM_TOKEN`** | Telegram Bot 的令牌。用于打包任务结束后发送成功/失败消息。 |
| **`TELEGRAM_CHAT_ID`** | 你的个人 ID 或群组 ID，机器人会将打包通知发到这里。 |

---

## 🛠️ 维护注意事项

### 更新密钥文件
如果签名文件 (`.jks` / `.keystore`) 发生变更，请在终端执行以下命令重新生成 Base64：
```bash
openssl base64 -A -in <文件路径> | pbcopy
```
