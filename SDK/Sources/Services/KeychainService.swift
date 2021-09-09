//  Copyright (c) 2021 D4L data4life gGmbH
//  All rights reserved.
//  
//  D4L owns all legal rights, title and interest in and to the Software Development Kit ("SDK"),
//  including any intellectual property rights that subsist in the SDK.
//  
//  The SDK and its documentation may be accessed and used for viewing/review purposes only.
//  Any usage of the SDK for other purposes, including usage for the development of
//  applications/third-party applications shall require the conclusion of a license agreement
//  between you and D4L.
//  
//  If you are interested in licensing the SDK for your own applications/third-party
//  applications and/or if you’d like to contribute to the development of the SDK, please
//  contact D4L by email to help@data4life.care.

import Foundation
import Security
import Combine

protocol KeychainServiceType {
    subscript(key: KeychainKey) -> String? { get set }
    func set(_ item: String?, forKey key: KeychainKey)
    func get(_ key: KeychainKey) throws -> String
    func clear()

    func getCommonKeyById(_ id: String) -> String?
    func store(commonKey: String, commonKeyId: String)
    func hasCommonKey(commonKeyId: String) -> Bool
}

enum KeychainKey: String, CaseIterable {
    case accessToken = "access_token"
    case refreshToken = "refresh_token"
    case authState = "auth_state"
    case userId = "user_id"
    case commonKeyId = "common_key_id"
    case commonKey = "common_key"
    case tagEncryptionKey = "tag_encryption_key"
}

struct KeychainService {
    let serviceName: String
    let groupId: String?
    let defaults: UserDefaults

    private let commonKeyPrefix = "common_key"
    private let splitChar: Character = "#"

    init(container: DIContainer, name: String, groupId: String? = nil) {
        self.serviceName = name
        self.groupId = groupId

        do {
            self.defaults = try container.resolve()
        } catch {
            fatalError(error.localizedDescription)
        }
        guard (self.defaults.value(forKey: name) as? Bool) != nil else {
            self.clear()
            self.defaults.setValue(true, forKey: name)
            return
        }
    }
}

extension KeychainService: KeychainServiceType {

    func clear() {
        KeychainKey.allCases.forEach { self.set(item: nil, forKey: $0.rawValue) }
        let generatedCommonKeys = getKeysContaining("\(commonKeyPrefix)\(splitChar)")
        generatedCommonKeys.forEach { self.set(item: nil, forKey: $0) }
    }

    subscript(key: KeychainKey) -> String? {
        get {
            return get(key.rawValue)
        }
        set {
            set(item: newValue, forKey: key.rawValue)
        }
    }

    func set(_ item: String?, forKey key: KeychainKey) {
        set(item: item, forKey: key.rawValue)
    }

    func get(_ key: KeychainKey) throws -> String {

        if let value: String = self.get(key.rawValue) {
            return value
        } else {
            guard key != KeychainKey.userId else {
                throw Data4LifeSDKError.notLoggedIn
            }

            throw Data4LifeSDKError.keychainItemNotFound(key.rawValue)
        }

    }
}

// MARK: - Private helper methods
extension KeychainService {
    private func query(for key: String) -> [CFString: Any] {
        var attr = [CFString: Any]()
        attr[kSecClass] = kSecClassGenericPassword
        attr[kSecAttrService] = "default"
        attr[kSecAttrAccount] = serviceName + "." + key

        if let groupId = groupId {
            attr[kSecAttrAccessGroup] = groupId
        }
        return attr
    }

    private func set(item: String?, forKey key: String) {
        var attr = self.query(for: key)

        if let item = item {
            SecItemDelete(attr as CFDictionary)
            attr[kSecValueData] = item.data(using: .utf8)
            SecItemAdd(attr as CFDictionary, nil)
        } else {
            SecItemDelete(attr as CFDictionary)
        }
   }

    private func get(_ key: String) -> String? {
        var attr = self.query(for: key)
        attr[kSecReturnData] = kCFBooleanTrue
        attr[kSecMatchLimit] = kSecMatchLimitOne

        var result: CFTypeRef?
        let status = SecItemCopyMatching(attr as CFDictionary, &result)

        guard status == errSecSuccess && result != nil else {
            return nil
        }

        if let data = result as? Data, let value = String(data: data, encoding: .utf8) {
            return value
        }

        return nil
    }

    // MARK: - Common Key methods
    func getCommonKeyById(_ id: String) -> String? {
        let completeCommonKeyId = "\(commonKeyPrefix)\(splitChar)\(id)"
        return self.get(completeCommonKeyId)
    }

    func store(commonKey: String, commonKeyId: String) {
        let completeCommonKeyId = "\(commonKeyPrefix)\(splitChar)\(commonKeyId)"
        self.set(item: commonKey, forKey: completeCommonKeyId)
    }

    func hasCommonKey(commonKeyId: String) -> Bool {
        let completeCommonKeyId = "\(commonKeyPrefix)\(splitChar)\(commonKeyId)"
        return self.contains(key: completeCommonKeyId)
    }

    private func contains(key: String) -> Bool {
        return get(key) != nil
    }

    private func getKeysContaining(_ string: String) -> [String] {
        var query = [CFString: Any]()
        query[kSecClass] = kSecClassGenericPassword
        query[kSecMatchLimit] = kSecMatchLimitAll

        // Initiate the search
        var items: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &items)
        guard status != errSecItemNotFound,
            status == errSecSuccess,
            let existingItems = items as? [[String:Any]]
            else {
                return []
        }

        let keys: [String] = existingItems.compactMap { dict in
            dict[kSecAttrAccount as String] as? String
        }

        let matched: [String] = keys.filter { $0.contains(string) }
        return matched
    }
}
