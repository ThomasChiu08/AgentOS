import Foundation

// MARK: - AgentOS Errors

enum AgentOSError: LocalizedError {
    case apiKeyMissing
    case pipelineExecutionFailed(String)
    case networkError(Error)
    case stageOutputEmpty(AgentRole)

    var errorDescription: String? {
        switch self {
        case .apiKeyMissing:
            return "API key is not configured. Please add it in Settings."
        case .pipelineExecutionFailed(let reason):
            return "Pipeline failed: \(reason)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .stageOutputEmpty(let role):
            return "\(role.rawValue) produced no output. Please try again."
        }
    }
}
