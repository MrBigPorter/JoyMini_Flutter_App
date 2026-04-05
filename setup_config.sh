#!/bin/bash

# 获取项目根目录的绝对路径
PROJECT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
# 自动定位到上一级目录的 flutter_configs
SOURCE_DIR="$( cd "$PROJECT_DIR/../../" && pwd )/flutter_configs"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🚀 正在同步多环境配置文件...${NC}"
echo -e "📍 查找路径: $SOURCE_DIR"

# 检查源目录
if [ ! -d "$SOURCE_DIR" ]; then
    echo -e "${RED}❌ 致命错误: 没找到 $SOURCE_DIR 文件夹！${NC}"
    exit 1
fi

sync_file() {
    local src="$1"
    local dest="$2"
    local name="$3"

    if [ -f "$dest" ]; then
        echo -e "   ℹ️  $name ${GREEN}已存在${NC}，跳过。"
    else
        if [ -f "$src" ]; then
            cp "$src" "$dest"
            echo -e "   ✅ $name ${GREEN}同步成功${NC}。"
        else
            echo -e "   ❌ ${RED}错误: 缺失源文件 $src ${NC}"
            exit 1
        fi
    fi
}

# 1. Android 部分
echo -e "\n🤖 Android 检查:"
sync_file "$SOURCE_DIR/google-services.json" "$PROJECT_DIR/android/app/google-services.json" "google-services.json"
sync_file "$SOURCE_DIR/upload-keystore.jks" "$PROJECT_DIR/android/app/upload-keystore.jks" "upload-keystore.jks"
sync_file "$SOURCE_DIR/debug.keystore" "$PROJECT_DIR/android/app/debug.keystore" "debug.keystore"

# 2. iOS 部分 (两个都拷，保持原名)
echo -e "\n🍎 iOS 多环境检查:"
sync_file "$SOURCE_DIR/GoogleService-Info-prod.plist" "$PROJECT_DIR/ios/Runner/GoogleService-Info-prod.plist" "GoogleService-Info-prod.plist"
sync_file "$SOURCE_DIR/GoogleService-Info-test.plist" "$PROJECT_DIR/ios/Runner/GoogleService-Info-test.plist" "GoogleService-Info-test.plist"

echo -e "\n${GREEN}✨ 搞定！Android 和 iOS 的多环境配置已全部同步。${NC}"