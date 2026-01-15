# 动态文件访问权限说明

## 🎯 核心概念

EasyView 使用 **动态文件访问权限**，而不是固定文件夹权限。

### 什么是动态权限？

```
用户选择什么 → 应用就能访问什么
```

- ✅ 用户打开 `/Users/xxx/Downloads/photo.jpg`
  - 应用获得访问该文件的权限
  - 通过安全作用域，应用也能访问 `/Users/xxx/Downloads/` 文件夹
  - 可以浏览该文件夹中的其他图片

- ✅ 用户打开 `/Volumes/USB/vacation/img.jpg`
  - 应用获得访问该文件的权限
  - 可以访问 `/Volumes/USB/vacation/` 文件夹
  - 可以浏览该文件夹中的其他图片

- ✅ 任意位置都可以！

### 与固定权限的区别

#### 固定权限（旧方式）❌
```
com.apple.security.files.downloads.read-write
com.apple.security.assets.pictures.read-write

问题：
- 只能访问特定的系统文件夹
- 不能访问外部硬盘、U盘
- 不能访问自定义文件夹
- 需要用户在系统设置中授权
```

#### 动态权限（我们的方式）✅
```
com.apple.security.files.user-selected.read-only

优势：
- 可以访问任意位置的文件和文件夹
- 用户选择即授权，无需额外弹窗
- 更安全：只能访问用户明确选择的内容
- 更灵活：不限于特定文件夹
```

## 🔧 技术实现

### 1. Entitlements 配置

```xml
<!-- easyView.entitlements -->
<key>com.apple.security.files.user-selected.read-only</key>
<true/>
<key>com.apple.security.app-sandbox</key>
<true/>
```

### 2. 代码实现

```swift
// 用户通过 NSOpenPanel 选择文件
let url = selectedFileURL

// 启动安全作用域访问
let accessing = url.startAccessingSecurityScopedResource()
defer {
    if accessing {
        url.stopAccessingSecurityScopedResource()
    }
}

// 现在可以访问该文件及其父文件夹
let parentDirectory = url.deletingLastPathComponent()
let images = scanDirectory(parentDirectory)
```

### 3. Xcode 配置

```
Signing & Capabilities
└── App Sandbox
    └── File Access
        └── ☑ User Selected File (Read Only)
```

## 🎬 工作流程

### 场景：用户打开 Downloads 中的图片

1. **用户操作**
   ```
   点击"打开" → 选择 Downloads/photo.jpg
   ```

2. **系统行为**
   ```
   - 不会弹出权限对话框（因为是用户主动选择）
   - 应用获得该文件的访问权限
   ```

3. **应用逻辑**
   ```swift
   // 获取文件 URL
   let fileURL = /Users/xxx/Downloads/photo.jpg
   
   // 启动安全作用域
   fileURL.startAccessingSecurityScopedResource()
   
   // 获取父文件夹
   let parentDir = /Users/xxx/Downloads/
   
   // 扫描父文件夹（因为有安全作用域，这是允许的）
   let allImages = scanDirectory(parentDir)
   // 找到：photo1.jpg, photo2.jpg, photo3.jpg, ...
   
   // 用户可以用左右箭头浏览所有图片！
   ```

4. **用户体验**
   ```
   ✅ 打开一张图片
   ✅ 自动加载整个文件夹
   ✅ 可以用箭头切换
   ✅ 没有权限对话框打扰
   ```

## 🌟 优势总结

### 对用户的好处
- ✅ 不需要理解"权限"概念
- ✅ 不需要在系统设置中配置
- ✅ 打开什么就能用什么
- ✅ 可以访问任意位置的图片
- ✅ 外部硬盘、U盘、网络共享都可以

### 对开发者的好处
- ✅ 配置简单（只需一个权限）
- ✅ 不需要申请特定文件夹权限
- ✅ 符合 macOS 安全最佳实践
- ✅ 可以上架 Mac App Store
- ✅ 用户体验更好

### 对安全性的好处
- ✅ 最小权限原则
- ✅ 用户明确控制访问范围
- ✅ 应用不能偷偷访问其他文件
- ✅ 符合 Apple 沙盒安全模型

## 📚 参考文档

- [App Sandbox Design Guide](https://developer.apple.com/library/archive/documentation/Security/Conceptual/AppSandboxDesignGuide/)
- [Security-Scoped Bookmarks](https://developer.apple.com/documentation/foundation/url/2143023-startaccessingsecurityscopedreso)
- [Entitlements Reference](https://developer.apple.com/documentation/bundleresources/entitlements)

## ❓ 常见问题

### Q: 为什么不用 Downloads Folder 权限？
A: 那是固定权限，只能访问 Downloads。动态权限可以访问任意位置。

### Q: 用户会看到权限对话框吗？
A: 不会！因为用户主动选择文件就是授权行为。

### Q: 可以访问外部硬盘吗？
A: 可以！只要用户选择了外部硬盘上的文件。

### Q: 安全吗？
A: 非常安全！应用只能访问用户明确选择的文件和文件夹。

### Q: 需要在 Info.plist 中添加说明吗？
A: 不需要！动态权限不会弹出对话框，所以不需要说明文字。

## ✨ 总结

**动态文件访问权限** = 用户选择什么，应用就能访问什么

这是最灵活、最安全、用户体验最好的方案！🎉
