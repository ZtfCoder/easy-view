# 修复 Info.plist 配置问题

## 问题原因
Xcode 项目设置为自动生成 Info.plist（`GENERATE_INFOPLIST_FILE = YES`），导致我们的自定义 Info.plist 被忽略，文件关联配置没有生效。

## 解决方案

### 方法 1：在 Xcode 中手动修改（推荐）

1. **打开 Xcode 项目**
   - 已经打开：`easyView.xcodeproj`

2. **选择项目配置**
   - 在左侧项目导航器中点击 `easyView` 项目（蓝色图标）
   - 在中间选择 `easyView` Target
   - 选择 `Build Settings` 标签

3. **搜索并修改设置**
   - 在搜索框输入：`Info.plist`
   - 找到 `Generate Info.plist File`
   - 将其设置为 **NO**（取消勾选）

4. **指定 Info.plist 路径**
   - 在搜索框输入：`INFOPLIST_FILE`
   - 找到 `Info.plist File` 设置
   - 设置值为：`easyView/Info.plist`

5. **清理并重新构建**
   ```bash
   cd /Users/zhangtengfei/Desktop/code/easyView
   rm -rf build
   ./build_dmg.sh
   ```

### 方法 2：使用命令行修改

运行以下命令：

```bash
cd /Users/zhangtengfei/Desktop/code/easyView

# 使用 xcodeproj 工具修改配置
xcodebuild -project easyView.xcodeproj \
  -target easyView \
  -showBuildSettings | grep INFOPLIST

# 如果没有 xcconfig，需要手动编辑 project.pbxproj
```

### 方法 3：直接编辑 project.pbxproj（最快）

我们可以直接修改项目文件。

## 验证修复

修复后，检查构建的应用：

```bash
plutil -p build/easyView.app/Contents/Info.plist | grep -A 30 CFBundleDocumentTypes
```

应该能看到：
- CFBundleDocumentTypes 数组
- 支持的图片格式列表
- LSHandlerRank = "Alternate"

## 测试文件关联

1. 右键点击任意图片
2. 选择"显示简介"
3. 在"打开方式"中应该能看到 easyView
4. 选择 easyView 并点击"全部更改"
5. 双击图片测试
