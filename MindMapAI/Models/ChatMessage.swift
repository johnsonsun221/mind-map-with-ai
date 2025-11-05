import Foundation

/// AI 聊天消息模型
struct ChatMessage: Identifiable, Codable, Equatable {
    let id: UUID
    var role: MessageRole
    var content: String
    var timestamp: Date
    var relatedNodeId: UUID? // 关联的思维导图节点 ID

    enum MessageRole: String, Codable {
        case user
        case assistant
        case system
    }

    init(
        id: UUID = UUID(),
        role: MessageRole,
        content: String,
        relatedNodeId: UUID? = nil
    ) {
        self.id = id
        self.role = role
        self.content = content
        self.timestamp = Date()
        self.relatedNodeId = relatedNodeId
    }
}
