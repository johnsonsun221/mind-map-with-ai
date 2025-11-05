import Foundation
import CloudKit
import Combine

/// CloudKit 管理器，负责 iCloud 同步
class CloudKitManager: ObservableObject {
    @Published var nodes: [MindMapNode] = []
    @Published var isSyncing = false
    @Published var syncError: Error?

    private let container: CKContainer
    private let database: CKDatabase
    private let recordType = "MindMapNode"

    init() {
        // 使用私有数据库进行同步
        self.container = CKContainer(identifier: "iCloud.com.mindmap.MindMapAI")
        self.database = container.privateCloudDatabase
    }

    // MARK: - 保存节点到 iCloud
    func saveNode(_ node: MindMapNode) async throws {
        isSyncing = true
        defer { isSyncing = false }

        let record = CKRecord(recordType: recordType, recordID: CKRecord.ID(recordName: node.id.uuidString))

        record["title"] = node.title as CKRecordValue
        record["content"] = node.content as CKRecordValue
        record["positionX"] = node.position.x as CKRecordValue
        record["positionY"] = node.position.y as CKRecordValue
        record["color"] = node.color as CKRecordValue
        record["createdAt"] = node.createdAt as CKRecordValue
        record["updatedAt"] = node.updatedAt as CKRecordValue

        if let parentId = node.parentId {
            record["parentId"] = parentId.uuidString as CKRecordValue
        }

        // 保存子节点 IDs
        let childrenIdsStrings = node.childrenIds.map { $0.uuidString }
        record["childrenIds"] = childrenIdsStrings as CKRecordValue

        try await database.save(record)
    }

    // MARK: - 从 iCloud 加载所有节点
    func fetchAllNodes() async throws -> [MindMapNode] {
        isSyncing = true
        defer { isSyncing = false }

        let query = CKQuery(recordType: recordType, predicate: NSPredicate(value: true))
        query.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: true)]

        let results = try await database.records(matching: query)
        var nodes: [MindMapNode] = []

        for (_, result) in results.matchResults {
            switch result {
            case .success(let record):
                if let node = parseNode(from: record) {
                    nodes.append(node)
                }
            case .failure(let error):
                print("Failed to fetch record: \(error)")
            }
        }

        await MainActor.run {
            self.nodes = nodes
        }

        return nodes
    }

    // MARK: - 删除节点
    func deleteNode(_ nodeId: UUID) async throws {
        isSyncing = true
        defer { isSyncing = false }

        let recordID = CKRecord.ID(recordName: nodeId.uuidString)
        try await database.deleteRecord(withID: recordID)

        await MainActor.run {
            self.nodes.removeAll { $0.id == nodeId }
        }
    }

    // MARK: - 批量保存节点
    func saveNodes(_ nodes: [MindMapNode]) async throws {
        isSyncing = true
        defer { isSyncing = false }

        for node in nodes {
            try await saveNode(node)
        }
    }

    // MARK: - 解析 CKRecord 到 MindMapNode
    private func parseNode(from record: CKRecord) -> MindMapNode? {
        guard
            let title = record["title"] as? String,
            let content = record["content"] as? String,
            let positionX = record["positionX"] as? Double,
            let positionY = record["positionY"] as? Double,
            let color = record["color"] as? String,
            let createdAt = record["createdAt"] as? Date,
            let updatedAt = record["updatedAt"] as? Date
        else {
            return nil
        }

        let id = UUID(uuidString: record.recordID.recordName) ?? UUID()
        let position = CGPoint(x: positionX, y: positionY)

        let parentIdString = record["parentId"] as? String
        let parentId = parentIdString != nil ? UUID(uuidString: parentIdString!) : nil

        let childrenIdsStrings = record["childrenIds"] as? [String] ?? []
        let childrenIds = childrenIdsStrings.compactMap { UUID(uuidString: $0) }

        var node = MindMapNode(
            id: id,
            title: title,
            content: content,
            position: position,
            color: color,
            parentId: parentId,
            childrenIds: childrenIds
        )

        // 手动设置日期，因为 init 会自动生成
        node.createdAt = createdAt
        node.updatedAt = updatedAt

        return node
    }

    // MARK: - 本地缓存
    func saveNodesLocally(_ nodes: [MindMapNode]) {
        if let encoded = try? JSONEncoder().encode(nodes) {
            UserDefaults.standard.set(encoded, forKey: "cachedNodes")
        }
    }

    func loadNodesLocally() -> [MindMapNode] {
        guard let data = UserDefaults.standard.data(forKey: "cachedNodes"),
              let nodes = try? JSONDecoder().decode([MindMapNode].self, from: data) else {
            return []
        }
        return nodes
    }
}
