# 配置 Xcode 项目以获取文件夹访问权限

## 📋 配置步骤

### 1. 添加 Entitlements 文件

已创建文件：`easyView/easyView.entitlements`

该文件包含以下权限：
- ✅ **用户选择的文件只读权限**（动态权限，核心！）
  - 用户选择什么文件/文件夹，应用就能访问什么
  - 不限于特定文件夹，可以是任意位置
- ✅ App Sandbox 启用（必需）
- ✅ 网络访问权限（可选）

### 2. 在 Xcode 中配置项目

#### 步骤 A：打开项目设置
1. 在 Xcode 中打开 `easyView.xcodeproj`
2. 在左侧导航栏选择项目根节点（蓝色图标）
3. 选择 `easyView` target
4. 点击顶部的 "Signing & Capabilities" 标签

#### 步骤 B：添加 App Sandbox
1. 点击 "+ Capability" 按钮
2. 搜索并添加 "App Sandbox"
3. 在 App Sandbox 区域，勾选以下选项：
   - ✅ **User Selected File**: Read Only（核心权限！）
   - ❌ **不需要勾选** Downloads Folder、Pictures Folder 等固定文件夹
   - 这是动态权限，用户选择什么就能访问什么

#### 步骤 C：关联 Entitlements 文件
1. 在 "Signing & Capabilities" 标签下
2. 找到 "Code Signing Entitlements" 字段
3. 输入：`easyView/easyView.entitlements`

或者在 "Build Settings" 中：
1. 点击 "Build Settings" 标签
2. 搜索 "Code Signing Entitlements"
3. 设置值为：`easyView/easyView.entitlements`

#### 步骤 D：添加 Info.plist（如果需要）
1. 点击 "Info" 标签
2. 确认 Info.plist 文件路径正确
3. 或者在 "Build Settings" 中搜索 "Info.plist File"
4. 设置为：`easyView/Info.plist`

### 3. 验证配置

重新构建并运行应用：

```bash
# Clean build
⌘ + Shift + K

# Build and run
⌘ + R
```

### 4. 测试权限

1. 运行应用
2. 点击"打开"按钮
3. 选择 Downloads 文件夹中的图片
4. 现在应该可以正常浏览整个文件夹了！

## 🔍 权限说明

### com.apple.security.files.user-selected.read-only ⭐
- **动态权限**：允许访问用户通过文件选择器选择的任意文件和文件夹
- **不限位置**：可以是 Downloads、Pictures、Documents，或任何其他位置
- **自动授权**：用户选择即授权，无需额外弹窗
- **安全作用域**：使用 `startAccessingSecurityScopedResource()` 访问文件及其父文件夹

### com.apple.security.app-sandbox
- 启用 App Sandbox（必需）
- macOS 安全要求，所有 Mac App Store 应用必须启用
- 与动态权限配合使用，提供安全的文件访问机制

## 📱 用户体验

配置完成后，用户体验：

1. **打开任意位置的图片**
   - ✅ Downloads、Pictures、Documents、桌面
   - ✅ 外部硬盘、U盘
   - ✅ 任何用户可访问的文件夹
   - ❌ **不会弹出权限对话框**（因为是用户主动选择的）

2. **自动扫描父文件夹**
   - 打开单个图片时，自动读取同文件夹的其他图片
   - 使用安全作用域机制，确保有权限访问

3. **无需重复授权**
   - 每次通过文件选择器选择即自动授权
   - 不需要在系统设置中管理权限

## ⚠️ 注意事项

### 开发签名
如果你使用个人开发者账号或本地测试：
- 在 "Signing & Capabilities" 中
- "Team" 选择你的开发者账号
- 或选择 "Sign to Run Locally"

### 发布到 Mac App Store
如果计划发布到 Mac App Store：
- 需要有效的 Apple Developer 账号
- 需要创建 App ID 和 Provisioning Profile
- 需要通过 App Store Review

### 权限被拒绝
如果用户不小心拒绝了权限：
1. 打开"系统设置"
2. 选择"隐私与安全性"
3. 找到"文件和文件夹"
4. 找到 EasyView
5. 手动勾选需要的文件夹权限

## 🎯 快速配置清单（简化版）

- [ ] 创建 `easyView.entitlements` 文件 ✅
- [ ] 在 Xcode 中添加 App Sandbox capability
- [ ] **只勾选 User Selected File (Read Only)** ⭐
- [ ] 设置 Code Signing Entitlements 路径：`easyView/easyView.entitlements`
- [ ] Clean 并重新 Build
- [ ] 测试打开任意位置的图片（Downloads、Desktop、外部硬盘等）

**不需要**：
- ❌ 固定的 Downloads Folder 权限
- ❌ 固定的 Pictures Folder 权限
- ❌ Info.plist 中的权限说明（动态权限不需要弹窗）

## 📚 参考资料

- [Apple: App Sandbox](https://developer.apple.com/documentation/security/app_sandbox)
- [Apple: Entitlements](https://developer.apple.com/documentation/bundleresources/entitlements)
- [Apple: File System Programming Guide](https://developer.apple.com/library/archive/documentation/FileManagement/Conceptual/FileSystemProgrammingGuide/Introduction/Introduction.html)
