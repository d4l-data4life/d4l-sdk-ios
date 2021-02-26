//  Copyright (c) 2020 D4L data4life gGmbH
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
import Data4LifeCrypto
@_implementationOnly import Then

protocol CommonKeyServiceType {
    static var initialId: String { get }
    var currentId: String? { get }
    var currentKey: Key? { get }

    func fetchKey(with: String) -> Async<Key>
    func storeKey(_ key: Key, id: String, isCurrent: Bool)
}

class CommonKeyService: CommonKeyServiceType {
    static let initialId = "00000000-0000-0000-0000-000000000000"

    var currentKey: Key? {
        return fetchKeyLocally(with: currentId ?? CommonKeyService.initialId)
    }

    var currentId: String? {
        get {
            return self.keychainService[.commonKeyId]
        }
        set {
            self.keychainService[.commonKeyId] = newValue
        }
    }

    private var keychainService: KeychainServiceType
    private var cryptoService: CryptoServiceType
    private var sessionService: SessionService

    private static var dateFormatter = DateFormatter.with(format: .iso8601TimeZone)

    private lazy var decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(CommonKeyService.dateFormatter)
        return decoder
    }()

    private lazy var encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .formatted(CommonKeyService.dateFormatter)
        return encoder
    }()

    init(container: DIContainer) {
        do {
            self.keychainService = try container.resolve()
            self.cryptoService = try container.resolve()
            self.sessionService = try container.resolve()
        } catch {
            fatalError(error.localizedDescription)
        }
    }

    func fetchKey(with commonKeyId: String) -> Async<Key> {
        return async {
            if !self.hasCommonKey(id: commonKeyId) {
                try await(self.fetchKeyRemotely(with: commonKeyId))
            }

            guard let commonKey = self.fetchKeyLocally(with: commonKeyId) else {
                throw Data4LifeSDKError.missingCommonKey
            }

            return commonKey
        }
    }

    func storeKey(_ key: Key, id: String, isCurrent: Bool) {
        guard let encodedCommonKey = try? encoder.encode(key).base64EncodedString() else {
            return
        }
        if id == CommonKeyService.initialId {
            self.keychainService[.commonKey] = encodedCommonKey
            return
        }
        self.keychainService.store(commonKey: encodedCommonKey, commonKeyId: id)
        if isCurrent {
            currentId = id
        }
    }

    private func fetchKeyLocally(with id: String) -> Key? {
        let commonKey = id == CommonKeyService.initialId ? self.keychainService[.commonKey] :
            self.keychainService.getCommonKeyById(id)
        return transformCommonKey(commonKey)
    }

    private func fetchKeyRemotely(with id: String) -> Async<Void> {
        return async {
            let userId = try await(self.keychainService.get(.userId))
            let route = Router.fetchCommonKey(userId: userId, commonKeyId: id)
            let response: CommonKeyResponse = try await(self.sessionService.request(route: route).responseDecodable())

            guard let eckData = Data(base64Encoded: response.commonKey) else {
                    throw Data4LifeSDKError.couldNotReadBase64EncodedData
            }

            let keyPair = try self.cryptoService.fetchOrGenerateKeyPair()
            let decryptedCommonKeyData = try self.cryptoService.decrypt(data: eckData, keypair: keyPair)
            let commonKey: Key = try JSONDecoder().decode(Key.self, from: decryptedCommonKeyData)

            self.storeKey(commonKey, id: id, isCurrent: false)
        }
    }

    private func hasCommonKey(id: String) -> Bool {
        if id == CommonKeyService.initialId {
            return self.keychainService[.commonKey] != nil
        }
        return keychainService.hasCommonKey(commonKeyId: id)
    }

    private func transformCommonKey(_ commonKeyBase64EncodedString: String?) -> Key? {
        guard
            let commonKeyBase64EncodedString = commonKeyBase64EncodedString,
            let commonKeyData = Data(base64Encoded: commonKeyBase64EncodedString),
            let commonKey: Key = try? decoder.decode(Key.self, from: commonKeyData)
            else {
                return nil
        }
        return commonKey
    }
}
