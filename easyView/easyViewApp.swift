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
        // 完全空的 scene，所有窗口由 AppDelegate 管理
        Settings {
            EmptyView()
        }
        .commands {
            // 移除默认的 New Window 命令
            CommandGroup(replacing: .newItem) {}
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var mainWindow: NSWindow?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        print("✅ 应用已启动")
        
        // 延迟检查，如果没有通过双击文件打开，显示文件选择对话框
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            // 关闭所有自动创建的空窗口
            for window in NSApplication.shared.windows {
                if window != self.mainWindow && window.title.isEmpty {
                    window.close()
                }
            }
            
            if self.mainWindow == nil {
                self.showOpenPanel()
            }
        }
    }
    
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag {
            showOpenPanel()
        }
        return true
    }
    
    func application(_ application: NSApplication, open urls: [URL]) {
        print("📂 接收到文件打开请求: \(urls.count) 个文件")
        createAndShowWindow(with: urls)
    }
    
    // 关闭最后一个窗口时退出应用
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
    
    private func showOpenPanel() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = true
        panel.canChooseFiles = true
        panel.allowedContentTypes = [.image]
        panel.message = "选择要预览的图片或文件夹"
        panel.prompt = "打开"
        
        let response = panel.runModal()
        
        if response == .OK && !panel.urls.isEmpty {
            createAndShowWindow(with: panel.urls)
        } else {
            // 用户取消了选择，退出应用
            NSApplication.shared.terminate(nil)
        }
    }
    
    private func createAndShowWindow(with urls: [URL]) {
        // 关闭其他所有窗口
        for window in NSApplication.shared.windows where window != mainWindow {
            window.close()
        }
        
        if let existingWindow = mainWindow, existingWindow.isVisible {
            existingWindow.makeKeyAndOrderFront(nil)
            NotificationCenter.default.post(
                name: NSNotification.Name("OpenFilesFromFinder"),
                object: nil,
                userInfo: ["urls": urls]
            )
        } else {
            let contentView = ContentView()
            let hostingView = NSHostingView(rootView: contentView)
            
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 1200, height: 800),
                styleMask: [.titled, .closable, .miniaturizable, .resizable],
                backing: .buffered,
                defer: false
            )
            
            window.title = "EasyView"
            window.contentView = hostingView
            window.center()
            window.makeKeyAndOrderFront(nil)
            
            self.mainWindow = window
            
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
}
