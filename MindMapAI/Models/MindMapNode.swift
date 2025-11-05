import Foundation
import SwiftUI

/// 思维导图节点模型
struct MindMapNode: Identifiable, Codable, Equatable {
    let id: UUID
    var title: String
    var content: String
    var position: CGPoint
    var color: String // 使用字符串存储颜色，便于 Codable
    var parentId: UUID?
    var childrenIds: [UUID]
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        title: String = "新节点",
        content: String = "",
        position: CGPoint = .zero,
        color: String = "blue",
        parentId: UUID? = nil,
        childrenIds: [UUID] = []
    ) {
        self.id = id
        self.title = title
        self.content = content
        self.position = position
        self.color = color
        self.parentId = parentId
        self.childrenIds = childrenIds
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    // 获取颜色
    var colorValue: Color {
        switch color {
        case "blue": return .blue
        case "green": return .green
        case "orange": return .orange
        case "purple": return .purple
        case "pink": return .pink
        case "red": return .red
        case "yellow": return .yellow
        default: return .blue
        }
    }

    // 用于拖放的类型标识
    static let dragType = "com.mindmap.node"
}

/// 用于传递拖放数据
struct DraggedNode: Codable {
    let nodeId: UUID
    let title: String
    let content: String
}
