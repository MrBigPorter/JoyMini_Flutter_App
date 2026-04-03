#!/bin/bash

echo "💀 [1/6] 正在猎杀所有平台的卡死进程..."
killall -9 java 2>/dev/null
killall Xcode 2>/dev/null
pkill -f gradle 2>/dev/null
pkill -f xcodebuild 2>/dev/null
pkill -f dart 2>/dev/null
pkill -f chrome 2>/dev/null

echo "🌪️ [2/6] 正在粉碎 Flutter 通用构建缓存..."
rm -rf build/
rm -rf .dart_tool/
rm -rf .flutter-plugins
rm -rf .flutter-plugins-dependencies
# 建议加上这句，清理旧版 pub 缓存配置
rm -f .packages

echo "🍏 [Xcode 26 fix] 清理遗留的 iOS 构建产物（防止 Xcode 26 删除权限错误）..."
rm -rf build/ios/ 2>/dev/null || true

echo "🤖 [3/6] 正在清理 Android 专属顽固缓存..."
rm -rf android/.gradle/
rm -rf android/app/build/
rm -rf android/build/

echo "🍎 [4/6] 正在清理 iOS 专属缓存 & 衍生数据..."
rm -rf ios/Pods/
rm -rf ios/.symlinks/
# ⚠️ 注意：移除了 rm -rf ios/Podfile.lock
# 只有在依赖版本严重冲突，或者更新了 pubspec.yaml 中的大版本时，才需要手动删 lock 文件
rm -rf ~/Library/Developer/Xcode/DerivedData/*

echo "🌐 [5/6] 正在清理 Web 专属编译产物..."
rm -rf .pub-cache/

echo "📦 [6/6] 正在重新拉取依赖 & 刷新环境..."
fvm flutter pub get

if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "🍏 检测到 macOS，正在同步安装 iOS Pods..."
    cd ios && pod install && cd ..
fi

echo "✅ 所有平台环境已彻底净化！"
echo "🚀 Porter，你可以重新起飞了 (fvm flutter run)！"