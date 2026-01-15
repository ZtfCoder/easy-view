# easyView 打包指南

## 🎁 快速打包成 DMG

### 方法一：使用自动化脚本（推荐）

1. **打开终端**，进入项目目录：
   ```bash
   cd /Users/zhangtengfei/Desktop/code/easyView
   ```

2. **给脚本添加执行权限**：
   ```bash
   chmod +x build_dmg.sh
   ```

3. **运行打包脚本**：
   ```bash
   ./build_dmg.sh
   ```

4. **等待完成**，会生成 `easyView-1.0.dmg` 文件

### 方法二：Xcode 手动打包

#### 步骤 1：构建 Release 版本

1. 在 Xcode 中打开项目
2. 选择菜单：**Product** → **Archive**
3. 等待构建完成（可能需要几分钟）

#### 步骤 2：导出应用

1. 构建完成后会自动打开 **Organizer** 窗口
2. 选择刚才构建的 Archive
3. 点击右侧的 **Distribute App** 按钮
4. 选择 **Copy App**
5. 点击 **Next** → **Export**
6. 选择保存位置，会得到 `easyView.app`

#### 步骤 3：创建 DMG

在终端中运行：

```bash
# 创建临时文件夹
mkdir dmg_temp
cp -R easyView.app dmg_temp/

# 创建 Applications 符号链接
ln -s /Applications dmg_temp/Applications

# 创建 DMG
hdiutil create -volname "easyView" -srcfolder dmg_temp -ov -format UDZO easyView-1.0.dmg

# 清理临时文件
rm -rf dmg_temp
```

## 📦 DMG 内容说明

打包后的 DMG 文件包含：
- ✅ **easyView.app** - 主应用程序
- ✅ **Applications** - 应用程序文件夹的快捷方式（方便拖拽安装）
- ✅ **使用说明.md** - README 文档
- ✅ **设置为默认查看器.md** - 配置说明

## 🚀 分发 DMG

### 安装方法（提供给用户）

1. **双击打开** `easyView-1.0.dmg`
2. **拖拽** `easyView.app` 到 `Applications` 文件夹
3. 在应用程序文件夹中找到 easyView，双击运行
4. 如果遇到"无法验证开发者"提示：
   - 右键点击应用 → 选择"打开"
   - 在弹出的对话框中点击"打开"
   - 或者在"系统偏好设置" → "安全性与隐私" → 点击"仍要打开"

### 文件大小优化

如果 DMG 文件太大，可以尝试：

1. **清理构建缓存**：
   ```bash
   xcodebuild clean
   rm -rf ~/Library/Developer/Xcode/DerivedData/*
   ```

2. **使用压缩格式**：
   ```bash
   hdiutil create -volname "easyView" -srcfolder dmg_temp -ov -format UDBZ easyView-1.0.dmg
   ```
   （UDBZ 比 UDZO 压缩率更高）

3. **移除符号表**：
   在 Xcode Build Settings 中设置：
   - Strip Debug Symbols During Copy: Yes
   - Strip Swift Symbols: Yes

## 🔐 代码签名（可选）

如果你有 Apple Developer 账号，可以对应用进行签名：

1. 在 Xcode 中配置 Signing & Capabilities
2. 选择你的开发团队
3. 在 `build_dmg.sh` 中修改：
   ```bash
   CODE_SIGN_IDENTITY="Developer ID Application: Your Name (TEAM_ID)"
   DEVELOPMENT_TEAM="YOUR_TEAM_ID"
   ```

签名后的应用可以直接在其他 Mac 上运行，不会出现安全警告。

### 公证（Notarization）

如果需要上传到 Mac App Store 或公开分发，还需要进行公证：

```bash
# 上传公证
xcrun notarytool submit easyView-1.0.dmg \
  --apple-id "your@email.com" \
  --password "app-specific-password" \
  --team-id "TEAM_ID" \
  --wait

# 检查公证状态
xcrun stapler staple easyView-1.0.dmg
```

## 🐛 常见问题

### 问题 1：构建失败

**错误**: `xcodebuild: error: Scheme easyView is not currently configured for the archive action.`

**解决**: 
1. 打开 Xcode
2. 选择 Product → Scheme → Edit Scheme
3. 在 Archive 选项卡中，确保 Build Configuration 设置为 Release

### 问题 2：权限错误

**错误**: `Permission denied`

**解决**:
```bash
chmod +x build_dmg.sh
```

### 问题 3：DMG 打开失败

**错误**: `hdiutil: create failed - Resource busy`

**解决**:
```bash
# 卸载可能已挂载的镜像
hdiutil detach /Volumes/easyView 2>/dev/null || true
# 删除旧的 DMG
rm -f easyView-1.0.dmg
# 重新运行脚本
./build_dmg.sh
```

## 📊 版本管理

每次发布新版本时：

1. 修改版本号（在 Xcode 项目设置中）
2. 更新 `build_dmg.sh` 中的 `VERSION` 变量
3. 更新 CHANGELOG（如果有）
4. 重新打包

## 🌟 最佳实践

1. **测试**: 在打包前充分测试应用
2. **版本号**: 使用语义化版本号（如 1.0.0, 1.1.0）
3. **文档**: 在 DMG 中包含清晰的使用说明
4. **大小**: 尽量减小应用体积，提升下载体验
5. **命名**: 使用清晰的命名，包含版本号

## 📝 检查清单

打包前确认：
- [ ] 应用在本地运行正常
- [ ] 版本号已更新
- [ ] 图标已设置
- [ ] Info.plist 配置正确
- [ ] README 文档完整
- [ ] 所有功能已测试
- [ ] 无编译警告
- [ ] 文件权限配置正确

打包后确认：
- [ ] DMG 可以正常打开
- [ ] 应用可以拖拽到 Applications
- [ ] 应用可以正常启动
- [ ] 文档可以正常查看
- [ ] 文件大小合理
