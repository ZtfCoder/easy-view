//
//  SettingsView.swift
//  easyView
//
//  设置页面 - 管理授权文件夹
//

import SwiftUI
import AppKit

struct SettingsView: View {
    @State private var authorizedFolders: [String] = []
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            // 标题栏
            HStack {
                Text("设置")
                    .font(.headline)
                Spacer()
            }
            .padding()
            .background(Color(NSColor.windowBackgroundColor))
            
            Divider()
            
            // 内容区域
            VStack(alignment: .leading, spacing: 16) {
                // 授权文件夹部分
                Text("授权访问的文件夹")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                if authorizedFolders.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "folder.badge.questionmark")
                            .font(.system(size: 40))
                            .foregroundColor(.secondary)
                        Text("暂无授权文件夹")
                            .foregroundColor(.secondary)
                        Text("添加文件夹后，打开其中的图片时无需再次授权")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 30)
                } else {
                    List {
                        ForEach(authorizedFolders, id: \.self) { folder in
                            HStack {
                                Image(systemName: "folder.fill")
                                    .foregroundColor(.blue)
                                VStack(alignment: .leading) {
                                    Text(URL(fileURLWithPath: folder).lastPathComponent)
                                        .lineLimit(1)
                                    Text(folder)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .lineLimit(1)
                                        .truncationMode(.middle)
                                }
                                Spacer()
                                Button(action: { removeFolder(folder) }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.secondary)
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .frame(height: 200)
                    .listStyle(.bordered)
                }
                
                // 添加按钮
                HStack {
                    Button(action: addFolder) {
                        Label("添加文件夹", systemImage: "plus")
                    }
                    
                    Spacer()
                    
                    if !authorizedFolders.isEmpty {
                        Button(action: clearAll) {
                            Text("清除全部")
                                .foregroundColor(.red)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding()
            
            Spacer()
            
            Divider()
            
            // 底部按钮
            HStack {
                Spacer()
                Button("完成") {
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
            }
            .padding()
        }
        .frame(width: 450, height: 400)
        .onAppear {
            loadFolders()
        }
    }
    
    private func loadFolders() {
        authorizedFolders = BookmarkManager.shared.getSavedFolders()
    }
    
    private func addFolder() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = true
        panel.message = "选择要授权访问的文件夹"
        panel.prompt = "授权"
        
        if panel.runModal() == .OK {
            for url in panel.urls {
                if url.startAccessingSecurityScopedResource() {
                    BookmarkManager.shared.saveBookmark(for: url)
                    url.stopAccessingSecurityScopedResource()
                }
            }
            loadFolders()
        }
    }
    
    private func removeFolder(_ path: String) {
        BookmarkManager.shared.removeBookmark(for: URL(fileURLWithPath: path))
        loadFolders()
    }
    
    private func clearAll() {
        let alert = NSAlert()
        alert.messageText = "确定清除所有授权？"
        alert.informativeText = "清除后，打开这些文件夹中的图片时需要重新授权。"
        alert.alertStyle = .warning
        alert.addButton(withTitle: "清除")
        alert.addButton(withTitle: "取消")
        
        if alert.runModal() == .alertFirstButtonReturn {
            BookmarkManager.shared.clearAllBookmarks()
            loadFolders()
        }
    }
}

#Preview {
    SettingsView()
}
