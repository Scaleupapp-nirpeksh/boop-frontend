import Foundation
import Security

enum KeychainManager {
    private static let service = "com.boop.app"

    enum Key: String {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
    }

    static func save(key: Key, value: String) {
        guard let data = value.data(using: .utf8) else { return }

        // Delete existing item first
        delete(key: key)

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key.rawValue,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]

        SecItemAdd(query as CFDictionary, nil)
    }

    static func load(key: Key) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key.rawValue,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess, let data = result as? Data else {
            return nil
        }

        return String(data: data, encoding: .utf8)
    }

    static func delete(key: Key) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key.rawValue
        ]

        SecItemDelete(query as CFDictionary)
    }

    static func saveTokens(_ pair: TokenPair) {
        save(key: .accessToken, value: pair.accessToken)
        save(key: .refreshToken, value: pair.refreshToken)
    }

    static func loadTokens() -> TokenPair? {
        guard let access = load(key: .accessToken),
              let refresh = load(key: .refreshToken) else {
            return nil
        }
        return TokenPair(accessToken: access, refreshToken: refresh)
    }

    static func clearTokens() {
        delete(key: .accessToken)
        delete(key: .refreshToken)
    }
}
