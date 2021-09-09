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

@_implementationOnly import Data4LifeCrypto
@_implementationOnly import Alamofire
import Combine

protocol UserServiceType {
    func fetchUserInfo() -> SDKFuture<Void>
    func getUserId() throws -> String
}

class UserService: UserServiceType {
    let sessionService: SessionService
    var cryptoService: CryptoServiceType
    var commonKeyService: CommonKeyServiceType

    let keychainService: KeychainServiceType

    init(container: DIContainer) {
        do {
            self.sessionService = try container.resolve()
            self.cryptoService = try container.resolve()
            self.keychainService = try container.resolve()
            self.commonKeyService = try container.resolve()
        } catch {
            fatalError(error.localizedDescription)
        }
    }

    func fetchUserInfo() -> SDKFuture<Void> {
        return combineAsync {
            let response: UserInfoResponse = try combineAwait(self.sessionService.request(route: Router.userInfo).responseDecodable())

            guard
                let encryptedCommonKey = Data(base64Encoded: response.commonKey),
                let encryptedTagEncryptionKey = Data(base64Encoded: response.tagEncryptionKey)
                else {
                    throw Data4LifeSDKError.couldNotReadBase64EncodedData
            }

            let keyPair = try self.cryptoService.fetchOrGenerateKeyPair()
            let decryptedCommonKeyData = try self.cryptoService.decrypt(data: encryptedCommonKey, keypair: keyPair)
            let commonKey: Key = try JSONDecoder().decode(Key.self, from: decryptedCommonKeyData)

            let commonKeyId = response.commonKeyId ?? CommonKeyService.initialId
            self.commonKeyService.storeKey(commonKey, id: commonKeyId, isCurrent: true)

            let decryptedTagEncryptionKeyData = try self.cryptoService.decrypt(data: encryptedTagEncryptionKey, key: commonKey)
            let tagKey: Key = try JSONDecoder().decode(Key.self, from: decryptedTagEncryptionKeyData)

            self.cryptoService.tagEncryptionKey = tagKey
            self.keychainService.set(response.userId, forKey: .userId)
        }
    }

    func getUserId() throws -> String {
        try self.keychainService.get(.userId)
    }
}
