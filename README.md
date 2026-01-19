# EasyView - macOS 图片预览器

一个简洁高效的 macOS 图片预览应用，使用 SwiftUI 构建。

## 主要特性

### 🖼️ 图片浏览
- 支持打开单个或多个图片文件
- 打开单个图片时，自动加载同文件夹下的所有图片
- 支持选择整个文件夹
- 支持格式：JPG, JPEG, PNG, GIF, HEIC, WebP, TIFF, BMP
- 按文件名自动排序

### 🔍 缩放功能
- 触控板双指捏合缩放
- Command + 滚轮缩放
- 双击图片重置缩放

### 🎮 导航控制
- 点击左右箭头按钮切换图片
- 键盘左右方向键切换
- ESC 键关闭窗口

### ⚡ 性能优化
- 图片缓存机制（NSCache）
- 异步加载图片
- 预加载相邻图片

### 🎨 用户体验
- 沉浸式 UI，控件自动隐藏
- 拖拽平移查看图片细节
- 窗口大小自适应图片尺寸
- 窗口置顶功能

## 使用方法

### 打开图片
1. 启动应用后会弹出文件选择器
2. 选择图片文件或文件夹
3. 也可以在 Finder 中双击图片用 easyView 打开

### 缩放图片
- **触控板**：双指捏合
- **鼠标**：Command + 滚轮
- **重置**：双击图片

### 浏览图片
- **鼠标**：点击左右箭头按钮
- **键盘**：左右方向键 ← →

### 关闭
- 点击窗口关闭按钮或按 ESC 键
- 关闭窗口后应用会退出

## 系统要求

- macOS 12.0 或更高版本

## 构建运行

```bash
# 在 Xcode 中打开
open easyView.xcodeproj

# 或使用命令行构建
xcodebuild -scheme easyView build
```

## 文件结构

```
easyView/
├── easyView/
│   ├── ContentView.swift       # 主视图
│   ├── ImageCache.swift        # 图片缓存
│   ├── BookmarkManager.swift   # 书签管理
│   ├── SettingsView.swift      # 设置页面
│   ├── easyViewApp.swift       # 应用入口
│   ├── Info.plist              # 应用配置
│   └── Assets.xcassets/        # 资源文件
├── easyView.xcodeproj/         # Xcode 项目
└── README.md
```

## 版本历史

- **1.1** - 修复窗口恢复弹窗问题，优化应用生命周期
- **1.0** - 初始版本

## 许可证

本项目仅供学习和个人使用。

