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
import Combine

class EncryptedRecordTests: XCTestCase {

    private lazy var container: Data4LifeDITestContainer = {
        let container = Data4LifeDITestContainer()
        container.registerDependencies()
        return container
    }()

    private lazy var encryptedRecordFactory = EncryptedRecordFactory(container: container)
    private var cryptoService: CryptoServiceMock!
    private var commonKeyService: CommonKeyServiceMock!

    override func setUp() {
        super.setUp()

        cryptoService = CryptoServiceMock()
        commonKeyService = CommonKeyServiceMock()
    }

    func testConvertEncryptedRecordFailMissingTek() throws {
        let document = FhirFactory.createStu3DocumentReferenceResource()
        let record = DecryptedRecordFactory.create(document)
        let encryptedRecord = encryptedRecordFactory.create(for: record)

        let expectedError = Data4LifeSDKError.missingTagKey

        _ = try DecryptedFhirStu3Record.from(encryptedRecord: encryptedRecord,
                                             cryptoService: cryptoService,
                                             commonKeyService: commonKeyService)
        XCTAssertThrowsError(expectedError)
    }

    func testConvertEncryptedRecordFailMissingRecordCommonKey() throws {
        let document = FhirFactory.createStu3DocumentReferenceResource()
        let record = DecryptedRecordFactory.create(document)
        let encryptedRecord = encryptedRecordFactory.create(for: record)
        let expectedError = Data4LifeSDKError.missingCommonKey

        cryptoService.tagEncryptionKey = KeyFactory.createKey()
        let tagGroup = TagGroup(tags: record.tags, annotations: record.annotations)
        cryptoService.decryptValuesResult = encryptedRecordFactory.tagsParameter(for: tagGroup)

        commonKeyService.fetchKeyResult = Fail(error: expectedError).asyncFuture
        XCTAssertThrowsError(try DecryptedFhirStu3Record.from(encryptedRecord: encryptedRecord,
                                                              cryptoService: cryptoService,
                                                              commonKeyService: commonKeyService),
                             "should throw error", { error in
                                XCTAssertEqual(error as? Data4LifeSDKError, expectedError)
                             })
    }

    func testConvertEncryptedRecordFailInvalidDataKey() throws {
        let document = FhirFactory.createStu3DocumentReferenceResource()
        let record = DecryptedRecordFactory.create(document)
        let tagGroup = TagGroup(tags: record.tags, annotations: record.annotations)
        var encryptedRecord = encryptedRecordFactory.create(for: record)

        commonKeyService.fetchKeyResult = Just(KeyFactory.createKey()).asyncFuture
        cryptoService.decryptValuesResult = encryptedRecordFactory.tagsParameter(for: tagGroup)

        let expectedError = Data4LifeSDKError.couldNotReadBase64EncodedData

        cryptoService.tagEncryptionKey = KeyFactory.createKey()
        encryptedRecord.encryptedDataKey = String(describing: Data([0x00]))

        XCTAssertThrowsError(try DecryptedFhirStu3Record.from(encryptedRecord: encryptedRecord, cryptoService: cryptoService, commonKeyService: commonKeyService),
                             "should throw error", { error in
                                XCTAssertEqual(error as? Data4LifeSDKError, expectedError)
                             })
    }

    func testConvertEncryptedRecordFailInvalidBodyPayload() throws {

        let document = FhirFactory.createStu3DocumentReferenceResource()
        let record = DecryptedRecordFactory.create(document)
        var encryptedRecord = encryptedRecordFactory.create(for: record)
        encryptedRecord.encryptedBody = String(describing: Data([0x00]))

        let expectedError = Data4LifeSDKError.couldNotReadBase64EncodedData

        cryptoService.tagEncryptionKey = KeyFactory.createKey()
        commonKeyService.fetchKeyResult = Just(KeyFactory.createKey()).asyncFuture

        let decryptedDataKey = try! JSONEncoder().encode(record.dataKey)
        let tagGroup = TagGroup(tags: record.tags, annotations: record.annotations)
        let decryptedTags = encryptedRecordFactory.tagsParameter(for: tagGroup)

        cryptoService.decryptDataResult = decryptedDataKey
        cryptoService.decryptValuesResult = decryptedTags

        XCTAssertThrowsError(try DecryptedFhirStu3Record.from(encryptedRecord: encryptedRecord, cryptoService: cryptoService, commonKeyService: commonKeyService),
                             "should throw error" , { error in
                                XCTAssertEqual(error as? Data4LifeSDKError, expectedError)
                             })
    }

    func testFailLoadingEncryptedRecordJSON() {
        let resource = FhirFactory.createStu3DomainResource()
        let record = DecryptedRecordFactory.create(resource)
        let encryptedRecord = encryptedRecordFactory.create(for: record)

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

    func testConvertEncryptedRecordFailInvalidModelVersion() throws {
        let resource = FhirFactory.createStu3CarePlanResource()
        let record = DecryptedRecordFactory.create(resource)
        var encryptedRecord = encryptedRecordFactory.create(for: record)
        encryptedRecord.encryptedAttachmentKey = nil
        encryptedRecord.modelVersion += 1

        commonKeyService.fetchKeyResult = Just(KeyFactory.createKey()).asyncFuture

        let expectedError = Data4LifeSDKError.invalidRecordModelVersionNotSupported

        cryptoService.tagEncryptionKey = KeyFactory.createKey()

        let decryptedDataKey = try! JSONEncoder().encode(record.dataKey)
        let tagGroup = TagGroup(tags: record.tags, annotations: record.annotations)
        let decryptedTags = encryptedRecordFactory.tagsParameter(for: tagGroup)

        let encryptedResourceData = Data(base64Encoded: encryptedRecord.encryptedBody)!
        let decryptedResourceData: Data = try! JSONEncoder().encode(record.resource)
        let encryptedDataKeyData = Data(base64Encoded: encryptedRecord.encryptedDataKey)!

        cryptoService.decryptDataForInput = [(encryptedDataKeyData, decryptedDataKey),
                                             (encryptedResourceData, decryptedResourceData)]
        cryptoService.decryptValuesResult = decryptedTags

        XCTAssertThrowsError(try DecryptedFhirStu3Record.from(encryptedRecord: encryptedRecord, cryptoService: cryptoService, commonKeyService: commonKeyService),
                             "should throw error", { error in
                                XCTAssertEqual(error as? Data4LifeSDKError, expectedError)
                             })
    }
}
