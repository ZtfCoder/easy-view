//
//  ContentView.swift
//  easyView
//
//  Created by 张腾飞 on 2025/10/16.
//

import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct ContentView: View {
    // MARK: - State
    @State private var imageURLs: [URL] = []
    @State private var loadedImages: [Int: NSImage] = [:]
    @State private var currentIndex: Int = 0
    @State private var scale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var isDragging: Bool = false
    @State private var dragStartOffset: CGSize = .zero
    @State private var magnifyState: CGFloat = 1.0
    @State private var viewportSize: CGSize = .zero
    @State private var securityScopedURLs: [URL] = []
    
    // 沉浸式 UI 状态
    @State private var showControls: Bool = true
    @State private var isHovering: Bool = false
    @State private var isPinned: Bool = false
    @State private var hideControlsTask: DispatchWorkItem?
    
    private let imageCache = ImageCache.shared
    private let minScale: CGFloat = 0.2
    private let maxScale: CGFloat = 10.0

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // 透明背景
                Color.clear
                    .onAppear { viewportSize = geo.size }
                    .onChange(of: geo.size) { viewportSize = $0 }
                
                // 图片显示
                imageView(in: geo)
                
                // 沉浸式控件层
                controlsOverlay
            }
            .background(imageBackground)
            .onAppear(perform: setupView)
            .onChange(of: currentIndex) { _ in
                withAnimation(.easeOut(duration: 0.2)) { resetTransform() }
                preloadNeighbors()
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("OpenFilesFromFinder"))) { notification in
                if let urls = notification.userInfo?["urls"] as? [URL] {
                    handleOpenFiles(urls)
                }
            }
            .onDisappear {
                // 延迟释放，避免在窗口关闭过程中出问题
                let urlsToRelease = securityScopedURLs
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    urlsToRelease.forEach { $0.stopAccessingSecurityScopedResource() }
                }
            }
            .focusable(true)
            .onKeyDown { handleKeyDown($0) }
            .onHover { hovering in
                isHovering = hovering
                if hovering {
                    showControlsTemporarily()
                }
            }
        }
    }
    
    // 图片作为背景（模糊效果）
    @ViewBuilder
    private var imageBackground: some View {
        if let image = currentImage {
            Image(nsImage: image)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .blur(radius: 30)
                .saturation(0.8)
                .overlay(Color.black.opacity(0.3))
        } else {
            Color.black
        }
    }
    
    // MARK: - Image View
    @ViewBuilder
    private func imageView(in geo: GeometryProxy) -> some View {
        let totalCount = imageURLs.count
        
        if totalCount > 0, let image = currentImage {
            Image(nsImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .scaleEffect(scale)
                .offset(offset)
                .animation(.interactiveSpring(response: 0.25, dampingFraction: 0.85), value: scale)
                .animation(.interactiveSpring(response: 0.2, dampingFraction: 0.9), value: offset)
                .frame(width: geo.size.width, height: geo.size.height)
                .contentShape(Rectangle())
                .overlay(
                    ZoomWheelHandler(scale: $scale, offset: $offset, minScale: minScale, maxScale: maxScale)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                )
                .gesture(magnificationGesture)
                .simultaneousGesture(dragGesture)
                .onTapGesture(count: 2) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        resetTransform()
                    }
                }
                .onTapGesture(count: 1) {
                    showControlsTemporarily()
                }
        } else if totalCount == 0 {
            // 空状态
            VStack(spacing: 20) {
                Image(systemName: "photo.on.rectangle.angled")
                    .font(.system(size: 64, weight: .thin))
                    .foregroundColor(.gray.opacity(0.5))
                Text("拖放图片到此处")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.gray.opacity(0.6))
            }
        } else {
            ProgressView()
                .scaleEffect(1.5)
                .progressViewStyle(CircularProgressViewStyle(tint: .white.opacity(0.6)))
        }
    }
    
    // MARK: - Controls Overlay
    private var controlsOverlay: some View {
        VStack {
            // 顶部工具栏
            topBar
                .opacity(showControls ? 1 : 0)
                .offset(y: showControls ? 0 : -20)
            
            Spacer()
            
            // 底部信息栏
            bottomBar
                .opacity(showControls ? 1 : 0)
                .offset(y: showControls ? 0 : 20)
        }
        .animation(.easeInOut(duration: 0.25), value: showControls)
    }
    
    // MARK: - Top Bar
    private var topBar: some View {
        HStack(spacing: 12) {
            // 打开文件按钮
            controlButton(icon: "folder", action: openFiles)
            
            // 左右切换按钮
            if imageURLs.count > 1 {
                controlButton(icon: "chevron.left", action: previous)
                controlButton(icon: "chevron.right", action: next)
            }
            
            Spacer()
            
            // 文件名
            if let url = currentImageURL {
                Text(url.lastPathComponent)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .shadow(color: .black.opacity(0.8), radius: 4, x: 0, y: 1)
            }
            
            Spacer()
            
            // 图片计数
            if imageURLs.count > 1 {
                Text("\(currentIndex + 1)/\(imageURLs.count)")
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundColor(.white.opacity(0.8))
                    .shadow(color: .black.opacity(0.8), radius: 4, x: 0, y: 1)
            }
            
            // 置顶按钮
            controlButton(
                icon: isPinned ? "pin.fill" : "pin",
                isActive: isPinned,
                action: togglePin
            )
        }
        .padding(.horizontal, 16)
        .padding(.top, 40)  // 留出标题栏按钮空间
        .padding(.bottom, 12)
    }
    
    // MARK: - Bottom Bar
    private var bottomBar: some View {
        HStack(spacing: 16) {
            // 缩放比例
            if scale != 1.0 {
                Text("\(Int(scale * 100))%")
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundColor(.white.opacity(0.7))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(.ultraThinMaterial, in: Capsule())
                    .shadow(color: .black.opacity(0.5), radius: 8, x: 0, y: 2)
            }
        }
        .padding(.bottom, 20)
    }
    
    // MARK: - UI Components
    private func controlButton(icon: String, isActive: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(isActive ? .yellow : .white)
                .frame(width: 32, height: 32)
                .background(.ultraThinMaterial, in: Circle())
                .shadow(color: .black.opacity(0.5), radius: 8, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Gestures
    private var magnificationGesture: some Gesture {
        MagnificationGesture()
            .onChanged { value in
                let prevScale = scale
                scale = (magnifyState * value).clamped(to: minScale...maxScale)
                let ratio = scale / prevScale
                offset = CGSize(width: offset.width * ratio, height: offset.height * ratio)
            }
            .onEnded { _ in magnifyState = scale }
    }
    
    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                if !isDragging {
                    dragStartOffset = offset
                    isDragging = true
                }
                offset = CGSize(
                    width: dragStartOffset.width + value.translation.width,
                    height: dragStartOffset.height + value.translation.height
                )
            }
            .onEnded { _ in
                if let img = currentImage {
                    let clamped = clampOffset(offset, scale: scale, imageSize: img.size, viewportSize: viewportSize)
                    if clamped != offset {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            offset = clamped
                        }
                    }
                    dragStartOffset = clamped
                }
                isDragging = false
            }
    }
    
    // MARK: - Actions
    private func previous() {
        guard imageURLs.count > 0 else { return }
        currentIndex = (currentIndex - 1 + imageURLs.count) % imageURLs.count
        showControlsTemporarily()
    }
    
    private func next() {
        guard imageURLs.count > 0 else { return }
        currentIndex = (currentIndex + 1) % imageURLs.count
        showControlsTemporarily()
    }
    
    private func resetTransform() {
        scale = 1.0
        offset = .zero
        magnifyState = 1.0
    }
    
    private func togglePin() {
        isPinned.toggle()
        if let window = NSApplication.shared.windows.first(where: { $0.isKeyWindow }) {
            window.level = isPinned ? .floating : .normal
        }
    }
    
    private func showControlsTemporarily() {
        hideControlsTask?.cancel()
        withAnimation { showControls = true }
        
        let task = DispatchWorkItem { [self] in
            if !isHovering {
                withAnimation { showControls = false }
            }
        }
        hideControlsTask = task
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5, execute: task)
    }
    
    private func handleKeyDown(_ event: NSEvent) {
        switch event.keyCode {
        case 123: previous()  // 左
        case 124: next()      // 右
        case 53:              // ESC - 只关闭窗口，不退出应用
            if let window = NSApplication.shared.keyWindow {
                window.performClose(nil)  // 使用 performClose 而不是 close，这样会触发 windowShouldClose
            }
        default: break
        }
    }
    
    // MARK: - Helpers
    private var currentImage: NSImage? {
        guard imageURLs.indices.contains(currentIndex) else { return nil }
        let key = imageURLs[currentIndex].absoluteString as NSString
        return imageCache.image(forKey: key) ?? loadedImages[currentIndex]
    }
    
    private var currentImageURL: URL? {
        imageURLs.indices.contains(currentIndex) ? imageURLs[currentIndex] : nil
    }
    
    private func clampOffset(_ offset: CGSize, scale: CGFloat, imageSize: CGSize, viewportSize: CGSize) -> CGSize {
        guard scale > 1.0 else { return .zero }
        let maxX = max(0, (imageSize.width * scale - viewportSize.width) / 2)
        let maxY = max(0, (imageSize.height * scale - viewportSize.height) / 2)
        return CGSize(
            width: offset.width.clamped(to: -maxX...maxX),
            height: offset.height.clamped(to: -maxY...maxY)
        )
    }
    
    private func setupView() {
        showControlsTemporarily()
    }
    
    // MARK: - File Handling
    private func openFiles() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = true
        panel.canChooseFiles = true
        panel.allowedContentTypes = [.image]
        panel.begin { response in
            if response == .OK { handleOpenFiles(panel.urls) }
        }
    }
    
    private func handleOpenFiles(_ urls: [URL]) {
        guard !urls.isEmpty else { return }
        releaseSecurityScopedAccess()
        
        var imagesToLoad: [URL] = []
        var selectedFile: URL?
        var accessURLs: [URL] = []
        
        for url in urls {
            if url.hasDirectoryPath {
                if url.startAccessingSecurityScopedResource() { accessURLs.append(url) }
                imagesToLoad.append(contentsOf: getImagesFromDirectory(url))
            } else {
                if selectedFile == nil { selectedFile = url }
                if url.startAccessingSecurityScopedResource() { accessURLs.append(url) }
                
                let parent = url.deletingLastPathComponent()
                var hasParentAccess = parent.startAccessingSecurityScopedResource()
                
                // 尝试从已保存的书签恢复权限
                if !hasParentAccess {
                    hasParentAccess = BookmarkManager.shared.restoreAccessForDirectory(parent)
                }
                
                if hasParentAccess { accessURLs.append(parent) }
                
                let siblings = getImagesFromDirectory(parent)
                if siblings.count > 1 {
                    imagesToLoad.append(contentsOf: siblings)
                } else if siblings.count == 1 {
                    imagesToLoad.append(contentsOf: siblings)
                } else {
                    // 无法读取父目录，只添加当前文件，并请求权限
                    imagesToLoad.append(url)
                    
                    // 延迟请求用户授权
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        self.requestFolderAccess(for: parent, selectedFile: url)
                    }
                }
            }
        }
        
        securityScopedURLs = accessURLs
        
        let unique = Array(Set(imagesToLoad)).sorted {
            $0.lastPathComponent.localizedStandardCompare($1.lastPathComponent) == .orderedAscending
        }
        
        guard !unique.isEmpty else { return }
        
        imageURLs = unique
        loadedImages.removeAll()
        currentIndex = selectedFile.flatMap { unique.firstIndex(of: $0) } ?? 0
        loadImage(at: currentIndex)
        preloadNeighbors()
    }
    
    // 请求用户授权访问文件夹
    private func requestFolderAccess(for directory: URL, selectedFile: URL) {
        // 先尝试从已保存的书签恢复权限
        if BookmarkManager.shared.restoreAccessForDirectory(directory) {
            // 成功恢复权限，重新加载图片
            let imagesInDir = getImagesFromDirectory(directory)
            if imagesInDir.count > 1 {
                let selectedIndex = imagesInDir.firstIndex(of: selectedFile) ?? 0
                imageURLs = imagesInDir
                loadedImages.removeAll()
                currentIndex = selectedIndex
                loadImage(at: selectedIndex)
                preloadNeighbors()
                return
            }
        }
        
        let alert = NSAlert()
        alert.messageText = "需要访问文件夹"
        alert.informativeText = "要浏览「\(directory.lastPathComponent)」文件夹中的所有图片，需要您授权访问该文件夹。\n\n授权后将自动记住，下次无需再次授权。"
        alert.alertStyle = .informational
        alert.addButton(withTitle: "选择文件夹")
        alert.addButton(withTitle: "仅查看当前图片")
        
        let response = alert.runModal()
        
        if response == .alertFirstButtonReturn {
            let panel = NSOpenPanel()
            panel.canChooseDirectories = true
            panel.canChooseFiles = false
            panel.allowsMultipleSelection = false
            panel.directoryURL = directory
            panel.message = "请选择要浏览的文件夹"
            panel.prompt = "选择"
            
            panel.begin { result in
                guard result == .OK, let url = panel.url else { return }
                
                if url.startAccessingSecurityScopedResource() {
                    self.securityScopedURLs.append(url)
                    // 保存书签以便下次自动访问
                    BookmarkManager.shared.saveBookmark(for: url)
                }
                
                let imagesInDir = self.getImagesFromDirectory(url)
                
                if !imagesInDir.isEmpty {
                    let selectedIndex = imagesInDir.firstIndex(of: selectedFile) ?? 0
                    
                    self.imageURLs = imagesInDir
                    self.loadedImages.removeAll()
                    self.currentIndex = selectedIndex
                    self.loadImage(at: selectedIndex)
                    self.preloadNeighbors()
                }
            }
        }
    }
    
    private func getImagesFromDirectory(_ directory: URL) -> [URL] {
        let extensions = ["jpg", "jpeg", "png", "gif", "heic", "webp", "tiff", "bmp"]
        guard let contents = try? FileManager.default.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        ) else { return [] }
        
        return contents.filter { url in
            let isDir = (try? url.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory ?? false
            return !isDir && extensions.contains(url.pathExtension.lowercased())
        }
    }
    
    private func loadImage(at index: Int) {
        guard imageURLs.indices.contains(index) else { return }
        let url = imageURLs[index]
        let key = url.absoluteString as NSString
        
        if let cached = imageCache.image(forKey: key) {
            loadedImages[index] = cached
            cleanupLoadedImages(around: index)
            // 通知窗口调整大小
            if index == currentIndex {
                notifyImageChanged(cached)
            }
            return
        }
        
        DispatchQueue.global(qos: .userInitiated).async {
            guard let data = try? Data(contentsOf: url), let image = NSImage(data: data) else { return }
            imageCache.setImage(image, forKey: key)
            DispatchQueue.main.async {
                loadedImages[index] = image
                cleanupLoadedImages(around: index)
                // 通知窗口调整大小
                if index == currentIndex {
                    notifyImageChanged(image)
                }
            }
        }
    }
    
    private func notifyImageChanged(_ image: NSImage) {
        NotificationCenter.default.post(
            name: NSNotification.Name("ImageChanged"),
            object: nil,
            userInfo: ["imageSize": image.size]
        )
    }
    
    private func cleanupLoadedImages(around index: Int) {
        let keep: Set<Int> = [
            (index - 1 + imageURLs.count) % imageURLs.count,
            index,
            (index + 1) % imageURLs.count
        ]
        loadedImages = loadedImages.filter { keep.contains($0.key) }
    }
    
    private func preloadNeighbors() {
        guard !imageURLs.isEmpty else { return }
        loadImage(at: (currentIndex - 1 + imageURLs.count) % imageURLs.count)
        loadImage(at: (currentIndex + 1) % imageURLs.count)
    }
    
    private func releaseSecurityScopedAccess() {
        securityScopedURLs.forEach { $0.stopAccessingSecurityScopedResource() }
        securityScopedURLs.removeAll()
    }
}

// MARK: - Helper Extensions
extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}

// MARK: - Zoom Wheel Handler
struct ZoomWheelHandler: NSViewRepresentable {
    @Binding var scale: CGFloat
    @Binding var offset: CGSize
    let minScale: CGFloat
    let maxScale: CGFloat

    func makeNSView(context: Context) -> WheelView {
        let view = WheelView()
        view.coordinator = context.coordinator
        return view
    }

    func updateNSView(_ nsView: WheelView, context: Context) {
        context.coordinator.update(scale: $scale, offset: $offset, min: minScale, max: maxScale)
        nsView.coordinator = context.coordinator
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(scale: $scale, offset: $offset, min: minScale, max: maxScale)
    }

    class Coordinator {
        var scale: Binding<CGFloat>
        var offset: Binding<CGSize>
        var minScale: CGFloat
        var maxScale: CGFloat

        init(scale: Binding<CGFloat>, offset: Binding<CGSize>, min: CGFloat, max: CGFloat) {
            self.scale = scale
            self.offset = offset
            self.minScale = min
            self.maxScale = max
        }
        
        func update(scale: Binding<CGFloat>, offset: Binding<CGSize>, min: CGFloat, max: CGFloat) {
            self.scale = scale
            self.offset = offset
            self.minScale = min
            self.maxScale = max
        }

        func handleScroll(_ event: NSEvent) {
            // 检查是否按住 Command 键
            guard event.modifierFlags.contains(.command) else { return }
            
            var delta: CGFloat = 0
            
            if event.hasPreciseScrollingDeltas {
                // 触控板
                delta = event.scrollingDeltaY * 0.01
            } else {
                // 鼠标滚轮
                delta = event.scrollingDeltaY * 0.05
            }
            
            guard abs(delta) > 0.001 else { return }
            
            let factor = 1.0 + delta
            let newScale = (scale.wrappedValue * factor).clamped(to: minScale...maxScale)
            
            DispatchQueue.main.async {
                self.scale.wrappedValue = newScale
            }
        }
    }
}

class WheelView: NSView {
    weak var coordinator: ZoomWheelHandler.Coordinator?
    
    override var acceptsFirstResponder: Bool { true }
    
    override func scrollWheel(with event: NSEvent) {
        coordinator?.handleScroll(event)
        super.scrollWheel(with: event)
    }
}

// MARK: - Key Handler
struct KeyDownHandler: NSViewRepresentable {
    var onKeyDown: (NSEvent) -> Void
    
    func makeNSView(context: Context) -> KeyView { KeyView(onKeyDown: onKeyDown) }
    func updateNSView(_ nsView: KeyView, context: Context) {}
    
    class KeyView: NSView {
        var onKeyDown: (NSEvent) -> Void
        init(onKeyDown: @escaping (NSEvent) -> Void) {
            self.onKeyDown = onKeyDown
            super.init(frame: .zero)
        }
        required init?(coder: NSCoder) { fatalError() }
        override var acceptsFirstResponder: Bool { true }
        override func keyDown(with event: NSEvent) { onKeyDown(event) }
    }
}

extension View {
    func onKeyDown(perform action: @escaping (NSEvent) -> Void) -> some View {
        background(KeyDownHandler(onKeyDown: action))
    }
}

#Preview {
    ContentView()
}
