
# 🚀 JoyMini 全平台打包“大包教程” (终极详尽版)

### 📊 第一部分：三大平台打包差异深度分析

| 维度 | **Web (网页端)** | **Android (安卓端)** | **iOS (苹果端)** |
| --- | --- | --- | --- |
| **产物形态** | 文件夹（包含 JS、HTML、CanvasKit） | 文件（`.apk` 或 `.aab`） | 文件（`.ipa`） |
| **核心编译工具** | Flutter Web Compiler | Gradle + Android SDK | Xcode + Apple SDK |
| **签名/证书** | **不需要** | **需要** (`.jks` 签名文件) | **极严** (开发者证书 + 配置文件) |
| **环境注入** | 编译时注入 JS 常量 | 编译时注入 Java/Kotlin 代码 | 编译时注入 Objective-C/Swift 代码 |
| **发布方式** | 传到 Nginx/CDN 服务器即可 | 传到商店或直接发给用户 APK | 必须通过 App Store 或 TestFlight |
| **运行机制** | 在浏览器沙盒里跑 | 在安卓虚拟机或真机上跑 | 在苹果封闭系统内跑 |

---

### 🛠️ 第二部分：全端打包实战指南

> **⚠️ 升空前检 (Pre-flight Check)**：
> 在开始之前，确保你的 `pubspec.yaml` 里的版本号（如 `version: 1.0.0+1`）已经更新，并且 `assets` 里的图标已经生成。

#### 🌐 1. Web 端：最简单的“一键发布”

Web 打包不需要签名，只要确保 API 地址正确。

* **打包命令**：
```bash
# 带 WebAssembly 的极致性能版（视需求选用）
flutter build web --release --wasm --dart-define-from-file=lib/core/config/env/prod.json

# 标准稳定版（推荐）
flutter build web --release --dart-define-from-file=lib/core/config/env/prod.json

```


* **后续操作**：
* 打包产物在 `build/web/` 文件夹。
* 直接把这个文件夹里的所有东西，通过 FTP 或 SSH 传到你的 Nginx 服务器对应目录下即可。



#### 🍏 2. iOS 端：严格的“苹果审核”

必须在 Mac 上操作，且 Xcode 里的 `Info.plist` 已经按照相关要求修好了。

* **第一步：生成归档 (Archive)**
```bash
flutter build ipa --release --dart-define-from-file=lib/core/config/env/prod.json

```


* **第二步：Xcode 发布**
* 命令跑完后，会生成一个 `Runner.xcarchive`。
* 打开 Xcode 的 **Organizer** (Window -> Organizer)。
* 选择你的 **JoyMini** 归档，点 **Distribute App**。
* 如果你是上架，选 `App Store Connect`；如果你是给内部人测，选 `Ad Hoc`。



---

### 🤖 第三部分：Android 端深度实操（保姆级）

安卓端涉及签名、防泄漏和 Gradle 改造，是配置最繁琐的一环，请严格按照以下步骤执行。

#### 第一步：确保终端在项目根目录（防错关键）

打开你的终端（Terminal），输入 `cd `（注意后面有个空格），然后把你的项目文件夹（比如 `flutter_happy_app`）拖进终端，回车。
*验证：终端光标前面的名字必须是你的项目名。*

#### 第二步：生成签名文件（铸造“玉玺”）

在终端中直接复制并运行这行命令：

```bash
keytool -genkey -v -keystore android/app/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload

```

* **操作**：输入一个密码（比如 `123456`，**屏幕不会显示，输完直接回车**），再次确认密码。后面的名字、组织、国家（填 `CN`）随便写，最后输入 `y` 确认。
* **结果**：你的 `android/app/` 目录下会多出一个 `upload-keystore.jks` 文件。

#### 第三步：提取指纹，打通 Firebase 离线推送

紧接着在终端运行这行命令，提取新玉玺的指纹：

```bash
keytool -list -v -keystore android/app/upload-keystore.jks -alias upload

```

* **操作**：输入刚才的密码。在输出的信息中，复制 **SHA1** 和 **SHA256** 后面的那串字符（如 `XX:XX:XX...`）。
* **打通 Firebase**：去网页打开 **Firebase 控制台** -> 左上角⚙️设置 -> **项目设置** -> 找到你的 Android 应用 -> 在“SHA 证书指纹”那里，点击**添加指纹**，把 SHA1 和 SHA256 分别填进去保存。

#### 第四步：建立密码本，并锁死安全后门

为了安全，我们要把密码写在配置文件里，并防止它被传到 GitHub。

1. **新建密码本**：在代码编辑器里，在 `android/` 目录下新建一个文件，命名为 `key.properties`。把下面内容填进去（**密码换成你自己的**）：
```properties
storePassword=你刚才设置的密码
keyPassword=你刚才设置的密码
keyAlias=upload
storeFile=upload-keystore.jks

```


2. **🚫 绝对红线（防泄露）**：打开项目最外层的 `.gitignore` 文件，在最下面加上这两行，防止秘钥泄露被传上云端：
```text
android/key.properties
android/app/upload-keystore.jks

```


3. **配置 GitHub Secrets (用于 CI/CD)**：
   在终端运行以下命令，将玉玺转成文本：
```bash
base64 -i android/app/upload-keystore.jks -o keystore_base64.txt

```


在 GitHub 上配置 4 个安全秘钥 (Secrets)：
* `ANDROID_KEYSTORE_BASE64`：全选并复制 `keystore_base64.txt` 里的所有内容粘贴进去。
* `ANDROID_KEY_PASSWORD`：你刚才设置的签名密码（比如 `123456`）。
* `ANDROID_STORE_PASSWORD`：你刚才设置的签名密码（和上面一样）。
* `ANDROID_KEY_ALIAS`：`upload` （我们之前固定写的别名）。



#### 第五步：改造 Gradle 构建脚本

打开 `android/app/build.gradle` 文件，做以下 3 处修改：

**修改 1：在文件最顶部（`android {` 上方）加入读取密码本的代码：**

```groovy
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}

android {
// ... 原本的代码

```

**修改 2：在 `android {` 内部，找到 `defaultConfig`，在它下面新增 `signingConfigs`：**

```groovy
    defaultConfig {
        // ... 原有的配置
    }

    // 新增这一块：
    signingConfigs {
        release {
            keyAlias = keystoreProperties['keyAlias']
            keyPassword = keystoreProperties['keyPassword']
            storeFile = keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
            storePassword = keystoreProperties['storePassword']
        }
    }

```

**修改 3：往下找，把 `signingConfigs.release` 绑到 `buildTypes.release` 上：**

```groovy
    buildTypes {
        release {
            // 新增这一行：
            signingConfig signingConfigs.release
            
            // 下面的保持原样
            minifyEnabled true
            shrinkResources true
        }
    }

```

#### 第六步：一键发射，编译正式包！

回到终端，执行我们之前配好环境变量的终极打包命令：

* **本地测试包 (APK)**：直接发给哥们儿安装，或者放在官网给用户下载。
```bash
flutter build apk --release --dart-define-from-file=lib/core/config/env/prod.json

```


*(产物路径：`build/app/outputs/flutter-apk/app-release.apk`)*
* **上架专用包 (AAB)**：传给 Google Play 控制台。
```bash
flutter build appbundle --release --dart-define-from-file=lib/core/config/env/prod.json

```


*(产物路径：`build/app/outputs/bundle/release/app-release.aab`)*

**架构师的等候区**：这个命令跑完大概需要几分钟。只要最后出现了绿色的 `✓ Built build/app/outputs/flutter-apk/app-release.apk`，你的工业级正式包就大功告成了！

---

### 📌 附录：核心备忘录

#### 1. 核心编译命令速查（你只需要记住这三行）

为了方便你复制，我把生产环境的最常用命令整在一起了：

```bash
# Web 发布
flutter build web --release --dart-define-from-file=lib/core/config/env/prod.json

# Android 发给用户 (APK)
flutter build apk --release --dart-define-from-file=lib/core/config/env/prod.json

# iOS 准备上传商店
flutter build ipa --release --dart-define-from-file=lib/core/config/env/prod.json

```

#### 2. 本地 CI/CD Runner 启动命令

如果需要重启本地的 GitHub Actions 服务，请在 Mac 终端执行：

```bash
cd /Volumes/MySSD/github-runner/
./run.sh

```

---

