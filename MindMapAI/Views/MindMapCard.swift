import SwiftUI
import UniformTypeIdentifiers

/// 思维导图卡片视图
struct MindMapCard: View {
    let node: MindMapNode
    let onDrag: () -> Void
    let onTap: () -> Void
    let onDelete: () -> Void

    @State private var isDragging = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(node.title)
                    .font(.headline)
                    .foregroundColor(.white)
                    .lineLimit(2)

                Spacer()

                Button(action: onDelete) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.white.opacity(0.7))
                        .font(.system(size: 16))
                }
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
