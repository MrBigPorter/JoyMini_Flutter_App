# 构建失败预防手册

> **核心原则：项目在外置 SSD 上，`flutter clean` 极慢（30min+），永远用 `make clean` 代替。**

---

## 一、快速命令卡片

| 场景 | 命令 | 耗时 |
|------|------|------|
| 日常清理 | `make clean` | ~3 秒 |
| 切分支后 / 更新依赖后 | `make clean && fvm flutter pub get` | ~10 秒 |
| iOS build 失败 | `make rebuild-ios` | ~10 分钟 |
| 死活编不过（核弹） | `make clean-ios && make pod` | ~10 分钟 |
| 排查 build 失败原因 | `make health-check` | ~5 秒 |

---

## 二、什么时候必须清理？

### 🔴 必须执行 `make rebuild-ios`
- 切换到差异很大的分支（`pubspec.yaml` / `Podfile` / Firebase 配置变了）
- 升级 Flutter SDK 版本（修改 `.fvm/fvm_config.json` 后）
- 更新 Xcode 大版本后
- 执行 `flutter pub upgrade` 后

### 🟡 必须执行 `make clean && fvm flutter pub get`
- 修改了 `pubspec.yaml` 依赖版本
- 出现 `Invalid depfile` 错误
- 出现 `Stale file outside allowed root paths` 错误
- 编译器报"某个类找不到"但代码明明有

### 🟢 不需要清理的情况
- 只改了 Dart/Flutter 业务代码
- 只改了资源文件（图片、字体等）
- 只改了配置文件（`dev.json`、`app_config.dart` 等）

---

## 三、常见 Build 失败原因 & 解决方案

### 错误 1: `Invalid depfile: .dart_tool/.../kernel_snapshot_program.d`
**原因**：`.dart_tool/` 构建缓存损坏（切分支/强制中断编译后）  
**解决**：`make clean && fvm flutter pub get`

### 错误 2: `Stale file '...FBSDKLoginKit.framework' is located outside of the allowed root paths`
**原因**：iOS build 目录里有旧版本 Facebook SDK 的残留文件  
**解决**：`make clean-ios && make pod`

### 错误 3: `[core/no-app] No Firebase App '[DEFAULT]' has been created`
**原因**：Firebase 未初始化就被访问（已修复，见 bootstrap.dart）  
**解决**：已永久修复，无需处理

### 错误 4: `pod install` 失败，提示版本冲突
**原因**：`Podfile.lock` 版本与 `Podfile` 不一致  
**解决**：`make clean-ios && make pod`（带 `--repo-update`）

### 错误 5: Android `Skipped 140 frames` / 主线程卡顿
**原因**：启动时主线程任务太重（启动优化已做到 Future.wait 并行）  
**解决**：正常现象，外置 SSD 上 I/O 本就比内置慢

### 错误 6: iOS Simulator 启动后白屏
**原因**：旧的 DerivedData 与新代码冲突  
**解决**：
```bash
rm -rf ~/Library/Developer/Xcode/DerivedData/
make clean && fvm flutter pub get
```

---

## 四、防止 build 目录膨胀的习惯

```bash
# 每周一次，防止 build/ 超过 2GB
make clean

# 提交代码前清理（让 CI 从干净状态构建）
make clean && fvm flutter pub get
```

build 目录超过 2GB 时：
- `flutter clean` 耗时 30 分钟以上
- `make clean` 仍然只需 3 秒（`rm -rf`）

---

## 五、Git 切换分支自动提醒

已安装 `.git/hooks/post-checkout`，切换分支时会自动检测：
- `pubspec.yaml` / `Podfile` 是否变化
- `build/` 是否超过 2GB
- Firebase 配置是否变化

**示例输出：**
```
🔀 分支已切换，正在检查是否需要清理...
⚠️  检测到以下变更，建议执行清理：
  • pubspec.yaml/lock 发生变化（Flutter 依赖变更）
  👉 推荐执行: make clean && fvm flutter pub get
```

---

## 六、新机器/新成员环境初始化

```bash
git clone <repo>
cd flutter_happy_app
make setup   # 自动安装 FVM 版本、pub get、pod install
make dev     # 启动开发环境
```

