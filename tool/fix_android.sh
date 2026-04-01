#!/bin/bash

# 终端跑这最后的大招，慎用！会删除所有项目的 Gradle 缓存
# rm -rf ~/.gradle/caches/

echo "💀 [1/4] Killing Gradle, Java, and Dart processes..."
# 1. 先赋予权限，防止静默失败
chmod +x android/gradlew 2>/dev/null
# 2. 温柔地停止 Gradle 守护进程
./android/gradlew --stop 2>/dev/null
# 3. 物理超度所有可能锁文件的僵尸进程
killall -9 java 2>/dev/null
killall -9 dart 2>/dev/null

echo "🧨 [2/4] Nuking Android & Flutter build cache (Bypassing locks)..."
# 核心秘诀：先暴力删，再 flutter clean，绝对不卡！
rm -rf build/
rm -rf .dart_tool/

cd android || exit
# 删除项目级的 Gradle 配置缓存（经常导致莫名其妙的编译失败）
rm -rf .gradle
# 删除原生的构建产物
rm -rf app/build
rm -rf build
cd ..

echo "🧹 [3/4] Resetting Flutter Environment..."
#flutter clean
flutter pub get

echo "🔄 [4/4] Running Gradle clean..."
cd android || exit
# 让 Gradle 自己再过一遍，确保没有遗漏
./gradlew clean
cd ..

echo "✅ Android environment fixed! 喝口水，第一次打包会去下载依赖，请耐心等待。"