import Foundation
import Security

enum KeychainError: Error, Sendable {
    case saveFailed(OSStatus)
    case deleteFailed(OSStatus)
}

nonisolated protocol AuthTokenPersisting: Sendable {
    func saveTokens(_ tokens: AuthTokens) throws
    func readTokens() -> AuthTokens?
    func deleteTokens() throws
}

nonisolated struct KeychainStore: AuthTokenPersisting {
    private let service = "com.zanzar.auth"
    private let accessAccount = "authToken"
    private let refreshAccount = "refreshToken"

    private func query(account: String) -> [String: Any] {
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

    func saveTokens(_ tokens: AuthTokens) throws {
        try save(tokens.accessToken, account: accessAccount)
        try save(tokens.refreshToken, account: refreshAccount)
    }

    func readTokens() -> AuthTokens? {
        guard let access = read(account: accessAccount),
              let refresh = read(account: refreshAccount),
              let tokens = AuthTokens(accessToken: access, refreshToken: refresh) else {
            try? deleteTokens()
            return nil
        }
        return tokens
    }

    func deleteTokens() throws {
        let accessResult = Result { try delete(account: accessAccount) }
        let refreshResult = Result { try delete(account: refreshAccount) }
        try accessResult.get()
        try refreshResult.get()
    }

    private func save(_ value: String, account: String) throws {
        let query = query(account: account)
        let attributes: [String: Any] = [
            kSecValueData as String: Data(value.utf8)
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

    private func read(account: String) -> String? {
        var readQuery = query(account: account)
        readQuery[kSecReturnData as String] = true
        readQuery[kSecMatchLimit as String] = kSecMatchLimitOne

        var item: CFTypeRef?
        let status = SecItemCopyMatching(readQuery as CFDictionary, &item)
        guard status == errSecSuccess,
              let data = item as? Data,
              let value = String(data: data, encoding: .utf8),
              !value.isEmpty else {
            return nil
        }
        return value
    }

    private func delete(account: String) throws {
        let status = SecItemDelete(query(account: account) as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.deleteFailed(status)
        }
    }
}
