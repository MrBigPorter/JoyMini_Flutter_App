#!/bin/bash

echo "💀 [1/6] 正在猎杀所有平台的卡死进程 (Java/Dart/Xcode/Chrome)..."
# 杀掉所有可能占用文件的进程
killall -9 java 2>/dev/null
killall Xcode 2>/dev/null
pkill -f gradle 2>/dev/null
pkill -f xcodebuild 2>/dev/null
pkill -f dart 2>/dev/null
pkill -f chrome 2>/dev/null

echo "🌪️ [2/6] 正在粉碎 Flutter 通用构建缓存..."
# 暴力秒删，不走慢悠悠的 flutter clean
rm -rf build/
rm -rf .dart_tool/
rm -rf .flutter-plugins
rm -rf .flutter-plugins-dependencies

echo "🤖 [3/6] 正在清理 Android 专属顽固缓存..."
rm -rf android/.gradle/
rm -rf android/app/build/
rm -rf android/build/

echo "🍎 [4/6] 正在清理 iOS 专属缓存 & 衍生数据..."
rm -rf ios/Pods/
rm -rf ios/Podfile.lock
rm -rf ios/.symlinks/
rm -rf ~/Library/Developer/Xcode/DerivedData/*

echo "🌐 [5/6] 正在清理 Web 专属编译产物..."
# Web 编译产物通常在 build/web，上面已经删了，这里确保环境干净
rm -rf .pub-cache/

echo "📦 [6/6] 正在重新拉取依赖 & 刷新环境..."
fvm flutter pub get

# 如果是在 Mac 上，顺便把 iOS 的 Pods 装了（非 Mac 会自动跳过）
if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "🍏 检测到 macOS，正在同步安装 iOS Pods..."
    cd ios && pod install && cd ..
fi

echo "✅ 所有平台环境已彻底净化！"
echo "🚀 Porter，你可以重新起飞了 (fvm flutter run)！"