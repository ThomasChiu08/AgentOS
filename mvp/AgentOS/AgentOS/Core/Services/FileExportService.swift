import Foundation

struct FileExportService {
    static let baseDir = FileManager.default
        .urls(for: .documentDirectory, in: .userDomainMask)[0]
        .appending(path: "AgentOS")

    /// Exports content to ~/Documents/AgentOS/{projectTitle}/{role}-{ISO8601}.md
    /// Returns the URL of the saved file.
    @discardableResult
    static func export(content: String, role: AgentRole, projectTitle: String) throws -> URL {
        let safeTitle = sanitizeFilename(projectTitle.isEmpty ? "untitled" : projectTitle)
        let projectDir = baseDir.appending(path: safeTitle)

        try FileManager.default.createDirectory(
            at: projectDir,
            withIntermediateDirectories: true
        )

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        let timestamp = formatter.string(from: Date())
            .replacingOccurrences(of: ":", with: "-")

        let safeRole = sanitizeFilename(role.rawValue.lowercased().replacingOccurrences(of: " ", with: "-"))
        let filename = "\(safeRole)-\(timestamp).md"
        let fileURL = projectDir.appending(path: filename)

        try content.write(to: fileURL, atomically: true, encoding: .utf8)
        return fileURL
    }

    // MARK: - Private

    private static func sanitizeFilename(_ name: String) -> String {
        let allowed = CharacterSet.alphanumerics.union(.init(charactersIn: "-_"))
        return name
            .components(separatedBy: allowed.inverted)
            .filter { !$0.isEmpty }
            .joined(separator: "-")
    }
}
