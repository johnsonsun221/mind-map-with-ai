import Foundation

/// AI 聊天消息模型
struct ChatMessage: Identifiable, Codable, Equatable {
    let id: UUID
    var role: MessageRole
    var content: String
    var timestamp: Date
    var relatedNodeId: UUID? // 关联的思维导图节点 ID
    var suggestedNodes: [NodeSuggestion]? // AI 建议的节点

    enum MessageRole: String, Codable {
        case user
        case assistant
        case system
    }

    init(
        id: UUID = UUID(),
        role: MessageRole,
        content: String,
        relatedNodeId: UUID? = nil,
        suggestedNodes: [NodeSuggestion]? = nil
    ) {
        self.id = id
        self.role = role
        self.content = content
        self.timestamp = Date()
        self.relatedNodeId = relatedNodeId
        self.suggestedNodes = suggestedNodes
    }
}

/// AI 建议的节点
struct NodeSuggestion: Identifiable, Codable, Equatable {
    let id: UUID
    var title: String
    var content: String
    var color: String

    init(
        id: UUID = UUID(),
        title: String,
        content: String,
        color: String = "blue"
    ) {
        self.id = id
        self.title = title
        self.content = content
        self.color = color
    }
}
