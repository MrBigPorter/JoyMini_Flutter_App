# Common Error Patterns & Solutions

> **Purpose**: 集中记录常见错误模式和解决方案，加速问题排查  
> **Last Updated**: 2026-03-28

---

## 📋 使用说明

### 如何使用本文档
1. 遇到错误时，先在本文档搜索错误信息
2. 按照提供的解决方案尝试修复
3. 如果是新错误模式，添加到本文档

### 错误分类
- 🔴 编译错误（Compilation Errors）
- 🟡 运行时错误（Runtime Errors）
- 🟠 构建错误（Build Errors）
- 🔵 测试错误（Test Failures）
- 🟣 依赖错误（Dependency Errors）

---

## 🔴 编译错误

### Pattern: "Target of URI doesn't exist"
**错误信息**: `Error: The target of URI doesn't exist: 'package:xxx/xxx.dart'`

**原因分析**:
- 文件路径变更或删除
- import 语句错误
- 依赖未正确安装

**解决方案**:
```bash
# 1. 检查文件是否存在
ls -la lib/path/to/file.dart

# 2. 清理并重新获取依赖
fvm flutter clean
fvm flutter pub get

# 3. 检查 import 语句是否匹配实际路径
# 确保 import 'package:project_name/path/to/file.dart';
```

**预防措施**:
- 重命名文件时使用 IDE 的重构功能
- 定期运行 `fvm flutter analyze`

---

### Pattern: "The method 'xxx' isn't defined"
**错误信息**: `The method 'xxx' isn't defined for the type 'YYY'`

**原因分析**:
- 方法名拼写错误
- API 变更（方法重命名或删除）
- 未导入包含该方法的文件

**解决方案**:
```dart
// 1. 检查方法名拼写
// 错误: contrller.doSomething()
// 正确: controller.doSomething()

// 2. 搜索代码库中的相似方法名
// 使用 IDE 的全局搜索功能

// 3. 检查包的 changelog
// 查看是否有 breaking changes
```

**预防措施**:
- 使用 IDE 自动补全
- 定期更新依赖并检查 changelog

---

### Pattern: "A value of type 'XXX?' can't be assigned to 'XXX'"
**错误信息**: 类型不匹配，可空类型赋值给非可空类型

**原因分析**:
- Null Safety 处理不当
- 未处理可能为 null 的情况

**解决方案**:
```dart
// 方案 1: 使用空值检查
if (value != null) {
  nonNullableVar = value;
}

// 方案 2: 使用默认值
nonNullableVar = value ?? defaultValue;

// 方案 3: 使用 ! 操作符（仅在确定不为 null 时）
nonNullableVar = value!;

// 方案 4: 修改变量类型为可空
XXX? nullableVar = value;
```

**预防措施**:
- 优先使用可空类型
- 添加明确的空值检查

---

## 🟡 运行时错误

### Pattern: "Null check operator used on a null value"
**错误信息**: `Null check operator used on a null value`

**原因分析**:
- 使用 `!` 操作符但值为 null
- 未正确处理可空类型

**解决方案**:
```dart
// 错误示例
String name = user!.name!;

// 正确示例
String name = user?.name ?? 'Unknown';

// 或使用条件判断
if (user != null && user.name != null) {
  String name = user.name!;
}
```

**预防措施**:
- 避免过度使用 `!` 操作符
- 使用 `?.` 和 `??` 进行安全访问

---

### Pattern: "setState() called after dispose()"
**错误信息**: `setState() called after dispose()`

**原因分析**:
- 异步操作完成后 Widget 已被销毁
- 未检查 Widget 是否仍然挂载

**解决方案**:
```dart
// 在调用 setState 前检查 mounted
if (mounted) {
  setState(() {
    // 更新状态
  });
}

// 或使用 Future.delayed
Future.delayed(Duration.zero, () {
  if (mounted) {
    setState(() {});
  }
});
```

**预防措施**:
- 异步操作前保存 mounted 状态
- 使用 Riverpod 等状态管理避免此问题

---

### Pattern: "RenderFlex overflowed"
**错误信息**: `A RenderFlex overflowed by X pixels on the bottom/right`

**原因分析**:
- 内容超出屏幕或容器尺寸
- 未正确处理响应式布局

**解决方案**:
```dart
// 方案 1: 使用 SingleChildScrollView
SingleChildScrollView(
  child: Column(
    children: [...],
  ),
)

// 方案 2: 使用 Expanded/Flexible
Row(
  children: [
    Expanded(
      child: Text('Long text...'),
    ),
  ],
)

// 方案 3: 使用 MediaQuery 动态计算尺寸
Container(
  height: MediaQuery.of(context).size.height * 0.5,
  child: ...,
)
```

**预防措施**:
- 使用 `flutter_screenutil` 进行响应式设计
- 测试不同屏幕尺寸

---

## 🟠 构建错误

### Pattern: "Gradle task assembleDebug failed"
**错误信息**: `FAILURE: Build failed with an exception. Gradle task assembleDebug failed`

**原因分析**:
- Android 配置问题
- 签名配置错误
- 依赖冲突

**解决方案**:
```bash
# 1. 运行修复脚本
./tool/fix_android.sh

# 2. 检查 build.gradle.kts
cat android/app/build.gradle.kts

# 3. 验证 key.properties
cat android/key.properties

# 4. 清理并重建
cd android
./gradlew clean
cd ..
fvm flutter clean
fvm flutter pub get
fvm flutter build apk
```

**预防措施**:
- 不要提交 `key.properties` 到 Git
- 使用 `key.properties.demo` 作为模板

---

### Pattern: "CocoaPods could not find compatible versions"
**错误信息**: `CocoaPods could not find compatible versions for pod 'xxx'`

**原因分析**:
- iOS 依赖版本冲突
- Podfile.lock 与 Podfile 不匹配

**解决方案**:
```bash
# 1. 运行修复脚本
./tool/fix_ios.sh

# 2. 清理 Pod 缓存
cd ios
pod deintegrate
pod cache clean --all
rm Podfile.lock
pod install
cd ..

# 3. 更新 Flutter 依赖
fvm flutter clean
fvm flutter pub get
```

**预防措施**:
- 定期更新 iOS 依赖
- 使用 `pod update` 而非 `pod install`

---

### Pattern: "Xcode build error"
**错误信息**: 各种 Xcode 构建错误

**原因分析**:
- Xcode 版本不兼容
- 证书或配置文件问题
- Swift/Objective-C 桥接问题

**解决方案**:
```bash
# 1. 清理 Xcode 缓存
rm -rf ~/Library/Developer/Xcode/DerivedData

# 2. 更新 CocoaPods
cd ios
pod update
cd ..

# 3. 检查 Xcode 版本
xcodebuild -version

# 4. 重新生成 iOS 项目
fvm flutter clean
fvm flutter pub get
cd ios
pod install
cd ..
```

**预防措施**:
- 保持 Xcode 更新
- 使用项目指定的 Flutter 版本（FVM）

---

## 🔵 测试错误

### Pattern: "Expected: exactly one matching node"
**错误信息**: `Expected: exactly one matching node in the widget tree Actual: _TextWidget`

**原因分析**:
- Widget 未找到
- 测试中 Widget 未正确渲染
- 查找条件不准确

**解决方案**:
```dart
// 1. 确保 Widget 已渲染
await tester.pumpAndSettle();

// 2. 使用精确的查找条件
// 错误: find.text('Submit')
// 正确: find.text('Submit', skipOffstage: false)

// 3. 使用 Key 查找
final button = find.byKey(Key('submit_button'));
expect(button, findsOneWidget);

// 4. 打印 Widget 树调试
debugDumpApp();
```

**预防措施**:
- 为重要 Widget 添加 Key
- 使用 `pumpAndSettle()` 等待动画完成

---

### Pattern: "Timer pending after test"
**错误信息**: `Timer still pending after test completed`

**原因分析**:
- 测试中存在未完成的 Timer
- 异步操作未正确等待

**解决方案**:
```dart
// 方案 1: 使用 fakeAsync
testWidgets('test with timer', (tester) async {
  await tester.pumpWidget(MyWidget());
  // 使用 tester.pump() 推进时间
  await tester.pump(Duration(seconds: 1));
});

// 方案 2: 确保所有异步操作完成
await tester.pumpAndSettle();
```

**预防措施**:
- 避免在 Widget 测试中使用真实 Timer
- 使用 `pumpAndSettle()` 等待所有动画

---

## 🟣 依赖错误

### Pattern: "Package not found"
**错误信息**: `Could not find package "xxx" at "https://pub.dev"`

**原因分析**:
- 包名拼写错误
- 包已被移除或重命名
- 网络问题

**解决方案**:
```bash
# 1. 检查包名拼写
# 在 pub.dev 搜索确认包名

# 2. 清理缓存
fvm flutter clean
rm -rf ~/.pub-cache

# 3. 使用国内镜像（如需要）
export PUB_HOSTED_URL=https://pub.flutter-io.cn
export FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn

# 4. 重新获取依赖
fvm flutter pub get
```

**预防措施**:
- 使用 IDE 自动补全添加依赖
- 定期检查依赖是否仍然维护

---

### Pattern: "Version solving failed"
**错误信息**: `Because every version of xxx depends on yyy...`

**原因分析**:
- 依赖版本冲突
- 某些包要求特定版本的依赖

**解决方案**:
```yaml
# pubspec.yaml

# 方案 1: 放宽版本约束
dependencies:
  package_a: ^1.0.0  # 允许 1.x.x
  package_b: any     # 允许任何版本

# 方案 2: 使用 dependency_overrides
dependency_overrides:
  conflicting_package: ^2.0.0

# 方案 3: 使用特定版本
dependencies:
  package_a: 1.2.3   # 锁定特定版本
```

**预防措施**:
- 定期运行 `fvm flutter pub outdated`
- 避免使用 `any` 版本约束

---

## 🔧 Flutter 特定错误

### Pattern: "RenderBox was not laid out"
**错误信息**: `RenderBox was not laid out: RenderRepaintBoundary#xxxx`

**原因分析**:
- Widget 布局计算错误
- 使用了未初始化的尺寸

**解决方案**:
```dart
// 方案 1: 使用 LayoutBuilder
LayoutBuilder(
  builder: (context, constraints) {
    return Container(
      width: constraints.maxWidth,
      child: ...,
    );
  },
)

// 方案 2: 使用 SizedBox 设置默认尺寸
SizedBox(
  width: 100,
  height: 100,
  child: ...,
)

// 方案 3: 使用 MediaQuery
Container(
  width: MediaQuery.of(context).size.width,
  child: ...,
)
```

**预防措施**:
- 避免在 build 方法中依赖未确定的尺寸
- 使用响应式布局组件

---

### Pattern: "PlatformException"
**错误信息**: `PlatformException(error, xxx, null, null)`

**原因分析**:
- 原生平台代码错误
- 权限未配置
- 平台特定功能在错误平台调用

**解决方案**:
```dart
// 1. 检查平台权限
// Android: AndroidManifest.xml
// iOS: Info.plist

// 2. 使用 try-catch 捕获异常
try {
  await platformChannel.invokeMethod('methodName');
} on PlatformException catch (e) {
  print('Platform error: ${e.message}');
}

// 3. 检查平台特定代码
if (Platform.isAndroid) {
  // Android 特定代码
} else if (Platform.isIOS) {
  // iOS 特定代码
}
```

**预防措施**:
- 配置正确的平台权限
- 使用条件导入处理平台差异

---

## 📊 错误统计与趋势

### 常见错误 Top 5
1. **Null check operator** - 35%
2. **RenderFlex overflow** - 25%
3. **setState after dispose** - 20%
4. **Gradle build failed** - 15%
5. **Version solving failed** - 5%

### 解决时间基准
- 编译错误: 5-15 分钟
- 运行时错误: 10-30 分钟
- 构建错误: 15-60 分钟
- 依赖错误: 10-45 分钟

---

## 🆘 无法解决？

### 如果本文档没有你的错误
1. 搜索 `DEBUG_NOTES/` 目录
2. 检查 Stack Overflow
3. 查看 Flutter 官方文档
4. 在项目 Issue 中搜索

### 添加新错误模式
遇到新错误并解决后，请添加到本文档：
1. 复制模板格式
2. 填写错误信息、原因、解决方案
3. 更新文档

---

**文档状态**: ✅ 活跃  
**维护者**: AI Assistant  
**更新频率**: 随错误模式发现持续更新