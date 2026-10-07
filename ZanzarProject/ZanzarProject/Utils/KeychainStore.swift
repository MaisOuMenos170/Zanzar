import Foundation
import Security

enum KeychainError: Error, Sendable {
    case saveFailed(OSStatus)
    case deleteFailed(OSStatus)
}

protocol AuthTokenPersisting: Sendable {
    func saveToken(_ token: String) throws
    func readToken() -> String?
    func deleteToken() throws
}

nonisolated struct KeychainStore: AuthTokenPersisting {
    private let service = "com.zanzar.auth"
    private let account = "authToken"

    private var query: [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
    }

    private var protectedAttributes: [String: Any] {
        [
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
            kSecAttrSynchronizable as String: false
        ]
    }

    func saveToken(_ token: String) throws {
        let data = Data(token.utf8)

        let attributes: [String: Any] = [
            kSecValueData as String: data
        ].merging(protectedAttributes) { current, _ in current }

        let updateStatus = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        if updateStatus == errSecSuccess {
            return
        }

        if updateStatus == errSecItemNotFound {
            let addQuery = query.merging(attributes) { _, new in new }
            let addStatus = SecItemAdd(addQuery as CFDictionary, nil)
            guard addStatus == errSecSuccess else {
                throw KeychainError.saveFailed(addStatus)
            }
            return
        }

        throw KeychainError.saveFailed(updateStatus)
    }

    func readToken() -> String? {
        var readQuery = query
        readQuery[kSecReturnData as String] = true
        readQuery[kSecMatchLimit as String] = kSecMatchLimitOne

        var item: CFTypeRef?
        let status = SecItemCopyMatching(readQuery as CFDictionary, &item)
        guard status == errSecSuccess,
              let data = item as? Data,
              let token = String(data: data, encoding: .utf8),
              !token.isEmpty else {
            return nil
        }
        return token
    }

    func deleteToken() throws {
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.deleteFailed(status)
        }
    }
}
