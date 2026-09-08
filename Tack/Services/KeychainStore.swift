import Foundation
import Security

/// Tiny Keychain wrapper. Stores string values keyed by service/account.
/// Used for Notion OAuth token, vault bookmarks serialized as Data, etc.
public enum KeychainStore {
    public enum Service: String {
        case notionOAuth = "app.tack.notion.oauth"
        case vaultBookmark = "app.tack.obsidian.vault"
    }

    public static func setString(_ value: String, service: Service, account: String) {
        guard let data = value.data(using: .utf8) else { return }
        setData(data, service: service, account: account)
    }

    public static func string(service: Service, account: String) -> String? {
        guard let data = data(service: service, account: account) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    public static func setData(_ data: Data, service: Service, account: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service.rawValue,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(query as CFDictionary)
        var attrs = query
        attrs[kSecValueData as String] = data
        attrs[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
        SecItemAdd(attrs as CFDictionary, nil)
    }

    public static func data(service: Service, account: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service.rawValue,
            kSecAttrAccount as String: account,
            kSecMatchLimit as String: kSecMatchLimitOne,
            kSecReturnData as String: true
        ]
        var item: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess else { return nil }
        return item as? Data
    }

    @discardableResult
    public static func remove(service: Service, account: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service.rawValue,
            kSecAttrAccount as String: account
        ]
        return SecItemDelete(query as CFDictionary) == errSecSuccess
    }
}
