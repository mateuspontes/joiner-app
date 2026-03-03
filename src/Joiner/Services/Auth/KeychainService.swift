import Foundation
import Security

final class KeychainService {
    static let shared = KeychainService()

    private let service = Constants.keychainService

    enum TokenType: String {
        case access = "access_token"
        case refresh = "refresh_token"
    }

    // MARK: - Token Storage

    func storeToken(_ token: String, forAccountId accountId: String, type: TokenType) throws {
        let key = "\(accountId)_\(type.rawValue)"
        let data = Data(token.utf8)

        // Delete existing
        let deleteQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
        ]
        SecItemDelete(deleteQuery as CFDictionary)

        // Add new
        let addQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock,
        ]

        let status = SecItemAdd(addQuery as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainError.unableToStore(status)
        }
    }

    func getToken(forAccountId accountId: String, type: TokenType) -> String? {
        let key = "\(accountId)_\(type.rawValue)"

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess, let data = result as? Data else {
            return nil
        }
        return String(data: data, encoding: .utf8)
    }

    func deleteTokens(forAccountId accountId: String) {
        for type in TokenType.allCases {
            let key = "\(accountId)_\(type.rawValue)"
            let query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: service,
                kSecAttrAccount as String: key,
            ]
            SecItemDelete(query as CFDictionary)
        }
        // Also delete metadata
        for metaKey in ["email", "displayName", "color"] {
            let key = "\(accountId)_meta_\(metaKey)"
            let query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: service,
                kSecAttrAccount as String: key,
            ]
            SecItemDelete(query as CFDictionary)
        }
    }

    // MARK: - Metadata

    func storeMetadata(forAccountId accountId: String, key: String, value: String) {
        let fullKey = "\(accountId)_meta_\(key)"
        let data = Data(value.utf8)

        let deleteQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: fullKey,
        ]
        SecItemDelete(deleteQuery as CFDictionary)

        let addQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: fullKey,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock,
        ]
        SecItemAdd(addQuery as CFDictionary, nil)
    }

    func getMetadata(forAccountId accountId: String, key: String) -> String? {
        let fullKey = "\(accountId)_meta_\(key)"

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: fullKey,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess, let data = result as? Data else {
            return nil
        }
        return String(data: data, encoding: .utf8)
    }

    // MARK: - Account Discovery

    func allAccountIds() -> [String] {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecReturnAttributes as String: true,
            kSecMatchLimit as String: kSecMatchLimitAll,
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess, let items = result as? [[String: Any]] else {
            return []
        }

        let ids = items
            .compactMap { $0[kSecAttrAccount as String] as? String }
            .filter { $0.hasSuffix("_\(TokenType.access.rawValue)") }
            .map { String($0.dropLast("_\(TokenType.access.rawValue)".count)) }

        return Array(Set(ids))
    }
}

extension KeychainService.TokenType: CaseIterable {}

enum KeychainError: LocalizedError {
    case unableToStore(OSStatus)

    var errorDescription: String? {
        switch self {
        case .unableToStore(let status):
            return "Keychain store failed with status: \(status)"
        }
    }
}
