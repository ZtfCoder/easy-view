# Xcode 项目配置指南

## 配置步骤

### 1. 打开项目设置

1. 在 Xcode 中打开 `easyView.xcodeproj`
2. 选择左侧项目根节点（蓝色图标）
3. 选择 `easyView` target
4. 点击 "Signing & Capabilities" 标签

### 2. 添加 App Sandbox

1. 点击 "+ Capability" 按钮
2. 搜索并添加 "App Sandbox"
3. 在 File Access 部分勾选：
   - ✅ User Selected File (Read Only)

### 3. 设置 Entitlements 文件

在 "Build Settings" 中搜索 "entitlements"，设置：
```
Code Signing Entitlements: easyView/easyView.entitlements
```

### 4. 构建运行

```bash
# Clean
⌘ + Shift + K

# Build and Run
⌘ + R
```

## 验证配置

运行应用后打开图片，如果能正常浏览同文件夹的其他图片，说明配置成功。

## 参考

- [App Sandbox](https://developer.apple.com/documentation/security/app_sandbox)
- [Entitlements](https://developer.apple.com/documentation/bundleresources/entitlements)
