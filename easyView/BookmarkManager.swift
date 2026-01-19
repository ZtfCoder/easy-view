//
//  BookmarkManager.swift
//  easyView
//
//  持久化保存文件夹访问权限
//

import Foundation
import AppKit

class BookmarkManager {
    static let shared = BookmarkManager()
    
    private let bookmarksKey = "SavedFolderBookmarks"
    private var activeSecurityScopedURLs: [URL] = []
    
    private init() {}
    
    // MARK: - 保存书签
    
    /// 保存文件夹的访问权限书签
    func saveBookmark(for url: URL) {
        do {
            let bookmarkData = try url.bookmarkData(
                options: .withSecurityScope,
                includingResourceValuesForKeys: nil,
                relativeTo: nil
            )
            
            var bookmarks = getStoredBookmarks()
            bookmarks[url.path] = bookmarkData
            
            UserDefaults.standard.set(bookmarks, forKey: bookmarksKey)
            print("✅ 已保存书签: \(url.path)")
        } catch {
            print("❌ 保存书签失败: \(error.localizedDescription)")
        }
    }
    
    /// 移除文件夹的书签
    func removeBookmark(for url: URL) {
        var bookmarks = getStoredBookmarks()
        bookmarks.removeValue(forKey: url.path)
        UserDefaults.standard.set(bookmarks, forKey: bookmarksKey)
        print("🗑️ 已移除书签: \(url.path)")
    }
    
    // MARK: - 恢复访问权限
    
    /// 尝试恢复对某个路径的访问权限
    func restoreAccess(for path: String) -> URL? {
        let bookmarks = getStoredBookmarks()
        
        guard let bookmarkData = bookmarks[path] else {
            return nil
        }
        
        do {
            var isStale = false
            let url = try URL(
                resolvingBookmarkData: bookmarkData,
                options: .withSecurityScope,
                relativeTo: nil,
                bookmarkDataIsStale: &isStale
            )
            
            if isStale {
                // 书签过期，尝试重新保存
                print("⚠️ 书签已过期，尝试更新: \(path)")
                saveBookmark(for: url)
            }
            
            if url.startAccessingSecurityScopedResource() {
                activeSecurityScopedURLs.append(url)
                print("✅ 已恢复访问权限: \(url.path)")
                return url
            }
        } catch {
            print("❌ 恢复书签失败: \(error.localizedDescription)")
            // 移除无效书签
            removeBookmark(for: URL(fileURLWithPath: path))
        }
        
        return nil
    }
    
    /// 尝试恢复对某个目录或其父目录的访问权限
    func restoreAccessForDirectory(_ directory: URL) -> Bool {
        // 先尝试直接恢复该目录
        if restoreAccess(for: directory.path) != nil {
            return true
        }
        
        // 尝试恢复父目录
        var currentPath = directory
        while currentPath.path != "/" {
            currentPath = currentPath.deletingLastPathComponent()
            if restoreAccess(for: currentPath.path) != nil {
                return true
            }
        }
        
        return false
    }
    
    // MARK: - 获取已保存的文件夹
    
    /// 获取所有已保存书签的文件夹路径
    func getSavedFolders() -> [String] {
        return Array(getStoredBookmarks().keys).sorted()
    }
    
    /// 检查某个路径是否已保存
    func hasBookmark(for path: String) -> Bool {
        return getStoredBookmarks()[path] != nil
    }
    
    // MARK: - 清理
    
    /// 释放所有活跃的安全作用域访问
    func releaseAllAccess() {
        for url in activeSecurityScopedURLs {
            url.stopAccessingSecurityScopedResource()
        }
        activeSecurityScopedURLs.removeAll()
    }
    
    /// 清除所有保存的书签
    func clearAllBookmarks() {
        UserDefaults.standard.removeObject(forKey: bookmarksKey)
        print("🗑️ 已清除所有书签")
    }
    
    // MARK: - Private
    
    private func getStoredBookmarks() -> [String: Data] {
        return UserDefaults.standard.dictionary(forKey: bookmarksKey) as? [String: Data] ?? [:]
    }
}
