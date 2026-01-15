//
//  easyViewApp.swift
//  easyView
//
//  Created by 张腾飞 on 2025/10/16.
//

import SwiftUI
import AppKit

@main
struct easyViewApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        // 使用空的 Settings scene，防止 SwiftUI 自动创建窗口
        Settings {
            EmptyView()
        }
    }
}

// AppDelegate 完全手动控制窗口
class AppDelegate: NSObject, NSApplicationDelegate {
    var mainWindow: NSWindow?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        print("✅ 应用已启动，等待文件打开请求...")
        // 不自动创建窗口，等待用户打开文件
    }
    
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        print("👆 用户点击了 Dock 图标")
        // 用户点击 Dock 图标时的行为
        if !flag {
            // 如果没有可见窗口，创建一个空窗口
            createAndShowWindow(with: [])
        }
        return true
    }
    
    func application(_ application: NSApplication, open urls: [URL]) {
        print("📂 接收到文件打开请求: \(urls.count) 个文件")
        print("   文件列表: \(urls.map { $0.lastPathComponent })")
        
        // 创建或更新窗口，直接传递文件 URLs
        createAndShowWindow(with: urls)
    }
    
    private func createAndShowWindow(with urls: [URL]) {
        if let existingWindow = mainWindow, existingWindow.isVisible {
            print("🔄 复用现有窗口，发送通知更新内容")
            // 窗口已存在，通过通知更新内容
            existingWindow.makeKeyAndOrderFront(nil)
            NotificationCenter.default.post(
                name: NSNotification.Name("OpenFilesFromFinder"),
                object: nil,
                userInfo: ["urls": urls]
            )
        } else {
            print("🆕 创建新窗口")
            // 创建新窗口
            let contentView = ContentView()
            let hostingView = NSHostingView(rootView: contentView)
            
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 1200, height: 800),
                styleMask: [.titled, .closable, .miniaturizable, .resizable],
                backing: .buffered,
                defer: false
            )
            
            window.title = "easyView"
            window.contentView = hostingView
            window.center()
            window.makeKeyAndOrderFront(nil)
            window.isReleasedWhenClosed = false
            
            self.mainWindow = window
            
            // 如果有文件，延迟发送通知（等待 ContentView 初始化完成）
            if !urls.isEmpty {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    print("📤 发送通知，传递 \(urls.count) 个文件")
                    NotificationCenter.default.post(
                        name: NSNotification.Name("OpenFilesFromFinder"),
                        object: nil,
                        userInfo: ["urls": urls]
                    )
                }
            }
        }
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        // 关闭最后一个窗口时不退出应用
        return false
    }
}
