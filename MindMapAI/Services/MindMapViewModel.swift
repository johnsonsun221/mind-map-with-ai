import Foundation
import SwiftUI
import Combine

/// 思维导图数据管理器 - 在画布和聊天窗口之间共享
class MindMapViewModel: ObservableObject {
    @Published var nodes: [MindMapNode] = []
    @Published var connections: [NodeConnection] = []

    // 连接模式
    @Published var isConnectionMode: Bool = false
    @Published var connectionStartNode: UUID?

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
        // 同时删除相关的连接
        connections.removeAll { $0.fromNodeId == nodeId || $0.toNodeId == nodeId }
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

    // 为指定节点创建子节点
    func createChildNode(for parentId: UUID) -> MindMapNode {
        guard let parentNode = nodes.first(where: { $0.id == parentId }) else {
            // 如果找不到父节点，创建一个普通节点
            let position = calculateNewNodePosition()
            let newNode = MindMapNode(
                title: "新节点",
                content: "",
                position: position
            )
            addNode(newNode)
            return newNode
        }

        // 计算子节点位置（在父节点下方）
        let childPosition = CGPoint(
            x: parentNode.position.x + CGFloat((parentNode.childrenIds.count % 3 - 1)) * 150,
            y: parentNode.position.y + 150
        )

        var newNode = MindMapNode(
            title: "新子节点",
            content: "",
            position: childPosition,
            parentId: parentId
        )

        addNode(newNode)

        // 更新父节点的子节点列表
        if let parentIndex = nodes.firstIndex(where: { $0.id == parentId }) {
            nodes[parentIndex].childrenIds.append(newNode.id)
        }

        // 创建父子连接
        createConnection(from: parentId, to: newNode.id, type: .parent)

        return newNode
    }

    // 为指定节点设置父节点
    func setParent(childId: UUID, parentId: UUID?) {
        guard let childIndex = nodes.firstIndex(where: { $0.id == childId }) else { return }

        // 移除旧的父子关系
        if let oldParentId = nodes[childIndex].parentId {
            // 从旧父节点的子节点列表中移除
            if let oldParentIndex = nodes.firstIndex(where: { $0.id == oldParentId }) {
                nodes[oldParentIndex].childrenIds.removeAll { $0 == childId }
            }
            // 删除旧的父子连接
            connections.removeAll {
                $0.fromNodeId == oldParentId && $0.toNodeId == childId && $0.connectionType == .parent
            }
        }

        // 设置新的父节点
        nodes[childIndex].parentId = parentId

        if let newParentId = parentId {
            // 添加到新父节点的子节点列表
            if let newParentIndex = nodes.firstIndex(where: { $0.id == newParentId }) {
                if !nodes[newParentIndex].childrenIds.contains(childId) {
                    nodes[newParentIndex].childrenIds.append(childId)
                }
            }
            // 创建新的父子连接
            createConnection(from: newParentId, to: childId, type: .parent)
        }
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

    // MARK: - 连接管理

    // 创建连接
    func createConnection(from: UUID, to: UUID, type: NodeConnection.ConnectionType = .parent) {
        // 避免重复连接
        if connections.contains(where: { $0.fromNodeId == from && $0.toNodeId == to }) {
            return
        }

        // 避免自己连接自己
        if from == to {
            return
        }

        let connection = NodeConnection(fromNodeId: from, toNodeId: to, connectionType: type)
        connections.append(connection)

        // 如果是父子关系，更新节点的 parentId 和 childrenIds
        if type == .parent {
            if let toIndex = nodes.firstIndex(where: { $0.id == to }) {
                nodes[toIndex].parentId = from
            }
            if let fromIndex = nodes.firstIndex(where: { $0.id == from }) {
                if !nodes[fromIndex].childrenIds.contains(to) {
                    nodes[fromIndex].childrenIds.append(to)
                }
            }
        }
    }

    // 删除连接
    func deleteConnection(_ connectionId: UUID) {
        if let connection = connections.first(where: { $0.id == connectionId }) {
            // 如果是父子关系，清除节点中的关系
            if connection.connectionType == .parent {
                if let toIndex = nodes.firstIndex(where: { $0.id == connection.toNodeId }) {
                    nodes[toIndex].parentId = nil
                }
                if let fromIndex = nodes.firstIndex(where: { $0.id == connection.fromNodeId }) {
                    nodes[fromIndex].childrenIds.removeAll { $0 == connection.toNodeId }
                }
            }
        }

        connections.removeAll { $0.id == connectionId }
    }

    // 开始连接模式
    func startConnection(from nodeId: UUID) {
        isConnectionMode = true
        connectionStartNode = nodeId
    }

    // 完成连接
    func completeConnection(to nodeId: UUID) {
        guard let startNode = connectionStartNode else { return }
        createConnection(from: startNode, to: nodeId, type: .related)
        cancelConnection()
    }

    // 取消连接模式
    func cancelConnection() {
        isConnectionMode = false
        connectionStartNode = nil
    }

    // 获取节点的所有连接
    func getConnections(for nodeId: UUID) -> [NodeConnection] {
        return connections.filter { $0.fromNodeId == nodeId || $0.toNodeId == nodeId }
    }
}
