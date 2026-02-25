import Security
import Foundation

enum KeychainHelper {
    private static let service = "com.thomas.agentos"
    private static let apiKeyAccount = "anthropic.apikey"

    // MARK: - Legacy (Anthropic only) — preserved for backward compatibility

    static var apiKey: String? {
        get { read(account: apiKeyAccount) }
        set {
            if let value = newValue {
                save(value, account: apiKeyAccount)
            } else {
                delete(account: apiKeyAccount)
            }
        }
    }

    // MARK: - Per-provider subscript

    static subscript(provider: AIProvider) -> String? {
        get {
            // Anthropic maps to the legacy account so existing keys survive
            let account = provider == .anthropic ? apiKeyAccount : provider.keychainAccount
            return read(account: account)
        }
        set {
            let account = provider == .anthropic ? apiKeyAccount : provider.keychainAccount
            if let value = newValue, !value.isEmpty {
                save(value, account: account)
            } else {
                delete(account: account)
            }
        }
    }

    /// Returns true if a key exists (or isn't required) for the given provider.
    static func hasKey(for provider: AIProvider) -> Bool {
        !provider.requiresAPIKey || self[provider] != nil
    }

    // MARK: - Account-level Access (for custom providers)

    static func save(_ value: String, account: String) {
        let data = Data(value.utf8)
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account,
            kSecValueData: data
        ]
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }

    static func read(account: String) -> String? {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account,
            kSecReturnData: true,
            kSecMatchLimit: kSecMatchLimitOne
        ]
        var result: AnyObject?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data
        else { return nil }
        return String(data: data, encoding: .utf8)
    }

    static func delete(account: String) {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account
        ]
        SecItemDelete(query as CFDictionary)
    }
}
