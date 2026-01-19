# easyView 打包指南

## 快速打包成 DMG

### 使用自动化脚本

```bash
cd /Users/zhangtengfei/Desktop/code/easyView
chmod +x build_dmg.sh
./build_dmg.sh
```

完成后会生成 `easyView-1.1.dmg` 文件。

### 手动打包

1. 在 Xcode 中：Product → Archive
2. 在 Organizer 中：Distribute App → Copy App → Export
3. 创建 DMG：

```bash
mkdir dmg_temp
cp -R easyView.app dmg_temp/
ln -s /Applications dmg_temp/Applications
hdiutil create -volname "easyView" -srcfolder dmg_temp -ov -format UDZO easyView-1.1.dmg
rm -rf dmg_temp
```

## 安装方法

1. 双击打开 DMG 文件
2. 拖拽 easyView.app 到 Applications 文件夹
3. 首次运行如遇"无法验证开发者"提示，右键点击应用选择"打开"

## 版本管理

发布新版本时：
1. 修改 Info.plist 中的 `CFBundleShortVersionString` 和 `CFBundleVersion`
2. 更新 `build_dmg.sh` 中的 `VERSION` 变量
3. 重新打包
