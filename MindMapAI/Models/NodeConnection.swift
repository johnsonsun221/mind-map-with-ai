import Foundation
import SwiftUI

/// 节点之间的连接
struct NodeConnection: Identifiable, Codable, Equatable {
    let id: UUID
    var fromNodeId: UUID
    var toNodeId: UUID
    var connectionType: ConnectionType
    var createdAt: Date

    enum ConnectionType: String, Codable {
        case parent // 父子关系
        case related // 相关关系
        case reference // 引用关系
    }

    init(
        id: UUID = UUID(),
        fromNodeId: UUID,
        toNodeId: UUID,
        connectionType: ConnectionType = .parent
    ) {
        self.id = id
        self.fromNodeId = fromNodeId
        self.toNodeId = toNodeId
        self.connectionType = connectionType
        self.createdAt = Date()
    }
}
