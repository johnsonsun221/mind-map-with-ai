import Foundation
import SwiftUI
import Combine

/// 思维导图数据管理器 - 在画布和聊天窗口之间共享
class MindMapViewModel: ObservableObject {
    @Published var nodes: [MindMapNode] = []

    // 添加节点
    func addNode(_ node: MindMapNode) {
        nodes.append(node)
    }

    // 更新节点
    func updateNode(_ node: MindMapNode) {
        if let index = nodes.firstIndex(where: { $0.id == node.id }) {
            nodes[index] = node
        }
    }

    // 删除节点
    func deleteNode(_ nodeId: UUID) {
        nodes.removeAll { $0.id == nodeId }
    }

    // 批量添加节点
    func addNodes(_ newNodes: [MindMapNode]) {
        nodes.append(contentsOf: newNodes)
    }

    // 根据 AI 建议创建节点
    func createNodeFromAISuggestion(title: String, content: String, color: String = "blue") {
        // 计算新节点位置，避免重叠
        let baseX: CGFloat = 200
        let baseY: CGFloat = 200
        let offset: CGFloat = CGFloat(nodes.count % 5) * 50

        let newNode = MindMapNode(
            title: title,
            content: content,
            position: CGPoint(x: baseX + offset, y: baseY + offset),
            color: color
        )

        addNode(newNode)
    }
}
