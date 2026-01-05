//
//  KeychainHelper.swift
//  midori
//
//  Secure storage for API keys using macOS Keychain
//

import Foundation
import Security

enum KeychainError: Error {
    case duplicateEntry
    case unknown(OSStatus)
    case itemNotFound
    case invalidData

    var localizedDescription: String {
        switch self {
        case .duplicateEntry:
            return "Key already exists in Keychain"
        case .unknown(let status):
            return "Keychain error: \(status)"
        case .itemNotFound:
            return "Key not found in Keychain"
        case .invalidData:
            return "Invalid data in Keychain"
        }
    }
}

class KeychainHelper {
    static let shared = KeychainHelper()

    private let service = "com.midori.app"
    private let account = "openrouter-api-key"

    private init() {}

    // MARK: - Public API

    func saveAPIKey(_ key: String) throws {
        // First try to delete any existing key
        try? deleteAPIKey()

        guard let data = key.data(using: .utf8) else {
            throw KeychainError.invalidData
        }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlocked
        ]

        let status = SecItemAdd(query as CFDictionary, nil)

        guard status == errSecSuccess else {
            if status == errSecDuplicateItem {
                throw KeychainError.duplicateEntry
            }
            throw KeychainError.unknown(status)
        }

        print("✓ API key saved to Keychain")
    }

    func getAPIKey() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data,
              let key = String(data: data, encoding: .utf8) else {
            return nil
        }

        return key
    }

    func deleteAPIKey() throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]

        let status = SecItemDelete(query as CFDictionary)

        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unknown(status)
        }

        print("✓ API key deleted from Keychain")
    }

    func hasAPIKey() -> Bool {
        return getAPIKey() != nil
    }
}
