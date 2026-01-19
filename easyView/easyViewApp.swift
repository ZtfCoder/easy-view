//
//  easyViewApp.swift
//  easyView
//
//  Created by 张腾飞 on 2025/10/16.
//

import SwiftUI
import AppKit
import UniformTypeIdentifiers

@main
struct easyViewApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            SettingsView()
        }
        .commands {
            CommandGroup(replacing: .newItem) {}
        }
    }
    
    init() {
        // 在初始化时禁用窗口状态恢复
        UserDefaults.standard.set(false, forKey: "NSQuitAlwaysKeepsWindows")
        UserDefaults.standard.set(true, forKey: "ApplePersistenceIgnoreState")
    }
}

class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    var mainWindow: NSWindow?
    private var pendingURLs: [URL] = []
    
    func applicationWillFinishLaunching(_ notification: Notification) {
        // 在应用启动前禁用窗口恢复，防止崩溃恢复弹窗
        UserDefaults.standard.set(false, forKey: "NSQuitAlwaysKeepsWindows")
        UserDefaults.standard.set(true, forKey: "ApplePersistenceIgnoreState")
    }
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // 设置应用激活策略，确保应用保持运行
        NSApp.setActivationPolicy(.regular)
        
        // 如果有待处理的 URL（从 Finder 打开），先处理它们
        if !pendingURLs.isEmpty {
            let urls = pendingURLs
            pendingURLs.removeAll()
            createAndShowWindow(with: urls)
            return
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            for window in NSApplication.shared.windows {
                // 只关闭空标题的临时窗口，保留主窗口和设置窗口
                if window == self.mainWindow { continue }
                if window.identifier?.rawValue.contains("settings") == true { continue }
                if window.className.contains("Settings") { continue }
                if window.title.isEmpty && !window.isVisible {
                    window.close()
                }
            }
            if self.mainWindow == nil {
                self.showOpenPanel()
            }
        }
    }
    
    func application(_ application: NSApplication, open urls: [URL]) {
        createAndShowWindow(with: urls)
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        // 关闭窗口后退出应用
        return true
    }
    
    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        // 禁用安全的状态恢复
        return false
    }
    
    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        // 只有用户明确退出时才允许退出
        return .terminateNow
    }
    
    // 窗口即将关闭时的处理
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        return true
    }
    
    // 窗口关闭时清理引用
    func windowWillClose(_ notification: Notification) {
        if let window = notification.object as? NSWindow, window == mainWindow {
            NotificationCenter.default.removeObserver(self, name: NSNotification.Name("ImageChanged"), object: nil)
            mainWindow = nil
        }
    }
    
    private func showOpenPanel() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = true
        panel.canChooseFiles = true
        panel.allowedContentTypes = [.image]
        panel.message = "选择要预览的图片或文件夹"
        panel.prompt = "打开"
        
        if panel.runModal() == .OK && !panel.urls.isEmpty {
            createAndShowWindow(with: panel.urls)
        }
        // 取消时不退出，保留在 Dock
    }
    
    private func createAndShowWindow(with urls: [URL]) {
        // 关闭其他非设置窗口（保留 Settings 窗口）
        for window in NSApplication.shared.windows {
            // 跳过主窗口、设置窗口和其他系统窗口
            if window == mainWindow { continue }
            if window.identifier?.rawValue.contains("settings") == true { continue }
            if window.className.contains("Settings") { continue }
            // 只关闭空标题的临时窗口
            if window.title.isEmpty && !window.isVisible {
                window.close()
            }
        }
        
        // 获取第一张图片的尺寸来设置窗口大小
        let windowSize = calculateWindowSize(for: urls)
        
        // 如果已有窗口且可见，复用它
        if let existingWindow = mainWindow, existingWindow.isVisible {
            resizeWindow(existingWindow, to: windowSize)
            existingWindow.makeKeyAndOrderFront(nil)
            NotificationCenter.default.post(
                name: NSNotification.Name("OpenFilesFromFinder"),
                object: nil,
                userInfo: ["urls": urls]
            )
        } else {
            // 创建新窗口
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: windowSize.width, height: windowSize.height),
                styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
                backing: .buffered,
                defer: false
            )
            
            // 禁用窗口恢复
            window.isRestorable = false
            
            // 设置窗口代理以监听关闭事件
            window.delegate = self
            
            // 标题栏透明，内容延伸到标题栏下方
            window.titlebarAppearsTransparent = true
            window.titleVisibility = .hidden
            window.backgroundColor = .black
            window.isMovableByWindowBackground = true
            
            // 创建 ContentView 并设置为窗口内容
            let contentView = ContentView()
            window.contentView = NSHostingView(rootView: contentView)
            window.center()
            window.makeKeyAndOrderFront(nil)
            
            self.mainWindow = window
            
            // 监听图片变化通知，动态调整窗口大小
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(handleImageChanged(_:)),
                name: NSNotification.Name("ImageChanged"),
                object: nil
            )
            
            if !urls.isEmpty {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    NotificationCenter.default.post(
                        name: NSNotification.Name("OpenFilesFromFinder"),
                        object: nil,
                        userInfo: ["urls": urls]
                    )
                }
            }
        }
    }
    
    private func calculateWindowSize(for urls: [URL]) -> NSSize {
        // 找到第一个图片文件
        let imageURL: URL? = urls.first { url in
            if url.hasDirectoryPath { return false }
            let ext = url.pathExtension.lowercased()
            return ["jpg", "jpeg", "png", "gif", "heic", "webp", "tiff", "bmp"].contains(ext)
        } ?? {
            // 如果是文件夹，找里面的第一张图片
            if let dir = urls.first, dir.hasDirectoryPath {
                let contents = try? FileManager.default.contentsOfDirectory(
                    at: dir,
                    includingPropertiesForKeys: nil,
                    options: [.skipsHiddenFiles]
                )
                return contents?.first { url in
                    let ext = url.pathExtension.lowercased()
                    return ["jpg", "jpeg", "png", "gif", "heic", "webp", "tiff", "bmp"].contains(ext)
                }
            }
            return nil
        }()
        
        guard let url = imageURL,
              let image = NSImage(contentsOf: url) else {
            return NSSize(width: 800, height: 600)
        }
        
        return fitImageSize(image.size)
    }
    
    private func fitImageSize(_ imageSize: NSSize) -> NSSize {
        guard let screen = NSScreen.main else {
            return NSSize(width: 800, height: 600)
        }
        
        let screenFrame = screen.visibleFrame
        let maxWidth = screenFrame.width * 0.85
        let maxHeight = screenFrame.height * 0.85
        let minSize: CGFloat = 400
        
        var width = imageSize.width
        var height = imageSize.height
        
        // 如果图片太大，按比例缩小
        if width > maxWidth || height > maxHeight {
            let widthRatio = maxWidth / width
            let heightRatio = maxHeight / height
            let ratio = min(widthRatio, heightRatio)
            width *= ratio
            height *= ratio
        }
        
        // 确保最小尺寸
        width = max(width, minSize)
        height = max(height, minSize)
        
        return NSSize(width: width, height: height)
    }
    
    private func resizeWindow(_ window: NSWindow, to size: NSSize) {
        var frame = window.frame
        let oldCenter = NSPoint(x: frame.midX, y: frame.midY)
        
        frame.size = size
        frame.origin.x = oldCenter.x - size.width / 2
        frame.origin.y = oldCenter.y - size.height / 2
        
        window.setFrame(frame, display: true, animate: true)
    }
    
    @objc private func handleImageChanged(_ notification: Notification) {
        guard let window = mainWindow,
              let imageSize = notification.userInfo?["imageSize"] as? NSSize else { return }
        
        let newSize = fitImageSize(imageSize)
        resizeWindow(window, to: newSize)
    }
}
