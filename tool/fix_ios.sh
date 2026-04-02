#!/bin/bash

echo "🚨 [1/4] 物理超度所有 Flutter/iOS 相关进程..."
# 相比原版，增加了 xcodebuild、Simulator 和 ibtoold 的清理。它们才是经常锁死文件的元凶！
killall -9 Xcode 2>/dev/null
killall -9 xcodebuild 2>/dev/null
killall -9 Simulator 2>/dev/null
killall -9 dart 2>/dev/null
killall -9 ibtoold 2>/dev/null # Xcode 的界面构建工具后台
echo "✅ 进程已清理完毕"

echo "🗑️ [2/4] 暴力强删高风险缓存目录 (绕过 flutter clean 的卡死陷阱)..."
# 核心秘诀：不要指望 flutter clean，用系统的 rm -rf 直接抹除，速度极快且不卡！
rm -rf build/
rm -rf .dart_tool/
rm -rf ios/build/
rm -rf ios/Pods/
rm -rf ios/.symlinks/
rm -rf ios/Podfile.lock
rm -rf ios/Flutter/Flutter.podspec
echo "✅ 物理文件已抹除"

echo "🔄 [3/4] 重置 Flutter 环境..."
# 因为大文件已经被我们手动删了，这一步会瞬间完成，绝对不可能卡住
#flutter clean
fvm flutter pub get
echo "✅ Flutter 依赖拉取完成"

echo "📦 [4/4] 重新构建 iOS Pods..."
cd ios || exit
# 加上 --repo-update，防止你切换分支后，新分支的包版本在本地找不到导致报错
pod install --repo-update --verbose
cd ..

echo "🎉 All Done! 环境已彻底净化，现在你可以安心打包了！"