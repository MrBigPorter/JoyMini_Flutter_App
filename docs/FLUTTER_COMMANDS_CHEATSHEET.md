# Flutter命令速查表（本项目专用）

> **重要**：执行任何Flutter命令前，必须先查阅本文件。这是AI协作开发规范的一部分。

## 📋 使用说明

### 为什么需要本速查表？
1. **记忆不可靠**：AI没有长期记忆，需要文档辅助
2. **项目特定**：每个项目有自己的命令习惯和脚本
3. **环境差异**：不同环境需要不同的命令参数
4. **错误预防**：避免因命令错误导致的问题

### 使用原则：
1. **执行前必查**：每次执行命令前查阅本文件
2. **记录命令**：所有执行的命令必须在沟通中明确写出
3. **验证结果**：执行后验证命令效果
4. **更新文档**：发现新的有用命令时更新本文件

## 🚀 命令分类索引

### 1. 开发环境命令
### 2. 代码质量命令
### 3. 测试命令
### 4. 运行命令
### 5. 构建命令
### 6. 代码生成命令
### 7. 项目特定命令
### 8. 调试命令

## 📝 详细命令列表

### 重要提醒：本项目使用FVM管理Flutter版本
**所有Flutter命令前必须加 `fvm` 前缀**，例如：
- ❌ `flutter run` → ✅ `fvm flutter run`
- ❌ `flutter pub get` → ✅ `fvm flutter pub get`
- ❌ `flutter build apk` → ✅ `fvm flutter build apk`

### 1. 开发环境命令

#### FVM环境管理
```bash
# 检查FVM环境
fvm flutter doctor

# 查看当前Flutter版本
fvm flutter --version

# 查看已安装的Flutter版本
fvm list

# 安装特定Flutter版本
fvm install 3.16.0

# 切换到特定版本
fvm use 3.16.0

# 使用稳定版
fvm use stable --pin

# 查看FVM配置
fvm config
```

#### 项目清理
```bash
# 清理构建文件（使用FVM）
fvm flutter clean

# 清理并重新获取依赖
fvm flutter clean && fvm flutter pub get

# 清理所有缓存（包括pub缓存）
fvm flutter clean && rm -rf ~/.pub-cache && fvm flutter pub get
```

#### 依赖管理
```bash
# 获取依赖（使用FVM）
fvm flutter pub get

# 升级依赖
fvm flutter pub upgrade

# 添加依赖
fvm flutter pub add package_name

# 移除依赖
fvm flutter pub remove package_name

# 查看过时依赖
fvm flutter pub outdated

# 查看依赖树
fvm flutter pub deps
```

### 2. 代码质量命令

#### 静态分析
```bash
# Flutter静态分析（使用FVM）
fvm flutter analyze

# 项目特定分析脚本
make analyze

# 只分析lib目录
fvm flutter analyze lib/

# 输出详细分析结果
fvm flutter analyze --verbose
```

#### 代码格式化
```bash
# 格式化所有Dart文件
dart format .

# 格式化指定目录
dart format lib/

# 检查格式化（不实际修改）
dart format --set-exit-if-changed .

# 修复所有格式化问题
dart fix --apply
```

#### 代码检查
```bash
# 检查未使用的导入
dart fix --dry-run

# 检查空安全
dart migrate --apply-changes

# 检查依赖版本（使用FVM）
fvm flutter pub deps --style=compact
```

### 3. 测试命令

#### 单元测试
```bash
# 运行所有测试（使用FVM）
fvm flutter test

# 运行指定测试文件
fvm flutter test test/unit/my_test.dart

# 运行测试并生成覆盖率报告
fvm flutter test --coverage

# 运行测试并查看详细输出
fvm flutter test --verbose
```

#### 集成测试
```bash
# 运行集成测试（使用FVM）
fvm flutter test integration_test/

# 在特定设备上运行集成测试
fvm flutter test integration_test/ --device-id=your_device_id
```

#### 项目特定测试
```bash
# 使用项目测试脚本
make test

# 运行Widget测试（使用FVM）
fvm flutter test test/widgets/

# 运行Provider测试（使用FVM）
fvm flutter test test/providers/
```

### 4. 运行命令

#### 开发运行
```bash
# 运行应用（默认调试模式，使用FVM）
fvm flutter run

# 在特定设备上运行
fvm flutter run -d chrome          # Web
fvm flutter run -d android         # Android
fvm flutter run -d ios             # iOS
fvm flutter run -d macos           # macOS
```

#### 项目特定运行
```bash
# 开发环境运行（使用项目脚本）
make dev

# 带热重载运行（使用FVM）
fvm flutter run --hot-reload

# 禁用热重载（使用FVM）
fvm flutter run --no-hot-reload
```

#### 不同模式运行
```bash
# 调试模式（默认，使用FVM）
fvm flutter run --debug

# 性能分析模式（使用FVM）
fvm flutter run --profile

# 发布模式（使用FVM）
fvm flutter run --release

# 启用Dart开发者工具（使用FVM）
fvm flutter run --observatory-port=8888
```

### 5. 构建命令

#### Android构建
```bash
# 调试APK（使用FVM）
fvm flutter build apk --debug

# 发布APK（使用FVM）
fvm flutter build apk --release

# 分ABI构建（减少APK大小，使用FVM）
fvm flutter build apk --release --split-per-abi

# App Bundle（Google Play，使用FVM）
fvm flutter build appbundle --release

# 指定构建类型（使用FVM）
fvm flutter build apk --flavor prod
```

#### iOS构建
```bash
# 调试构建（使用FVM）
fvm flutter build ios --debug

# 发布构建（使用FVM）
fvm flutter build ios --release

# 模拟器构建（使用FVM）
fvm flutter build ios --simulator

# 指定scheme（使用FVM）
fvm flutter build ios --release --flavor prod
```

#### Web构建
```bash
# 调试构建（使用FVM）
fvm flutter build web --debug

# 发布构建（使用FVM）
fvm flutter build web --release

# 指定目标目录（使用FVM）
fvm flutter build web --release --output=build/web_prod

# 启用CanvasKit渲染器（使用FVM）
fvm flutter build web --release --web-renderer canvaskit
```

#### 项目特定构建
```bash
# 生产环境构建
make prod

# 开发环境构建
make build-dev

# 清理并构建
make clean-build
```

### 6. 代码生成命令

#### Build Runner
```bash
# 生成代码（清理冲突输出）
dart run build_runner build --delete-conflicting-outputs

# 监听模式生成
dart run build_runner watch --delete-conflicting-outputs

# 只生成指定目标
dart run build_runner build --delete-conflicting-outputs --build-filter="lib/**"

# 清理生成的文件
dart run build_runner clean
```

#### 项目生成脚本
```bash
# 运行项目生成脚本
tool/generate.sh

# 生成设计token
tool/gen_tokens_flutter.dart

# 生成Tailwind提示
tool/gen_tw_hints.dart
```

### 7. 项目特定命令（Make命令）

#### 开发工作流
```bash
# 完整的开发启动流程
make dev

# 生产构建
make prod

# 代码分析
make analyze

# 运行测试
make test

# 清理项目
make clean
```

#### 平台特定修复
```bash
# 修复Android问题
tool/fix_android.sh

# 修复iOS问题
tool/fix_ios.sh

# 开发环境设置
tool/dev.sh
```

#### 工具脚本
```bash
# 登录回归测试
tool/test_login_regression.sh

# 生成所有代码
tool/generate.sh
```

### 8. 调试命令

#### 日志和调试
```bash
# 启用详细日志（使用FVM）
fvm flutter run --verbose

# 查看设备日志（使用FVM）
fvm flutter logs

# 清除设备日志（使用FVM）
fvm flutter logs --clear

# 调试特定Dart文件（使用FVM）
fvm flutter run --start-paused --dart-define=DEBUG=true
```

#### 性能分析
```bash
# 性能分析运行（使用FVM）
fvm flutter run --profile

# 跟踪启动性能（使用FVM）
fvm flutter run --trace-startup

# 内存分析（使用FVM）
fvm flutter run --trace-skia

# 渲染性能分析（使用FVM）
fvm flutter run --trace-systrace
```

#### 设备管理
```bash
# 列出所有设备（使用FVM）
fvm flutter devices

# 启动模拟器（使用FVM）
fvm flutter emulators --launch apple_ios_simulator

# 创建新模拟器（使用FVM）
fvm flutter emulators --create --name my_ios_simulator
```

## 🔄 常用工作流

### 日常开发工作流（使用FVM）
```bash
# 1. 开始新的一天
fvm flutter clean
fvm flutter pub get
fvm flutter analyze
make dev

# 2. 修改代码后
fvm flutter analyze
fvm flutter test
dart format .

# 3. 提交代码前
make analyze
make test
dart format --set-exit-if-changed .
```

### 问题排查工作流（使用FVM）
```bash
# 1. 遇到构建问题
fvm flutter clean
fvm flutter pub get
fvm flutter doctor
fvm flutter analyze

# 2. 遇到运行时问题
fvm flutter run --verbose
# 查看控制台日志
# 检查设备连接

# 3. 遇到测试问题
fvm flutter test --verbose
# 检查测试环境
# 查看测试日志
```

### 发布工作流（使用FVM）
```bash
# 1. 准备发布
fvm flutter clean
fvm flutter pub get
fvm flutter analyze
make test

# 2. 构建发布版本
make prod
# 或
fvm flutter build apk --release --split-per-abi
fvm flutter build ios --release
fvm flutter build web --release

# 3. 验证发布版本
# 安装测试APK/iOS应用
# 测试Web版本
```

## ⚠️ 注意事项

### 环境相关
1. **FVM使用**：本项目使用FVM管理Flutter版本
   ```bash
   # 使用FVM运行命令
   fvm flutter run
   
   # 查看当前Flutter版本
   fvm flutter --version
   
   # 切换Flutter版本
   fvm use 3.16.0
   ```

2. **平台特定**：
   - Android：需要Android Studio和SDK
   - iOS：需要Xcode和开发者账号
   - Web：需要Chrome浏览器测试

3. **网络环境**：
   - 国内用户可能需要配置镜像
   - 确保网络可以访问pub.dev

### 常见问题解决

#### 问题1：`fvm flutter pub get` 失败
```bash
# 解决方案：
fvm flutter clean
rm -rf ~/.pub-cache
export PUB_HOSTED_URL=https://pub.flutter-io.cn
export FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn
fvm flutter pub get
```

#### 问题2：构建失败
```bash
# 解决方案：
fvm flutter clean
fvm flutter pub get
fvm flutter doctor
# 检查平台特定配置
# 检查依赖版本冲突
```

#### 问题3：热重载不工作
```bash
# 解决方案：
fvm flutter clean
fvm flutter run --no-hot-reload
# 或重启开发服务器
```

## 📊 命令执行记录规范

### 必须记录的信息：
1. **命令内容**：完整的命令字符串
2. **执行目的**：为什么要执行这个命令
3. **预期结果**：期望命令产生什么效果
4. **实际结果**：命令实际执行的结果
5. **问题记录**：如果命令失败，记录问题和解决方案

### 记录示例：
```
## 命令执行记录

### 命令1：清理项目
**命令**: `fvm flutter clean`
**目的**: 清理旧的构建文件，避免缓存问题
**预期**: 成功清理所有构建缓存
**实际**: ✅ 成功执行，输出"Deleting build..."
**问题**: 无

### 命令2：获取依赖
**命令**: `fvm flutter pub get`
**目的**: 获取项目所有依赖包
**预期**: 成功下载所有依赖
**实际**: ✅ 成功执行，输出"Running 'flutter pub get'..."
**问题**: 无
```

## 🔄 文档更新

### 发现新命令时：
1. **测试验证**：先测试命令的有效性
2. **分类归档**：按照分类添加到相应章节
3. **添加说明**：提供详细的说明和示例
4. **更新日期**：更新文档的最后修改日期

### 命令过时时：
1. **标记废弃**：使用⚠️标记过时命令
2. **提供替代**：提供新的替代命令
3. **说明原因**：说明为什么命令过时

---

**最后更新：2026-03-26**
**文档状态：生效中**
**下次检查：2026-04-02**

> **提醒**：本文件是AI协作开发规范的一部分，必须严格遵守。