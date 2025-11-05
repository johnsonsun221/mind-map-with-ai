import SwiftUI

/// 思维导图画布视图
struct MindMapCanvas: View {
    @StateObject private var cloudKitManager = CloudKitManager()
    @State private var nodes: [MindMapNode] = []
    @State private var selectedNode: MindMapNode?
    @State private var isShowingEditSheet = false
    @State private var scale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero

    var body: some View {
        ZStack {
            // 背景
            Color(UIColor.systemGroupedBackground)
                .ignoresSafeArea()

            // 网格背景
            GridPattern()
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                .scaleEffect(scale)
                .offset(offset)

            // 思维导图节点
            ForEach(nodes) { node in
                MindMapCard(
                    node: node,
                    onDrag: {
                        selectedNode = node
                    },
                    onTap: {
                        selectedNode = node
                        isShowingEditSheet = true
                    },
                    onDelete: {
                        deleteNode(node)
                    }
                )
                .position(
                    x: node.position.x * scale + offset.width,
                    y: node.position.y * scale + offset.height
                )
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            updateNodePosition(node, translation: value.translation)
                        }
                )
            }

            // 连接线
            ForEach(nodes) { node in
                if let parentId = node.parentId,
                   let parentNode = nodes.first(where: { $0.id == parentId }) {
                    ConnectionLine(
                        from: CGPoint(
                            x: parentNode.position.x * scale + offset.width,
                            y: parentNode.position.y * scale + offset.height
                        ),
                        to: CGPoint(
                            x: node.position.x * scale + offset.width,
                            y: node.position.y * scale + offset.height
                        )
                    )
                    .stroke(Color.gray.opacity(0.5), lineWidth: 2)
                }
            }
        }
        .gesture(
            MagnificationGesture()
                .onChanged { value in
                    scale = value.magnitude
                }
        )
        .simultaneousGesture(
            DragGesture()
                .onChanged { value in
                    offset = CGSize(
                        width: lastOffset.width + value.translation.width,
                        height: lastOffset.height + value.translation.height
                    )
                }
                .onEnded { _ in
                    lastOffset = offset
                }
        )
        .overlay(alignment: .topTrailing) {
            ToolBar(
                onAddNode: addNode,
                onZoomIn: zoomIn,
                onZoomOut: zoomOut,
                onSync: syncWithCloud
            )
            .padding()
        }
        .sheet(isPresented: $isShowingEditSheet) {
            if let node = selectedNode {
                EditNodeSheet(node: node) { updatedNode in
                    updateNode(updatedNode)
                }
            }
        }
        .task {
            await loadNodes()
        }
    }

    // MARK: - 节点操作
    private func addNode() {
        let newNode = MindMapNode(
            title: "新节点",
            content: "",
            position: CGPoint(x: 200, y: 200)
        )
        nodes.append(newNode)
        Task {
            try? await cloudKitManager.saveNode(newNode)
        }
    }

    private func updateNodePosition(_ node: MindMapNode, translation: CGSize) {
        if let index = nodes.firstIndex(where: { $0.id == node.id }) {
            nodes[index].position = CGPoint(
                x: node.position.x + translation.width / scale,
                y: node.position.y + translation.height / scale
            )
        }
    }

    private func updateNode(_ node: MindMapNode) {
        if let index = nodes.firstIndex(where: { $0.id == node.id }) {
            nodes[index] = node
            Task {
                try? await cloudKitManager.saveNode(node)
            }
        }
    }

    private func deleteNode(_ node: MindMapNode) {
        nodes.removeAll { $0.id == node.id }
        Task {
            try? await cloudKitManager.deleteNode(node.id)
        }
    }

    // MARK: - 缩放操作
    private func zoomIn() {
        withAnimation(.spring(response: 0.3)) {
            scale = min(scale * 1.2, 3.0)
        }
    }

    private func zoomOut() {
        withAnimation(.spring(response: 0.3)) {
            scale = max(scale / 1.2, 0.5)
        }
    }

    // MARK: - 云同步
    private func syncWithCloud() {
        Task {
            do {
                let cloudNodes = try await cloudKitManager.fetchAllNodes()
                await MainActor.run {
                    nodes = cloudNodes
                }
            } catch {
                print("Sync error: \(error)")
            }
        }
    }

    private func loadNodes() async {
        // 先加载本地缓存
        let cachedNodes = cloudKitManager.loadNodesLocally()
        if !cachedNodes.isEmpty {
            await MainActor.run {
                nodes = cachedNodes
            }
        }

        // 然后从云端同步
        do {
            let cloudNodes = try await cloudKitManager.fetchAllNodes()
            await MainActor.run {
                nodes = cloudNodes
                cloudKitManager.saveNodesLocally(cloudNodes)
            }
        } catch {
            print("Load error: \(error)")
        }
    }
}

// MARK: - 网格图案
struct GridPattern: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let spacing: CGFloat = 30

        for x in stride(from: 0, to: rect.width, by: spacing) {
            path.move(to: CGPoint(x: x, y: 0))
            path.addLine(to: CGPoint(x: x, y: rect.height))
        }

        for y in stride(from: 0, to: rect.height, by: spacing) {
            path.move(to: CGPoint(x: 0, y: y))
            path.addLine(to: CGPoint(x: rect.width, y: y))
        }

        return path
    }
}

// MARK: - 连接线
struct ConnectionLine: Shape {
    let from: CGPoint
    let to: CGPoint

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: from)

        // 贝塞尔曲线
        let controlPoint1 = CGPoint(x: from.x, y: (from.y + to.y) / 2)
        let controlPoint2 = CGPoint(x: to.x, y: (from.y + to.y) / 2)

        path.addCurve(to: to, control1: controlPoint1, control2: controlPoint2)

        return path
    }
}

// MARK: - 工具栏
struct ToolBar: View {
    let onAddNode: () -> Void
    let onZoomIn: () -> Void
    let onZoomOut: () -> Void
    let onSync: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            Button(action: onAddNode) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 30))
                    .foregroundColor(.blue)
            }

            Button(action: onZoomIn) {
                Image(systemName: "plus.magnifyingglass")
                    .font(.system(size: 26))
                    .foregroundColor(.blue)
            }

            Button(action: onZoomOut) {
                Image(systemName: "minus.magnifyingglass")
                    .font(.system(size: 26))
                    .foregroundColor(.blue)
            }

            Button(action: onSync) {
                Image(systemName: "arrow.clockwise.icloud.fill")
                    .font(.system(size: 26))
                    .foregroundColor(.blue)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .shadow(radius: 5)
        )
    }
}

// MARK: - 编辑节点表单
struct EditNodeSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var node: MindMapNode
    let onSave: (MindMapNode) -> Void

    init(node: MindMapNode, onSave: @escaping (MindMapNode) -> Void) {
        _node = State(initialValue: node)
        self.onSave = onSave
    }

    var body: some View {
        NavigationView {
            Form {
                Section("标题") {
                    TextField("输入标题", text: $node.title)
                }

                Section("内容") {
                    TextEditor(text: $node.content)
                        .frame(height: 100)
                }

                Section("颜色") {
                    Picker("选择颜色", selection: $node.color) {
                        Text("蓝色").tag("blue")
                        Text("绿色").tag("green")
                        Text("橙色").tag("orange")
                        Text("紫色").tag("purple")
                        Text("粉色").tag("pink")
                        Text("红色").tag("red")
                        Text("黄色").tag("yellow")
                    }
                }
            }
            .navigationTitle("编辑节点")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        onSave(node)
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    MindMapCanvas()
}
