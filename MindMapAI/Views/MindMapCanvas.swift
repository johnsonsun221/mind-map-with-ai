import SwiftUI

/// 思维导图画布视图
struct MindMapCanvas: View {
    @ObservedObject var viewModel: MindMapViewModel
    @StateObject private var cloudKitManager = CloudKitManager()
    @State private var selectedNode: MindMapNode?
    @State private var isShowingEditSheet = false
    @State private var scale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero

    // 拖动状态管理
    @State private var draggingNodeId: UUID?
    @State private var dragStartPosition: CGPoint = .zero

    // 连接管理
    @State private var selectedConnection: UUID?
    @State private var showConnectionAlert = false

    var body: some View {
        ZStack {
            // 背景
            Color(UIColor.systemGroupedBackground)
                .ignoresSafeArea()

            // 无限网格背景
            GeometryReader { geometry in
                InfiniteGridPattern(offset: offset, scale: scale, viewSize: geometry.size)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
            }

            // 思维导图节点
            ForEach(viewModel.nodes) { node in
                MindMapCard(
                    node: node,
                    onDrag: {
                        // 仅用于标识拖动开始
                    },
                    onTap: {
                        if viewModel.isConnectionMode {
                            // 连接模式：完成连接
                            viewModel.completeConnection(to: node.id)
                        } else {
                            // 普通模式：编辑节点
                            selectedNode = node
                            isShowingEditSheet = true
                        }
                    },
                    onDelete: {
                        deleteNode(node)
                    },
                    onStartConnection: {
                        // 长按开始连接
                        viewModel.startConnection(from: node.id)
                    },
                    onAddChild: {
                        // 添加子节点
                        addChildNode(for: node.id)
                    }
                )
                .overlay(
                    // 连接模式下高亮起始节点
                    viewModel.connectionStartNode == node.id ?
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.blue, lineWidth: 3)
                        .padding(-4)
                    : nil
                )
                .position(
                    x: node.position.x * scale + offset.width,
                    y: node.position.y * scale + offset.height
                )
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            // 第一次拖动时保存起始位置
                            if draggingNodeId != node.id {
                                draggingNodeId = node.id
                                dragStartPosition = node.position
                            }

                            // 使用起始位置 + translation 来计算新位置
                            let newPosition = CGPoint(
                                x: dragStartPosition.x + value.translation.width / scale,
                                y: dragStartPosition.y + value.translation.height / scale
                            )
                            updateNodePositionDirect(node.id, newPosition: newPosition)
                        }
                        .onEnded { _ in
                            // 拖动结束，清除状态
                            draggingNodeId = nil

                            // 保存到云端
                            if let updatedNode = viewModel.nodes.first(where: { $0.id == node.id }) {
                                Task {
                                    try? await cloudKitManager.saveNode(updatedNode)
                                }
                            }
                        }
                )
            }

            // 连接线 - 显示所有连接
            ForEach(viewModel.connections) { connection in
                if let fromNode = viewModel.nodes.first(where: { $0.id == connection.fromNodeId }),
                   let toNode = viewModel.nodes.first(where: { $0.id == connection.toNodeId }) {
                    ConnectionLine(
                        from: CGPoint(
                            x: fromNode.position.x * scale + offset.width,
                            y: fromNode.position.y * scale + offset.height
                        ),
                        to: CGPoint(
                            x: toNode.position.x * scale + offset.width,
                            y: toNode.position.y * scale + offset.height
                        )
                    )
                    .stroke(
                        connectionColor(for: connection.connectionType),
                        style: StrokeStyle(
                            lineWidth: 2,
                            dash: connection.connectionType == .related ? [5, 5] : []
                        )
                    )
                    .contentShape(Rectangle())
                    .onTapGesture {
                        // 点击连接线可以删除
                        selectedConnection = connection.id
                    }
                }
            }

            // 连接模式指示线
            if viewModel.isConnectionMode,
               let startNodeId = viewModel.connectionStartNode,
               let startNode = viewModel.nodes.first(where: { $0.id == startNodeId }) {
                Path { path in
                    let startPoint = CGPoint(
                        x: startNode.position.x * scale + offset.width,
                        y: startNode.position.y * scale + offset.height
                    )
                    path.move(to: startPoint)
                    path.addLine(to: startPoint) // 这条线在用户移动时会更新
                }
                .stroke(Color.blue.opacity(0.5), style: StrokeStyle(lineWidth: 2, dash: [5, 3]))
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
                onSync: syncWithCloud,
                onToggleConnection: toggleConnectionMode,
                isConnectionMode: viewModel.isConnectionMode
            )
            .padding()
        }
        .sheet(isPresented: $isShowingEditSheet) {
            if let node = selectedNode {
                EditNodeSheet(
                    node: node,
                    availableNodes: viewModel.nodes.filter { $0.id != node.id },
                    onSave: { updatedNode in
                        updateNode(updatedNode)
                    },
                    onParentChange: { newParentId in
                        viewModel.setParent(childId: node.id, parentId: newParentId)
                    }
                )
            }
        }
        .alert("删除连接？", isPresented: Binding(
            get: { selectedConnection != nil },
            set: { if !$0 { selectedConnection = nil } }
        )) {
            Button("取消", role: .cancel) {
                selectedConnection = nil
            }
            Button("删除", role: .destructive) {
                if let connId = selectedConnection {
                    viewModel.deleteConnection(connId)
                    selectedConnection = nil
                }
            }
        } message: {
            Text("是否要删除这条连接线？")
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
        viewModel.addNode(newNode)
        Task {
            try? await cloudKitManager.saveNode(newNode)
        }
    }

    private func updateNodePositionDirect(_ nodeId: UUID, newPosition: CGPoint) {
        if let index = viewModel.nodes.firstIndex(where: { $0.id == nodeId }) {
            var updatedNode = viewModel.nodes[index]
            updatedNode.position = newPosition
            viewModel.updateNode(updatedNode)
        }
    }

    private func updateNode(_ node: MindMapNode) {
        viewModel.updateNode(node)
        Task {
            try? await cloudKitManager.saveNode(node)
        }
    }

    private func deleteNode(_ node: MindMapNode) {
        viewModel.deleteNode(node.id)
        Task {
            try? await cloudKitManager.deleteNode(node.id)
        }
    }

    private func addChildNode(for parentId: UUID) {
        let newNode = viewModel.createChildNode(for: parentId)
        Task {
            try? await cloudKitManager.saveNode(newNode)
        }
    }

    // MARK: - 连接操作
    private func toggleConnectionMode() {
        if viewModel.isConnectionMode {
            viewModel.cancelConnection()
        } else {
            // 需要先选择一个节点来开始连接
            // 这里可以显示一个提示
        }
    }

    private func connectionColor(for type: NodeConnection.ConnectionType) -> Color {
        switch type {
        case .parent:
            return Color.gray.opacity(0.5)
        case .related:
            return Color.blue.opacity(0.6)
        case .reference:
            return Color.purple.opacity(0.6)
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
                    // 清空并添加所有节点
                    viewModel.nodes.removeAll()
                    viewModel.addNodes(cloudNodes)
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
                viewModel.addNodes(cachedNodes)
            }
        }

        // 然后从云端同步
        do {
            let cloudNodes = try await cloudKitManager.fetchAllNodes()
            // 只有当云端有数据时才替换本地数据
            if !cloudNodes.isEmpty {
                await MainActor.run {
                    viewModel.nodes.removeAll()
                    viewModel.addNodes(cloudNodes)
                    cloudKitManager.saveNodesLocally(cloudNodes)
                }
            }
        } catch {
            print("Load error: \(error)")
        }
    }
}

// MARK: - 无限网格图案
struct InfiniteGridPattern: Shape {
    let offset: CGSize
    let scale: CGFloat
    let viewSize: CGSize

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let spacing: CGFloat = 30 * scale

        // 计算可见区域（考虑 offset）
        let visibleRect = CGRect(
            x: -offset.width - spacing * 2,
            y: -offset.height - spacing * 2,
            width: viewSize.width + spacing * 4,
            height: viewSize.height + spacing * 4
        )

        // 计算网格起始位置，对齐到网格
        let startX = (floor(visibleRect.minX / spacing) * spacing)
        let startY = (floor(visibleRect.minY / spacing) * spacing)
        let endX = visibleRect.maxX
        let endY = visibleRect.maxY

        // 绘制垂直线
        var x = startX
        while x <= endX {
            path.move(to: CGPoint(x: x, y: startY))
            path.addLine(to: CGPoint(x: x, y: endY))
            x += spacing
        }

        // 绘制水平线
        var y = startY
        while y <= endY {
            path.move(to: CGPoint(x: startX, y: y))
            path.addLine(to: CGPoint(x: endX, y: y))
            y += spacing
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
    let onToggleConnection: () -> Void
    let isConnectionMode: Bool

    var body: some View {
        VStack(spacing: 12) {
            Button(action: onAddNode) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 30))
                    .foregroundColor(.blue)
            }

            Button(action: onToggleConnection) {
                Image(systemName: isConnectionMode ? "link.circle.fill" : "link.circle")
                    .font(.system(size: 30))
                    .foregroundColor(isConnectionMode ? .green : .blue)
            }

            Divider()
                .frame(height: 2)
                .background(Color.gray.opacity(0.3))

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
    @State private var selectedParentId: UUID?

    let availableNodes: [MindMapNode]
    let onSave: (MindMapNode) -> Void
    let onParentChange: ((UUID?) -> Void)?

    init(
        node: MindMapNode,
        availableNodes: [MindMapNode] = [],
        onSave: @escaping (MindMapNode) -> Void,
        onParentChange: ((UUID?) -> Void)? = nil
    ) {
        _node = State(initialValue: node)
        _selectedParentId = State(initialValue: node.parentId)
        self.availableNodes = availableNodes
        self.onSave = onSave
        self.onParentChange = onParentChange
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

                if !availableNodes.isEmpty {
                    Section("父节点") {
                        Picker("选择父节点", selection: $selectedParentId) {
                            Text("无父节点").tag(nil as UUID?)
                            ForEach(availableNodes) { availableNode in
                                Text(availableNode.title).tag(availableNode.id as UUID?)
                            }
                        }
                        .pickerStyle(.menu)
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

                        // 如果父节点发生变化，调用回调
                        if selectedParentId != node.parentId {
                            onParentChange?(selectedParentId)
                        }

                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    MindMapCanvas(viewModel: MindMapViewModel())
}
