//
//  ContentView.swift
//  easyView
//
//  Created by 张腾飞 on 2025/10/16.
//

import SwiftUI
import AppKit
import UniformTypeIdentifiers

// MARK: - Simple macOS Image Previewer
// Features:
// - Load a list of images (from bundle for demo)
// - Left/Right arrow click to switch images
// - Mouse wheel zoom with centred zooming
// - Click-and-drag to pan the image when zoomed
// - Smooth animations and limits on zoom
// - Basic in-memory image cache for performance

struct ContentView: View {
    // Demo image names placed in Assets.xcassets or bundled resources
    private let demoImageNames = [
        "AppIcon", // Replace with real image asset names you add
        "AccentColor"
    ]

    // MARK: - View state
    @State private var images: [NSImage] = []
    // If user opens files, we'll store their URLs here and load images on demand
    @State private var imageURLs: [URL] = []
    // Loaded images keyed by index for quick presentation
    @State private var loadedImages: [Int: NSImage] = [:]
    // Simple in-memory cache for NSImage
    private let imageCache = ImageCache.shared
    @State private var currentIndex: Int = 0
    @State private var scale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var isDragging: Bool = false
    @State private var dragStartOffset: CGSize = .zero
    @State private var leftHover: Bool = false
    @State private var rightHover: Bool = false
    @State private var openHover: Bool = false
    @State private var pinHover: Bool = false  // 置顶按钮悬停状态
    @State private var isPinned: Bool = false  // 窗口是否置顶
    @State private var magnifyState: MagnificationGesture.Value = 1.0
    @State private var viewportSize: CGSize = .zero  // 记录视口尺寸
    
    // 保持安全作用域访问权限的 URL（直到用户选择新文件或关闭应用）
    @State private var securityScopedURLs: [URL] = []

    // Zoom limits
    private let minScale: CGFloat = 0.2
    private let maxScale: CGFloat = 5.0

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color.black.opacity(0.9)
                    .ignoresSafeArea()
                    .onAppear {
                        viewportSize = geo.size
                    }
                    .onChange(of: geo.size) { newSize in
                        viewportSize = newSize
                    }

                let totalCount = imageURLs.isEmpty ? images.count : imageURLs.count

                if totalCount > 0 {
                    // If user opened files, prefer images loaded from URLs (cached or loadedImages)
                    // Otherwise fall back to bundled demo images
                    let displayImage: NSImage? = {
                        if !imageURLs.isEmpty {
                            guard imageURLs.indices.contains(currentIndex) else { return nil }
                            if let cached = imageCache.image(forKey: imageURLs[currentIndex].absoluteString as NSString) {
                                return cached
                            }
                            return loadedImages[currentIndex]
                        }
                        return images[safe: currentIndex]
                    }()

                    Group {
                        if let display = displayImage {
                            Image(nsImage: display)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .scaleEffect(scale)
                                .offset(offset)
                                .animation(.interactiveSpring(response: 0.3, dampingFraction: 0.8, blendDuration: 0.1), value: scale)
                                .animation(.interactiveSpring(response: 0.25, dampingFraction: 0.9), value: offset)
                                .frame(width: geo.size.width, height: geo.size.height)
                                .overlay(
                                    // Native wheel scroll handler - covers entire area
                                    ZoomWheelHandler(scale: $scale, offset: $offset, minScale: minScale, maxScale: maxScale)
                                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                                )
                                // SwiftUI gestures
                                .gesture(
                                    // MagnificationGesture - responds to trackpad pinch
                                    MagnificationGesture()
                                        .onChanged { value in
                                            print("MagnificationGesture.onChanged: \(value)")
                                            let prevScale = scale
                                            scale = (magnifyState * value).clamped(to: minScale...maxScale)
                                            
                                            // Simple cursor-centered zoom (using screen center)
                                            let scaleRatio = scale / prevScale
                                            offset = CGSize(
                                                width: offset.width * scaleRatio,
                                                height: offset.height * scaleRatio
                                            )
                                        }
                                        .onEnded { value in
                                            magnifyState = scale
                                        }
                                )
                                .simultaneousGesture(dragGesture())
                                .onTapGesture(count: 2) { // Double click to reset
                                    withAnimation { resetTransform() }
                                }
                        } else {
                            // Placeholder while async image loads
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                                .frame(width: geo.size.width, height: geo.size.height)
                                .overlay(ZoomWheelHandler(scale: $scale, offset: $offset, minScale: minScale, maxScale: maxScale))
                                .simultaneousGesture(dragGesture())
                        }
                    }
                    // ensure neighbor images are preloaded for smoother navigation
                    .onAppear { preloadNeighbors() }
                } else {
                    Text("No images")
                        .foregroundColor(.white)
                }

                // Floating controls: open (top-left), pin (top-right), previous (left-center), next (right-center)
                // Top controls: open button (left) and pin button (right)
                VStack {
                    HStack {
                        // Open button (top-left)
                        Button(action: openFiles) {
                            Image(systemName: "folder.fill.badge.plus")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(8)
                                .background(Color.black.opacity(0.5))
                                .clipShape(Circle())
                                .shadow(radius: 6)
                                .scaleEffect(openHover ? 1.05 : 1.0)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .onHover { openHover = $0 }

                        Spacer()
                        
                        // Pin button (top-right)
                        Button(action: togglePin) {
                            Image(systemName: isPinned ? "pin.fill" : "pin.slash")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(isPinned ? .yellow : .white)
                                .padding(8)
                                .background(Color.black.opacity(0.5))
                                .clipShape(Circle())
                                .shadow(radius: 6)
                                .scaleEffect(pinHover ? 1.05 : 1.0)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .onHover { pinHover = $0 }
                    }
                    Spacer()
                }
                .padding(20)

                // Large left/right circular buttons centered vertically
                HStack {
                    Button(action: previous) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 40, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(18)
                            .background(Color.black.opacity(0.45))
                            .clipShape(Circle())
                            .shadow(radius: 8)
                            .scaleEffect(leftHover ? 1.06 : 1.0)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .onHover { leftHover = $0 }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 30)

                    Button(action: next) {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 40, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(18)
                            .background(Color.black.opacity(0.45))
                            .clipShape(Circle())
                            .shadow(radius: 8)
                            .scaleEffect(rightHover ? 1.06 : 1.0)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .onHover { rightHover = $0 }
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.trailing, 30)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                // Index indicator
                VStack {
                    Spacer()
                    let totalCountLabel = imageURLs.isEmpty ? images.count : imageURLs.count
                    Text("\(currentIndex + 1) / \(totalCountLabel)")
                        .foregroundColor(.white)
                        .padding(8)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
                        .padding(.bottom, 20)
                        .onAppear {
                            print("Current totalCount: \(totalCountLabel)")
                        }
                }
            }
            .onAppear(perform: loadDemoImages)
            .onChange(of: currentIndex) { _ in
                // Reset transform when switching images
                withAnimation { resetTransform() }
                preloadNeighbors()
            }
            // 监听从 Finder 打开文件的通知
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("OpenFilesFromFinder"))) { notification in
                if let userInfo = notification.userInfo,
                   let urls = userInfo["urls"] as? [URL] {
                    handleOpenFiles(urls)
                }
            }
            // Keyboard left/right for quicker navigation on mac
            .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
                // No-op; ensures view can receive key events if needed
            }
            .onDisappear {
                // 视图消失时释放所有安全作用域访问权限
                releaseSecurityScopedAccess()
            }
            .focusable(true)
            .onKeyDown { event in
                // Handle arrow keys
                if event.keyCode == 123 { // left
                    previous()
                } else if event.keyCode == 124 { // right
                    next()
                }
            }
        }
    }

    // MARK: - Actions
    private func previous() {
        let totalCount = imageURLs.isEmpty ? images.count : imageURLs.count
        if totalCount == 0 { return }
        currentIndex = (currentIndex - 1 + totalCount) % totalCount
        print("previous -> currentIndex=\(currentIndex) total=\(totalCount)")
    }

    private func next() {
        let totalCount = imageURLs.isEmpty ? images.count : imageURLs.count
        if totalCount == 0 { return }
        currentIndex = (currentIndex + 1) % totalCount
        print("next -> currentIndex=\(currentIndex) total=\(totalCount)")
    }

    private func resetTransform() {
        scale = 1.0
        offset = .zero
    }
    
    // 切换窗口置顶状态
    private func togglePin() {
        isPinned.toggle()
        
        // 获取当前窗口并设置 level
        if let window = NSApplication.shared.windows.first(where: { $0.isKeyWindow }) {
            if isPinned {
                // 置顶：设置为浮动窗口级别
                window.level = .floating
                print("🔝 窗口已置顶")
            } else {
                // 取消置顶：恢复为正常窗口级别
                window.level = .normal
                print("📍 窗口已取消置顶")
            }
        }
    }
    
    // 限制偏移量，防止图片完全移出视口
    private func clampOffset(_ offset: CGSize, scale: CGFloat, imageSize: CGSize, viewportSize: CGSize) -> CGSize {
        // 如果缩放 <= 1.0（图片没有超出视口），不允许平移
        guard scale > 1.0 else {
            return .zero
        }
        
        // 计算缩放后的图片尺寸
        let scaledWidth = imageSize.width * scale
        let scaledHeight = imageSize.height * scale
        
        // 计算允许的最大偏移量（保证至少有一部分图片在视口内）
        // 允许图片边缘最多移到视口边缘，但不能完全移出
        let maxOffsetX = max(0, (scaledWidth - viewportSize.width) / 2)
        let maxOffsetY = max(0, (scaledHeight - viewportSize.height) / 2)
        
        // 限制偏移量
        let clampedX = offset.width.clamped(to: -maxOffsetX...maxOffsetX)
        let clampedY = offset.height.clamped(to: -maxOffsetY...maxOffsetY)
        
        return CGSize(width: clampedX, height: clampedY)
    }

    // MARK: - Gestures
    private func dragGesture() -> some Gesture {
        DragGesture()
            .onChanged { value in
                // Initialize start offset on first change
                if !isDragging {
                    dragStartOffset = offset
                    isDragging = true
                }
                // Update offset relative to the drag start point (prevents accumulation)
                let newOffset = CGSize(width: dragStartOffset.width + value.translation.width,
                                      height: dragStartOffset.height + value.translation.height)
                
                // 实时限制偏移（可选，如果希望拖动时就限制）
                // offset = clampOffset(newOffset, scale: scale, imageSize: currentImageSize, viewportSize: viewportSize)
                
                // 或者允许拖动超出范围，只在结束时回弹
                offset = newOffset
            }
            .onEnded { _ in
                // 拖动结束时，限制偏移量并应用弹簧动画回弹
                if let img = getCurrentImage() {
                    let imageSize = CGSize(width: img.size.width, height: img.size.height)
                    let clampedOffset = clampOffset(offset, scale: scale, imageSize: imageSize, viewportSize: viewportSize)
                    
                    // 如果偏移量被限制了，用动画回弹
                    if clampedOffset != offset {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            offset = clampedOffset
                        }
                    }
                    dragStartOffset = clampedOffset
                } else {
                    dragStartOffset = offset
                }
                
                isDragging = false
            }
    }
    
    // 获取当前显示的图片
    private func getCurrentImage() -> NSImage? {
        if !imageURLs.isEmpty {
            guard imageURLs.indices.contains(currentIndex) else { return nil }
            if let cached = imageCache.image(forKey: imageURLs[currentIndex].absoluteString as NSString) {
                return cached
            }
            return loadedImages[currentIndex]
        }
        return images[safe: currentIndex]
    }

    // MARK: - Image loading & cache
    private func loadDemoImages() {
        // Load images from asset names; filter out nils.
        images = demoImageNames.compactMap { name in
            if let ns = NSImage(named: name) {
                return ns
            } else if let path = Bundle.main.path(forResource: name, ofType: nil), let ns = NSImage(contentsOfFile: path) {
                return ns
            }
            return nil
        }
        // Ensure there's at least one placeholder if nothing found
        if images.isEmpty {
            let placeholder = NSImage(size: NSSize(width: 800, height: 600))
            images = [placeholder]
        }
    }

    // Open panel to pick image files or directory; stores URLs and starts asynchronous loading
    private func openFiles() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = true  // 允许选择文件夹
        panel.allowedContentTypes = [.image]
        panel.canChooseFiles = true
        
        panel.begin { response in
            guard response == .OK else { return }
            handleOpenFiles(panel.urls)
        }
    }
    
    // 统一处理打开文件的逻辑（无论是通过按钮还是双击打开）
    private func handleOpenFiles(_ urls: [URL]) {
        guard !urls.isEmpty else { return }
        
        // 释放之前保持的所有安全作用域访问权限
        releaseSecurityScopedAccess()
        
        print("🔍 处理 \(urls.count) 个文件/文件夹")
        
        // 处理选定的 URL（可能是文件或文件夹）
        var imageURLsToLoad: [URL] = []
        var selectedFileURL: URL?  // 记录用户第一个选择的文件
        var urlsToKeepAccess: [URL] = []  // 需要保持访问权限的 URL
        
        for url in urls {
            print("  处理: \(url.lastPathComponent) (isDirectory: \(url.hasDirectoryPath))")
            
            if url.hasDirectoryPath {
                // 如果是文件夹，启动并保持访问权限
                if url.startAccessingSecurityScopedResource() {
                    urlsToKeepAccess.append(url)
                    print("  ✅ 已保持文件夹访问权限")
                }
                
                // 获取其中的所有图片文件
                let imagesInDir = getImagesFromDirectory(url)
                print("  📁 文件夹包含 \(imagesInDir.count) 张图片")
                imageURLsToLoad.append(contentsOf: imagesInDir)
            } else {
                // 单个文件 - 先将文件本身添加到列表
                imageURLsToLoad.append(url)
                
                // 记录第一个选择的文件
                if selectedFileURL == nil {
                    selectedFileURL = url
                }
                
                // 启动并保持对选中文件的访问权限
                if url.startAccessingSecurityScopedResource() {
                    urlsToKeepAccess.append(url)
                    print("  ✅ 已保持文件访问权限: \(url.lastPathComponent)")
                }
            }
        }
        
        // 保存需要持续访问权限的 URL
        securityScopedURLs = urlsToKeepAccess
        print("🔐 保持 \(securityScopedURLs.count) 个安全作用域访问权限")
        
        print("📊 去重前: \(imageURLsToLoad.count) 张图片")
        
        // 去重并排序
        let uniqueURLs = Array(Set(imageURLsToLoad))
        imageURLsToLoad = uniqueURLs.sorted { 
            $0.lastPathComponent.localizedStandardCompare($1.lastPathComponent) == .orderedAscending 
        }
        
        print("📊 去重后: \(imageURLsToLoad.count) 张图片")
        
        // 如果没找到图片文件，直接返回
        if imageURLsToLoad.isEmpty {
            print("❌ No image files found")
            return
        }
        
        // 确定起始索引
        var selectedFileIndex = 0
        if let selectedFile = selectedFileURL,
           let index = imageURLsToLoad.firstIndex(of: selectedFile) {
            selectedFileIndex = index
            print("📍 用户选择的文件位于第 \(index + 1) 张")
        }
        
        print("✅ 成功加载 \(imageURLsToLoad.count) 张图片，起始位置: \(selectedFileIndex + 1)")
        
        // 如果只加载了一张图片，提示用户
        if imageURLsToLoad.count == 1 && urls.count == 1 && !urls[0].hasDirectoryPath {
            print("💡 提示：选择了单个文件，如需浏览整个文件夹的图片，请直接打开文件夹")
        }
        
        // 重置状态
        imageURLs = imageURLsToLoad
        loadedImages.removeAll()
        
        // 设置为用户选择的图片位置（而不是总是从第一张开始）
        currentIndex = selectedFileIndex
        loadImage(at: selectedFileIndex)
        preloadNeighbors()
    }
    
    // 从文件夹中获取所有图片文件
    private func getImagesFromDirectory(_ directory: URL) -> [URL] {
        let fileManager = FileManager.default
        let imageExtensions = ["jpg", "jpeg", "png", "gif", "heic", "webp", "tiff", "bmp", "svg"]
        
        print("  🔎 扫描目录: \(directory.path)")
        
        // 首先尝试简单的目录内容读取（只读取直接子文件，不递归）
        do {
            let contents = try fileManager.contentsOfDirectory(
                at: directory,
                includingPropertiesForKeys: [.isRegularFileKey, .isDirectoryKey],
                options: [.skipsHiddenFiles]
            )
            
            print("  📂 找到 \(contents.count) 个项目")
            
            // 筛选出图片文件
            var imageURLs: [URL] = []
            for url in contents {
                let isDirectory = (try? url.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory ?? false
                
                // 跳过目录，只处理文件
                if !isDirectory {
                    let fileExtension = url.pathExtension.lowercased()
                    if imageExtensions.contains(fileExtension) {
                        imageURLs.append(url)
                        print("    ✓ \(url.lastPathComponent)")
                    }
                }
            }
            
            print("  ✅ 找到 \(imageURLs.count) 张图片")
            
            // 按文件名排序
            return imageURLs.sorted { 
                $0.lastPathComponent.localizedStandardCompare($1.lastPathComponent) == .orderedAscending 
            }
            
        } catch {
            print("  ❌ 读取目录失败: \(error.localizedDescription)")
            return []
        }
    }

    // Load image at index asynchronously and cache it
    private func loadImage(at index: Int) {
        guard imageURLs.indices.contains(index) else { return }
        let url = imageURLs[index]
        let key = url.absoluteString as NSString
        if let cached = imageCache.image(forKey: key) {
            DispatchQueue.main.async {
                loadedImages[index] = cached
            }
            return
        }

        DispatchQueue.global(qos: .userInitiated).async {
            if let data = try? Data(contentsOf: url), let ns = NSImage(data: data) {
                imageCache.setImage(ns, forKey: key)
                DispatchQueue.main.async {
                    loadedImages[index] = ns
                }
            }
        }
    }

    // Preload left/right neighbor images for smoother navigation
    private func preloadNeighbors() {
        guard !imageURLs.isEmpty else { return }
        let left = (currentIndex - 1 + imageURLs.count) % imageURLs.count
        let right = (currentIndex + 1) % imageURLs.count
        loadImage(at: left)
        loadImage(at: right)
    }
    
    // 释放所有保持的安全作用域访问权限
    private func releaseSecurityScopedAccess() {
        for url in securityScopedURLs {
            url.stopAccessingSecurityScopedResource()
            print("🔓 释放访问权限: \(url.lastPathComponent)")
        }
        securityScopedURLs.removeAll()
    }
}

// MARK: - Utilities & Helpers

extension Array {
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

// A small view that wraps an NSView to capture mouse wheel events for zooming.
// It updates the bound scale and offset while respecting limits.
struct ZoomWheelHandler: NSViewRepresentable {
    @Binding var scale: CGFloat
    @Binding var offset: CGSize
    let minScale: CGFloat
    let maxScale: CGFloat

    func makeNSView(context: Context) -> WheelCaptureView {
        let view = WheelCaptureView()
        view.coordinator = context.coordinator
        return view
    }

    func updateNSView(_ nsView: WheelCaptureView, context: Context) {
        context.coordinator.scale = $scale
        context.coordinator.offset = $offset
        context.coordinator.minScale = minScale
        context.coordinator.maxScale = maxScale
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(scale: $scale, offset: $offset, minScale: minScale, maxScale: maxScale)
    }

    class Coordinator {
        var scale: Binding<CGFloat>
        var offset: Binding<CGSize>
        var minScale: CGFloat
        var maxScale: CGFloat
        var eventMonitor: Any?

        init(scale: Binding<CGFloat>, offset: Binding<CGSize>, minScale: CGFloat, maxScale: CGFloat) {
            self.scale = scale
            self.offset = offset
            self.minScale = minScale
            self.maxScale = maxScale
        }

        func handleScrollWheel(event: NSEvent, in view: NSView) {
            print("🎯 Scroll event captured!")
            
            // 获取滚动值
            var deltaY: CGFloat = 0
            if event.hasPreciseScrollingDeltas {
                // 触控板
                deltaY = event.deltaY * 0.5
                print("  触控板滚动: deltaY=\(event.deltaY) adjusted=\(deltaY)")
            } else {
                // 鼠标滚轮
                deltaY = event.scrollingDeltaY * 0.3
                print("  鼠标滚轮: scrollingDeltaY=\(event.scrollingDeltaY) adjusted=\(deltaY)")
            }
            
            guard abs(deltaY) > 0.01 else {
                print("  ⚠️ Delta too small, ignoring")
                return
            }
            
            // 计算缩放因子
            let sensitivity: CGFloat = 0.2
            let zoomFactor = pow(1.0 + sensitivity, deltaY)
            
            let oldScale = scale.wrappedValue
            let newScale = (oldScale * zoomFactor).clamped(to: minScale...maxScale)
            
            print("  缩放: \(oldScale) -> \(newScale) (factor: \(zoomFactor))")
            
            // 更新缩放
            DispatchQueue.main.async {
                self.scale.wrappedValue = newScale
            }
        }
    }
}

// 专门用于捕获滚轮事件的 NSView
class WheelCaptureView: NSView {
    weak var coordinator: ZoomWheelHandler.Coordinator?
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupEventMonitor()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupEventMonitor()
    }
    
    private func setupEventMonitor() {
        // 使用本地事件监听器来捕获滚轮事件
        coordinator?.eventMonitor = NSEvent.addLocalMonitorForEvents(matching: .scrollWheel) { [weak self] event in
            guard let self = self,
                  let window = self.window,
                  let coordinator = self.coordinator else {
                return event
            }
            
            // 检查事件是否在我们的视图范围内
            let locationInWindow = event.locationInWindow
            let locationInView = self.convert(locationInWindow, from: nil)
            
            if self.bounds.contains(locationInView) {
                print("📍 Scroll in bounds: \(locationInView)")
                coordinator.handleScrollWheel(event: event, in: self)
            }
            
            return event
        }
    }
    
    // 确保视图可以接收事件
    override var acceptsFirstResponder: Bool { true }
    override var canBecomeKeyView: Bool { true }
    
    override func scrollWheel(with event: NSEvent) {
        print("🔄 scrollWheel called directly!")
        coordinator?.handleScrollWheel(event: event, in: self)
        super.scrollWheel(with: event)
    }
    
    deinit {
        if let monitor = coordinator?.eventMonitor {
            NSEvent.removeMonitor(monitor)
        }
    }
}



// Clamp helper
extension Comparable {
    func clamped(to limits: ClosedRange<Self>) -> Self {
        return min(max(self, limits.lowerBound), limits.upperBound)
    }
}

// MARK: - Key event handling for SwiftUI on macOS
// Lightweight NSViewRepresentable to capture keyDown events and forward them.
struct KeyDownHandler: NSViewRepresentable {
    var onKeyDown: (NSEvent) -> Void

    func makeNSView(context: Context) -> KeyView { KeyView(onKeyDown: onKeyDown) }
    func updateNSView(_ nsView: KeyView, context: Context) {}

    class KeyView: NSView {
        var onKeyDown: (NSEvent) -> Void
        init(onKeyDown: @escaping (NSEvent) -> Void) {
            self.onKeyDown = onKeyDown
            super.init(frame: .zero)
            self.wantsLayer = true
            self.layer?.backgroundColor = NSColor.clear.cgColor
        }
        required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
        override var acceptsFirstResponder: Bool { true }
        override func keyDown(with event: NSEvent) { onKeyDown(event) }
    }
}

// View modifier to attach keyDown handler conveniently
extension View {
    func onKeyDown(perform action: @escaping (NSEvent) -> Void) -> some View {
        background(KeyDownHandler(onKeyDown: action))
    }
}

// Preview
#Preview {
    ContentView()
}
