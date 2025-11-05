import SwiftUI
import UniformTypeIdentifiers

/// 思维导图卡片视图
struct MindMapCard: View {
    let node: MindMapNode
    let onDrag: () -> Void
    let onTap: () -> Void
    let onDelete: () -> Void
    var onStartConnection: (() -> Void)? = nil

    @State private var isDragging = false
    @State private var showActionMenu = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(node.title)
                    .font(.headline)
                    .foregroundColor(.white)
                    .lineLimit(2)

                Spacer()

                Menu {
                    if let onStartConnection = onStartConnection {
                        Button(action: onStartConnection) {
                            Label("创建连接", systemImage: "link.circle")
                        }
                    }

                    Button(role: .destructive, action: onDelete) {
                        Label("删除节点", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle.fill")
                        .foregroundColor(.white.opacity(0.7))
                        .font(.system(size: 16))
                }
                .menuStyle(.borderlessButton)
            }

            if !node.content.isEmpty {
                Text(node.content)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.9))
                    .lineLimit(3)
            }

            HStack {
                Image(systemName: "calendar")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))

                Text(formatDate(node.updatedAt))
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
            }
        }
        .padding()
        .frame(width: 200)
        .frame(minHeight: 120)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(node.colorValue)
                .shadow(color: .black.opacity(isDragging ? 0.3 : 0.15), radius: isDragging ? 12 : 6, x: 0, y: isDragging ? 6 : 3)
        )
        .scaleEffect(isDragging ? 1.05 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isDragging)
        .onTapGesture {
            onTap()
        }
        .onLongPressGesture(minimumDuration: 0.5) {
            // 长按开始连接
            onStartConnection?()
        }
        .onDrag {
            isDragging = true
            onDrag()

            // 创建拖放数据
            let draggedNode = DraggedNode(nodeId: node.id, title: node.title, content: node.content)
            guard let data = try? JSONEncoder().encode(draggedNode) else {
                return NSItemProvider()
            }

            let itemProvider = NSItemProvider(item: data as NSData, typeIdentifier: UTType.data.identifier)
            return itemProvider
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

#Preview {
    MindMapCard(
        node: MindMapNode(
            title: "测试节点",
            content: "这是一个测试内容",
            color: "blue"
        ),
        onDrag: {},
        onTap: {},
        onDelete: {}
    )
    .padding()
}
