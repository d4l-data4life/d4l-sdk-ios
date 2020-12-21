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

import XCTest
@testable import Data4LifeSDK
import Then

class EncryptedRecordTests: XCTestCase {

    var cryptoService: CryptoServiceMock!
    var commonKeyService: CommonKeyServiceMock!

    override func setUp() {
        super.setUp()

        cryptoService = CryptoServiceMock()
        commonKeyService = CommonKeyServiceMock()
    }

    func testConvertEncryptedRecordFailMissingTek() {
        let document = FhirFactory.createStu3DocumentReferenceResource()
        let record = DecryptedRecordFactory.create(document)
        let encryptedRecord = EncryptedRecordFactory.create(for: record)

        let expectedError = Data4LifeSDKError.missingTagKey
        let asyncExpectation = expectation(description: "Should fail decrypting record")

        DecryptedFhirStu3Record.from(encryptedRecord: encryptedRecord,
                             cryptoService: cryptoService,
                             commonKeyService: commonKeyService)
            .then { _ in
                XCTFail("Should return an error")
            }.onError { error in
                XCTAssertEqual(error as? Data4LifeSDKError, expectedError)
            }.finally {
                asyncExpectation.fulfill()
        }

        waitForExpectations(timeout: 5)
    }

    func testConvertEncryptedRecordFailMissingRecordCommonKey() {
        let document = FhirFactory.createStu3DocumentReferenceResource()
        let record = DecryptedRecordFactory.create(document)
        let encryptedRecord = EncryptedRecordFactory.create(for: record)
        let expectedError = Data4LifeSDKError.missingCommonKey

        cryptoService.tek = KeyFactory.createKey()
        cryptoService.decryptValuesResult = record.tags.toKeyValueStringArray()

        commonKeyService.fetchKeyResult = Async.reject(expectedError)

        let asyncExpectation = expectation(description: "Should fail decrypting record")

        DecryptedFhirStu3Record.from(encryptedRecord: encryptedRecord,
                                 cryptoService: cryptoService,
                                 commonKeyService: commonKeyService)
            .then { _ in
                XCTFail("Should return an error")
            }.onError { error in
                XCTAssertEqual(error as? Data4LifeSDKError, expectedError)
            }.finally {
                asyncExpectation.fulfill()
        }

        waitForExpectations(timeout: 5)
    }

    func testConvertEncryptedRecordFailInvalidDataKey() {
        let document = FhirFactory.createStu3DocumentReferenceResource()
        let record = DecryptedRecordFactory.create(document)
        var encryptedRecord = EncryptedRecordFactory.create(for: record)

        commonKeyService.fetchKeyResult = Async.resolve(KeyFactory.createKey())
        cryptoService.decryptValuesResult = record.tags.toKeyValueStringArray()

        let expectedError = Data4LifeSDKError.couldNotReadBase64EncodedData
        let asyncExpectation = expectation(description: "Should fail decrypting record")

        cryptoService.tek = KeyFactory.createKey()
        encryptedRecord.encryptedDataKey = String(describing: Data([0x00]))

        DecryptedFhirStu3Record.from(encryptedRecord: encryptedRecord, cryptoService: cryptoService, commonKeyService: commonKeyService)
            .then { _ in
                XCTFail("Should return an error")
            }.onError { error in
                XCTAssertEqual(error as? Data4LifeSDKError, expectedError)
            }.finally {
                asyncExpectation.fulfill()
        }

        waitForExpectations(timeout: 5)
    }

    func testConvertEncryptedRecordFailInvalidBodyPayload() {
        let document = FhirFactory.createStu3DocumentReferenceResource()
        let record = DecryptedRecordFactory.create(document)
        var encryptedRecord = EncryptedRecordFactory.create(for: record)
        encryptedRecord.encryptedBody = String(describing: Data([0x00]))

        let expectedError = Data4LifeSDKError.couldNotReadBase64EncodedData
        let asyncExpectation = expectation(description: "Should fail decrypting record")

        cryptoService.tek = KeyFactory.createKey()
        commonKeyService.fetchKeyResult = Promise.resolve(KeyFactory.createKey())

        let decryptedDataKey = try! JSONEncoder().encode(record.dataKey)
        let decryptedTags = record.tags.toKeyValueStringArray()

        cryptoService.decryptDataResult = decryptedDataKey
        cryptoService.decryptValuesResult = decryptedTags

        DecryptedFhirStu3Record.from(encryptedRecord: encryptedRecord, cryptoService: cryptoService, commonKeyService: commonKeyService)
            .then { _ in
                XCTFail("Should return an error")
            }.onError { error in
                XCTAssertEqual(error as? Data4LifeSDKError, expectedError)
            }.finally {
                asyncExpectation.fulfill()
        }

        waitForExpectations(timeout: 5)
    }

    func testFailLoadingEncryptedRecordJSON() {
        let resource = FhirFactory.createDomainResource()
        let record = DecryptedRecordFactory.create(resource)
        let encryptedRecord = EncryptedRecordFactory.create(for: record)

        do {
            var json = encryptedRecord.json
            json["createdAt"] = encryptedRecord.createdAt.timeIntervalSince1970

            // insert invalid date
            json["date"] = Date().ISO8601FormattedString()
            let data = try JSONSerialization.data(withJSONObject: json, options: .prettyPrinted)

            _ = try JSONDecoder().decode(EncryptedRecord.self, from: data)
            XCTFail("Should fail with error")
        } catch let error as Data4LifeSDKError {
            XCTAssertEqual(error, Data4LifeSDKError.invalidRecordDateFormat)
        } catch {
            XCTFail("Should be an SDK error type")
        }
    }

    func testConvertEncryptedRecordFailInvalidModelVersion() {
        let resource = FhirFactory.createStu3CarePlanResource()
        let record = DecryptedRecordFactory.create(resource)
        var encryptedRecord = EncryptedRecordFactory.create(for: record)
        encryptedRecord.encryptedAttachmentKey = nil
        encryptedRecord.modelVersion += 1

        commonKeyService.fetchKeyResult = Async.resolve(KeyFactory.createKey())

        let expectedError = Data4LifeSDKError.invalidRecordModelVersionNotSupported
        let asyncExpectation = expectation(description: "Should fail decrypting record")

        cryptoService.tek = KeyFactory.createKey()

        let decryptedDataKey = try! JSONEncoder().encode(record.dataKey)
        let decryptedTags = record.tags.toKeyValueStringArray()

        let encryptedResourceData = Data(base64Encoded: encryptedRecord.encryptedBody)!
        let decryptedResourceData: Data = try! JSONEncoder().encode(record.resource)
        let encryptedDataKeyData = Data(base64Encoded: encryptedRecord.encryptedDataKey)!

        cryptoService.decryptDataForInput = [(encryptedDataKeyData, decryptedDataKey),
                                             (encryptedResourceData, decryptedResourceData)]
        cryptoService.decryptValuesResult = decryptedTags

        DecryptedFhirStu3Record.from(encryptedRecord: encryptedRecord, cryptoService: cryptoService, commonKeyService: commonKeyService)
            .then { _ in
                XCTFail("Should return an error")
            }.onError { error in
                XCTAssertEqual(error as? Data4LifeSDKError, expectedError)
            }.finally {
                asyncExpectation.fulfill()
        }

        waitForExpectations(timeout: 5)
    }
}
