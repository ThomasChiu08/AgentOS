import Foundation
import SwiftData

// MARK: - ArtifactType

enum ArtifactType: String, Codable {
    case document = "Document"
    case code = "Code"
    case report = "Report"
    case notes = "Notes"

    var icon: String {
        switch self {
        case .document: return "doc.richtext"
        case .code: return "chevron.left.forwardslash.chevron.right"
        case .report: return "chart.bar.doc.horizontal"
        case .notes: return "note.text"
        }
    }
}

// MARK: - Artifact Model

@Model final class Artifact {
    var id: UUID
    var type: ArtifactType
    var title: String
    var content: String
    var filePath: String
    var createdAt: Date

    var stage: Stage?

    init(type: ArtifactType, title: String, content: String = "", filePath: String = "") {
        self.id = UUID()
        self.type = type
        self.title = title
        self.content = content
        self.filePath = filePath
        self.createdAt = Date()
    }
}
