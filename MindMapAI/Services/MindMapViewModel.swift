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
        // 智能计算新节点位置，避免重叠
        let position = calculateNewNodePosition()

        let newNode = MindMapNode(
            title: title,
            content: content,
            position: position,
            color: color
        )

        addNode(newNode)
    }

    // 计算新节点位置，避免与现有节点重叠
    private func calculateNewNodePosition() -> CGPoint {
        if nodes.isEmpty {
            // 第一个节点放在中心
            return CGPoint(x: 400, y: 300)
        }

        // 螺旋式布局：以中心为起点，向外螺旋放置
        let centerX: CGFloat = 400
        let centerY: CGFloat = 300
        let angleStep: CGFloat = .pi * 2 / 5 // 每圈 5 个节点
        let radiusIncrement: CGFloat = 80

        let nodeIndex = nodes.count
        let ring = nodeIndex / 5 // 第几圈
        let positionInRing = nodeIndex % 5 // 圈内位置

        let radius = CGFloat(ring + 1) * radiusIncrement
        let angle = CGFloat(positionInRing) * angleStep

        let x = centerX + radius * cos(angle)
        let y = centerY + radius * sin(angle)

        return CGPoint(x: x, y: y)
    }
}
