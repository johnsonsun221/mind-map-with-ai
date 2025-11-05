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

    // MARK: - Codable
    enum CodingKeys: String, CodingKey {
        case id, title, content, positionX, positionY, color, parentId, childrenIds, createdAt, updatedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        content = try container.decode(String.self, forKey: .content)
        let x = try container.decode(CGFloat.self, forKey: .positionX)
        let y = try container.decode(CGFloat.self, forKey: .positionY)
        position = CGPoint(x: x, y: y)
        color = try container.decode(String.self, forKey: .color)
        parentId = try container.decodeIfPresent(UUID.self, forKey: .parentId)
        childrenIds = try container.decode([UUID].self, forKey: .childrenIds)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(content, forKey: .content)
        try container.encode(position.x, forKey: .positionX)
        try container.encode(position.y, forKey: .positionY)
        try container.encode(color, forKey: .color)
        try container.encodeIfPresent(parentId, forKey: .parentId)
        try container.encode(childrenIds, forKey: .childrenIds)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
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
