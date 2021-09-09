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

import XCTest
@testable import Data4LifeSDK
import Combine

class KeychainServiceTests: XCTestCase {
    var keychain: KeychainService!
    var defaults: UserDefaults!
    var keychainName = UUID().uuidString
    var groupId: String?
    var container: Data4LifeDITestContainer!

    override func setUp() {
        super.setUp()

        container = Data4LifeDITestContainer()
        container.registerDependencies()
        keychain = KeychainService(container: container, name: keychainName, groupId: groupId)

        do {
            defaults = try container.resolve()
        } catch {
            XCTFail(error.localizedDescription)
        }
        keychain.clear()
    }

    override func tearDown() {
        defaults = nil
        keychain = nil
        super.tearDown()
    }

    func testClearKeychainOnNewInstall() {
        let accessToken = UUID().uuidString

        defaults.setValue(nil, forKey: keychainName)
        XCTAssertTrue(defaults.value(forKey: keychainName) == nil)

        keychain[.accessToken] = nil
        XCTAssertTrue(keychain[.accessToken] == nil)

        keychain[.accessToken] = accessToken
        XCTAssertEqual(keychain[.accessToken], accessToken)

        // Removes value from user defaults indicating app was already installed
        keychain = nil
        defaults.setValue(nil, forKey: keychainName)
        keychain = KeychainService(container: container, name: keychainName, groupId: groupId)

        XCTAssertTrue(keychain[.accessToken] == nil)
    }

    func testSetGet() {
        let accessToken = "some_access_token"
        keychain[.accessToken] = accessToken
        XCTAssertEqual(keychain[.accessToken], accessToken)

        let refreshToken = "some_refresh_token"
        keychain[.refreshToken] = refreshToken
        XCTAssertEqual(keychain[.refreshToken], refreshToken)

        let userId = "some_user_id"
        keychain[.userId] = userId
        XCTAssertEqual(keychain[.userId], userId)

        let tagEncryptionKey = "some_tag_encryption_key"
        keychain[.tagEncryptionKey] = tagEncryptionKey
        XCTAssertEqual(keychain[.tagEncryptionKey], tagEncryptionKey)
    }

    func testClear() {
        let someValue = "some_value"

        keychain[.accessToken] = someValue
        keychain[.refreshToken] = someValue
        keychain[.userId] = someValue
        keychain[.tagEncryptionKey] = someValue

        XCTAssertEqual(keychain[.accessToken], someValue)
        XCTAssertEqual(keychain[.refreshToken], someValue)
        XCTAssertEqual(keychain[.userId], someValue)
        XCTAssertEqual(keychain[.tagEncryptionKey], someValue)

        keychain.clear()
        XCTAssertNil(self.keychain[.accessToken])
        XCTAssertNil(self.keychain[.refreshToken])
        XCTAssertNil(self.keychain[.userId])
        XCTAssertNil(self.keychain[.tagEncryptionKey])
    }

    func testUpdateTokenSync() {
        let first = UUID().uuidString
        let second = UUID().uuidString

        keychain[.accessToken] = first
        XCTAssertEqual(keychain[.accessToken], first)

        keychain[.accessToken] = second
        XCTAssertEqual(keychain[.accessToken], second)
    }

    func testUpdateTokenAsync() throws {
        let first = UUID().uuidString
        let second = UUID().uuidString
        keychain.set(first, forKey: .accessToken)
        var accessToken = try self.keychain.get(.accessToken)
        XCTAssertEqual(accessToken, first)
        self.keychain.set(second, forKey: .accessToken)
        accessToken = try self.keychain.get(.accessToken)
        XCTAssertEqual(accessToken, second)
    }

    func testKeychainKeyNotFound() throws {
        let expectedError = Data4LifeSDKError.keychainItemNotFound("access_token")
        XCTAssertThrowsError(try keychain.get(.accessToken),
        "should throw error", { error in
            XCTAssertEqual(error as? Data4LifeSDKError, expectedError)
        })
    }

    func testKeychainKeyCustomError() throws {
        let expectedError = Data4LifeSDKError.notLoggedIn
        XCTAssertThrowsError(try keychain.get(.userId),
        "should throw error", { error in
            XCTAssertEqual(error as? Data4LifeSDKError, expectedError)
        })
    }

    func testGroupKeychain() {
        let name = UUID().uuidString
        let groupId = UUID().uuidString
        var groupedKeychain = KeychainService(container: container, name: name, groupId: groupId)

        let item = UUID().uuidString
        groupedKeychain[.accessToken] = item

        // grouped keychain should not be able to read item back as groupId does not exist in the project settings
        XCTAssertNil(groupedKeychain[.accessToken])
    }

    func testCommonKey() {
        let commonKeyId = UUID().uuidString
        let commonKey = UUID().uuidString

        XCTAssertFalse(keychain.hasCommonKey(commonKeyId: commonKeyId))
        XCTAssertNil(keychain.getCommonKeyById(commonKeyId))

        keychain.store(commonKey: commonKey, commonKeyId: commonKeyId)
        keychain[.commonKeyId] = commonKeyId

        XCTAssertTrue(keychain.hasCommonKey(commonKeyId: commonKeyId))
        XCTAssertEqual(keychain.getCommonKeyById(commonKeyId), commonKey)
    }
}