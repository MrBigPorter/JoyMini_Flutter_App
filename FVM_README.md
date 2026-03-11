# 🚀 Flutter 项目环境管理指南 (FVM 版)

本项目使用 **FVM (Flutter Version Management)** 进行 SDK 版本管理，以确保不同项目间的环境物理隔离，并优化 SSD 存储空间。

## 📦 1. 环境准备 (只需执行一次)

### 安装 FVM 工具

```bash
brew tap leoafarias/fvm
brew install fvm

```

### 配置 SSD 缓存路径 (推荐)

为了节省系统盘空间并提升性能，建议将 SDK 缓存移动至外置 SSD：

```bash
fvm config --cache-path /Volumes/MySSD/fvm_cache

```

---

## 🛠️ 2. 项目初始化 (新项目或克隆后)

进入项目根目录，安装并锁定 SDK 版本：

```bash
# 安装并锁定当前项目指定的版本
fvm use stable --pin

```

执行后，项目根目录会生成 `.fvm/` 文件夹。

---

## 🖥️ 3. IDE 配置 (关键)

### Android Studio / IntelliJ

1. 进入 **Settings** -> **Languages & Frameworks** -> **Flutter**。
2. 将 **Flutter SDK path** 修改为当前项目的绝对路径：
   `{项目路径}/.fvm/flutter_sdk`
   *(提示：在文件选择器中按 `Cmd + Shift + .` 显示隐藏文件夹)*
3. **Dart SDK path** 会自动同步。
4. 执行 **File -> Invalidate Caches...** 并重启以刷新索引。

### VS Code

在 `.vscode/settings.json` 中添加：

```json
{
  "dart.flutterSdkPath": ".fvm/flutter_sdk"
}

```

---

## ⌨️ 4. 常用命令对照表

以后所有 `flutter` 命令前请加 `fvm` 前缀：

| 场景 | 传统命令 | **FVM 命令 (推荐)** |
| --- | --- | --- |
| 获取依赖 | `flutter pub get` | **`fvm flutter pub get`** |
| 运行项目 | `flutter run` | **`fvm flutter run`** |
| 构建 APK | `flutter build apk` | **`fvm flutter build apk`** |
| 版本切换 | 手动切换 | **`fvm use <version>`** |

> **懒人技巧**：可以在 `~/.zshrc` 中添加 `alias f='fvm flutter'`，之后只需输入 `f run` 即可。

---

## 🛡️ 5. Git 忽略规则 (`.gitignore`)

请务必在 `.gitignore` 中加入以下行，防止将数 GB 的 SDK 源码提交到仓库：

```text
# FVM
.fvm/flutter_sdk
.fvm/versions/
.fvm/cache/

```

**注意**：`.fvmrc` 和 `fvm_config.json` **应该**提交到 Git，以便团队同步版本。

---

## 🤖 6. 自动化构建 (CI/CD)

在 GitHub Actions 或其他 CI 环境中，使用以下步骤对齐环境：

```yaml
- uses: leoafarias/setup-fvm@v1
- name: Install Flutter
  run: fvm install
- name: Build
  run: fvm flutter build apk --release

```

