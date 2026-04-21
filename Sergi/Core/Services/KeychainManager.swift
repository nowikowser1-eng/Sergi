import Foundation
import KeychainAccess

// MARK: - Keychain Manager

enum KeychainManager {
    private static let keychain = Keychain(service: "com.sergi.app")
        .accessibility(.whenUnlockedThisDeviceOnly)

    // MARK: - OpenAI API Key

    private static let openAIKeyName = "openai_api_key"

    static var openAIAPIKey: String? {
        get { try? keychain.get(openAIKeyName) }
        set {
            if let value = newValue {
                try? keychain.set(value, key: openAIKeyName)
            } else {
                try? keychain.remove(openAIKeyName)
            }
        }
    }

    /// Resolves the API key: Keychain first, then environment variable as fallback (debug only)
    static var resolvedOpenAIKey: String {
        if let keychainKey = openAIAPIKey, !keychainKey.isEmpty {
            return keychainKey
        }
        #if DEBUG
        return ProcessInfo.processInfo.environment["OPENAI_API_KEY"] ?? ""
        #else
        return ""
        #endif
    }

    // MARK: - Helpers

    static func clearAll() {
        try? keychain.removeAll()
    }
}
