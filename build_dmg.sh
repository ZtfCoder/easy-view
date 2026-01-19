#!/bin/bash

# easyView DMG 打包脚本
# 使用方法: ./build_dmg.sh

set -e  # 遇到错误立即退出

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  easyView DMG 打包脚本${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# 配置
APP_NAME="easyView"
VERSION="1.1"
SCHEME="easyView"
BUILD_DIR="build"
DMG_DIR="dmg_temp"
DMG_NAME="${APP_NAME}-${VERSION}.dmg"

# 1. 清理旧的构建文件
echo -e "${YELLOW}[1/6]${NC} 清理旧的构建文件..."
rm -rf "${BUILD_DIR}"
rm -rf "${DMG_DIR}"
rm -f "${DMG_NAME}"

# 2. 构建 Release 版本
echo -e "${YELLOW}[2/6]${NC} 构建 Release 版本..."
xcodebuild clean \
    -scheme "${SCHEME}" \
    -configuration Release

xcodebuild archive \
    -scheme "${SCHEME}" \
    -configuration Release \
    -archivePath "${BUILD_DIR}/${APP_NAME}.xcarchive" \
    CODE_SIGN_IDENTITY="-" \
    CODE_SIGN_STYLE=Manual \
    DEVELOPMENT_TEAM="" \
    | grep -v "^$" || true

# 3. 导出应用
echo -e "${YELLOW}[3/6]${NC} 导出应用..."
xcodebuild -exportArchive \
    -archivePath "${BUILD_DIR}/${APP_NAME}.xcarchive" \
    -exportPath "${BUILD_DIR}" \
    -exportOptionsPlist export_options.plist \
    | grep -v "^$" || true

# 检查应用是否成功构建
if [ ! -d "${BUILD_DIR}/${APP_NAME}.app" ]; then
    echo -e "${RED}❌ 错误: 应用构建失败${NC}"
    exit 1
fi

echo -e "${GREEN}✅ 应用构建成功: ${BUILD_DIR}/${APP_NAME}.app${NC}"

# 4. 创建 DMG 临时文件夹
echo -e "${YELLOW}[4/6]${NC} 准备 DMG 内容..."
mkdir -p "${DMG_DIR}"
cp -R "${BUILD_DIR}/${APP_NAME}.app" "${DMG_DIR}/"

# 创建应用程序文件夹的符号链接（方便用户拖拽安装）
ln -s /Applications "${DMG_DIR}/Applications"

# 如果有 README，也复制进去
if [ -f "README.md" ]; then
    cp README.md "${DMG_DIR}/使用说明.md"
fi

if [ -f "HOW_TO_SET_DEFAULT_VIEWER.md" ]; then
    cp HOW_TO_SET_DEFAULT_VIEWER.md "${DMG_DIR}/设置为默认查看器.md"
fi

# 5. 创建 DMG
echo -e "${YELLOW}[5/6]${NC} 创建 DMG 文件..."
hdiutil create -volname "${APP_NAME}" \
    -srcfolder "${DMG_DIR}" \
    -ov -format UDZO \
    "${DMG_NAME}"

# 6. 清理临时文件
echo -e "${YELLOW}[6/6]${NC} 清理临时文件..."
rm -rf "${DMG_DIR}"

# 完成
echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}✨ 打包完成！${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "DMG 文件位置: ${GREEN}$(pwd)/${DMG_NAME}${NC}"
echo -e "应用构建位置: ${GREEN}$(pwd)/${BUILD_DIR}/${APP_NAME}.app${NC}"
echo ""
echo -e "📦 DMG 文件大小: $(du -h "${DMG_NAME}" | cut -f1)"
echo ""
echo -e "${YELLOW}安装方法:${NC}"
echo -e "  1. 双击打开 ${DMG_NAME}"
echo -e "  2. 将 ${APP_NAME}.app 拖到 Applications 文件夹"
echo -e "  3. 按照「设置为默认查看器.md」文档配置"
echo ""
