import Foundation

enum ProviderItem: Identifiable, Hashable {
    case builtIn(AIProvider)
    case custom(UUID)

    var id: String {
        switch self {
        case .builtIn(let provider): return "builtin.\(provider.rawValue)"
        case .custom(let uuid): return "custom.\(uuid.uuidString)"
        }
    }

    var isCustom: Bool {
        if case .custom = self { return true }
        return false
    }
}
