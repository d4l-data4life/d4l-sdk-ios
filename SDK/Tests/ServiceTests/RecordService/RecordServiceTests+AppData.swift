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
import Alamofire
import Combine
import Data4LifeFHIR

extension RecordServiceTests {

    func testCreateAppDataRecord() {

        let userId = UUID().uuidString
        let resource = FhirFactory.createAppDataResourceData()
        let record = DecryptedRecordFactory.create(resource)
        var encryptedRecord = encryptedRecordFactory.create(for: record, commonKeyId: commonKeyId)
        encryptedRecord.encryptedAttachmentKey = nil

        userService.fetchUserInfoResult = Just(()).asyncFuture()

        // Common key
        commonKeyService.currentId = commonKeyId
        commonKeyService.currentKey = commonKey

        // encrypted body
        cryptoService.encryptValueResult = Just(encryptedRecord.encryptedBodyData).asyncFuture()

        // encrypted tags
        taggingService.tagResourceResult = TagGroup(tags: record.tags)
        cryptoService.encryptValuesResult = encryptedRecord.encryptedTags
        cryptoService.decryptValuesResult = encryptedRecord.encryptedTags

        let dataInput: (Data, Data) = (encryptedRecord.encryptedDataKeyData, encryptedRecord.encryptedDataKeyData)
        let bodyInput: (Data, Data) = (encryptedRecord.encryptedBodyData, encryptedRecord.encryptedBodyData)

        let inputs = [dataInput, bodyInput]

        cryptoService.generateGCKeyResult = record.dataKey
        cryptoService.encryptDataForInput = inputs
        cryptoService.decryptDataForInput = inputs

        stub("POST", "/users/\(userId)/records", with: encryptedRecord.data)

        let asyncExpectation = expectation(description: "should create record")
        let createdRecord: SDKFuture<DecryptedAppDataRecord> = recordService.createRecord(forResource: resource, userId: userId)
        createdRecord.then { result in
            defer { asyncExpectation.fulfill() }

            XCTAssertNotNil(result)
            XCTAssertNotNil(result.resource)

            XCTAssertEqual(result.id, record.id)
            XCTAssertEqual(result.metadata.updatedDate.ISO8601FormattedString(),
                           record.metadata.updatedDate.ISO8601FormattedString())
            XCTAssertEqual(result.tags, record.tags)
            XCTAssertEqual(result.dataKey, record.dataKey)

            XCTAssertTrue(self.userService.fetchUserInfoCalled)
            XCTAssertEqual(AnySDKResource(resource: result.resource), AnySDKResource(resource: resource))
        }

        waitForExpectations(timeout: 5)
    }

    func testFetchAppDataRecord() {
        let userId = UUID().uuidString
        let appData = "test".data(using: .utf8)!

        let record = DecryptedRecordFactory.create(appData, dataKey: commonKey)
        var encryptedRecord = encryptedRecordFactory.create(for: record, commonKeyId: commonKeyId)
        encryptedRecord.encryptedAttachmentKey = nil

        // Common key
        commonKeyService.fetchKeyResult = Just(commonKey).asyncFuture()

        // encrypted body
        cryptoService.encryptValueResult = Just(encryptedRecord.encryptedBodyData).asyncFuture()

        // encrypted tags
        taggingService.tagResourceResult = TagGroup(tags: record.tags)
        cryptoService.encryptValuesResult = encryptedRecord.encryptedTags
        cryptoService.decryptValuesResult = encryptedRecord.encryptedTags

        // encrypted data key
        cryptoService.encryptDataResult = encryptedRecord.encryptedDataKeyData
        cryptoService.generateGCKeyResult = record.dataKey

        // decrypt values for data key and body
        let dataInput: (Data, Data) = (encryptedRecord.encryptedDataKeyData, encryptedRecord.encryptedDataKeyData)
        let bodyInput: (Data, Data) = (encryptedRecord.encryptedBodyData, encryptedRecord.encryptedBodyData)
        cryptoService.decryptDataForInput = [dataInput, bodyInput]

        stub("GET", "/users/\(userId)/records/\(record.id)", with: encryptedRecord.data)

        let asyncExpectation = expectation(description: "should return a record")
        recordService.fetchRecord(recordId: record.id, userId: userId, decryptedRecordType: DecryptedAppDataRecord.self)
            .then { record in
                defer { asyncExpectation.fulfill() }

                XCTAssertNotNil(record)
                XCTAssertEqual(record.id, record.id)
                XCTAssertEqual(record.metadata.updatedDate, record.metadata.updatedDate)
                XCTAssertEqual(record.tags, record.tags)
                XCTAssertEqual(record.dataKey, record.dataKey)
                XCTAssertEqual(record.attachmentKey, record.attachmentKey)
        }

        waitForExpectations(timeout: 5)
    }

    func testUpdateAppDataRecord() {
        let userId = UUID().uuidString
        let oldData = FhirFactory.createAppDataResourceData()
        let oldRecord = DecryptedRecordFactory.create(oldData)
        var oldEncryptedRecord = encryptedRecordFactory.create(for: oldRecord, commonKeyId: commonKeyId)
        oldEncryptedRecord.encryptedAttachmentKey = nil

        let oldBaseData = try! JSONDecoder().decode(SomeAppDataResource.self, from: oldData)
        var newBaseData = oldBaseData
        newBaseData.subtitle = "modified"
        let newData = try! JSONEncoder().encode(newBaseData)
        var record = DecryptedRecordFactory.create(newData)
        record.id = oldRecord.id
        let encryptedRecord = encryptedRecordFactory.create(for: record)

        stub("GET", "/users/\(userId)/records/\(oldRecord.id)", with: oldEncryptedRecord.data)

        userService.fetchUserInfoResult = Just(()).asyncFuture()

        // Common key
        commonKeyService.currentId = commonKeyId
        commonKeyService.currentKey = commonKey

        // encrypted body
        cryptoService.encryptValueResult = Just(encryptedRecord.encryptedBodyData).asyncFuture()

        // encrypted tags
        taggingService.tagResourceResult = TagGroup(tags: record.tags)
        cryptoService.encryptValuesResult = encryptedRecord.encryptedTags
        cryptoService.decryptValuesResult = encryptedRecord.encryptedTags
        cryptoService.generateGCKeyResult = record.dataKey

        // decrypt values for data key and body
        let dataInput: (Data, Data) = (encryptedRecord.encryptedDataKeyData,
                                       encryptedRecord.encryptedDataKeyData)
        let bodyInput: (Data, Data) = (encryptedRecord.encryptedBodyData,
                                       encryptedRecord.encryptedBodyData)

        let oldDataInput: (Data, Data) = (oldEncryptedRecord.encryptedDataKeyData,
                                          oldEncryptedRecord.encryptedDataKeyData)
        let oldBodyInput: (Data, Data) = (oldEncryptedRecord.encryptedBodyData,
                                          oldEncryptedRecord.encryptedBodyData)

        let inputs = [dataInput, bodyInput, oldDataInput, oldBodyInput]
        cryptoService.encryptDataForInput = inputs
        cryptoService.decryptDataForInput = inputs

        stub("PUT", "/users/\(userId)/records/\(record.id)", with: encryptedRecord.data)

        let asyncExpectation = expectation(description: "should update record")
        let updatedRecord: SDKFuture<DecryptedAppDataRecord> = recordService.updateRecord(forResource: newData,
                                                                                               userId: userId,
                                                                                               recordId: record.id,
                                                                                               attachmentKey: record.attachmentKey)
        updatedRecord.then { result in
            defer { asyncExpectation.fulfill() }
            XCTAssertNotNil(result)
            XCTAssertEqual(result.id, record.id)
            XCTAssertEqual(result.metadata.updatedDate.ISO8601FormattedString(), record.metadata.updatedDate.ISO8601FormattedString())
            XCTAssertEqual(result.tags, record.tags)
            XCTAssertEqual(result.dataKey, record.dataKey)
            XCTAssertEqual(result.attachmentKey, result.attachmentKey)

            XCTAssertTrue(self.userService.fetchUserInfoCalled)
            let resultedData = try! JSONDecoder().decode(SomeAppDataResource.self, from: result.resource)
            XCTAssertEqual(resultedData.title, oldBaseData.title)
            XCTAssertEqual(resultedData.subtitle, newBaseData.subtitle)
        }

        waitForExpectations(timeout: 5)
    }

    func testSearchAppDataRecordsWithNonPercentEncodableTags() {
        let annotations = ["example"]
        let userId = UUID().uuidString
        let startDate = Date()
        let endDate = Date()
        let appData = FhirFactory.createAppDataResourceData()

        let record = DecryptedRecordFactory.create(appData, annotations: annotations)
        var encryptedRecord = encryptedRecordFactory.create(for: record, resource: appData, commonKeyId: commonKeyId)
        encryptedRecord.encryptedAttachmentKey = nil

        taggingService.tagTypeResult = TagGroup(tags: ["resourcetype": "documentreference"], annotations: annotations)
        taggingService.tagResourceResult = TagGroup(tags: record.tags, annotations: record.annotations)
        cryptoService.encryptValuesResult = encryptedRecord.encryptedTags
        cryptoService.decryptValuesResult = encryptedRecord.encryptedTags

        // Common key
        commonKeyService.fetchKeyResult = Just(commonKey).asyncFuture()

        // encrypted body
        cryptoService.encryptValueResult = Just(encryptedRecord.encryptedBodyData).asyncFuture()

        // encrypted data key
        cryptoService.encryptDataResult = encryptedRecord.encryptedDataKeyData
        cryptoService.generateGCKeyResult = record.dataKey

        // decrypt values for data key and body
        let dataInput: (Data, Data) = (encryptedRecord.encryptedDataKeyData, encryptedRecord.encryptedDataKeyData)
        let bodyInput: (Data, Data) = (encryptedRecord.encryptedBodyData, encryptedRecord.encryptedBodyData)
        cryptoService.decryptDataForInput = [dataInput, bodyInput]

        stub("GET", "/users/\(userId)/records", with: [encryptedRecord.json])

        let asyncExpectation = expectation(description: "should return a list of records")
        let searchRecords: SDKFuture<[DecryptedAppDataRecord]> = recordService.searchRecords(for: userId,
                                                                                         from: startDate,
                                                                                         to: endDate,
                                                                                         pageSize: 10,
                                                                                         offset: 0)
         searchRecords.then { records in
                defer { asyncExpectation.fulfill() }
                XCTAssertEqual(records.count, 1)
            XCTAssertEqual(record.resource, appData)
        }

        waitForExpectations(timeout: 5)
    }

    func testSearchAppDataRecordsWithPercentEncodableTags() {
        let userId = UUID().uuidString
        let startDate = Date()
        let endDate = Date()
        let appData = FhirFactory.createAppDataResourceData()
        let annotations = ["hello-hello"]
        let record = DecryptedRecordFactory.create(appData, annotations: annotations)
        var encryptedRecord = encryptedRecordFactory.create(for: record, resource: appData, commonKeyId: commonKeyId)
        encryptedRecord.encryptedAttachmentKey = nil

        taggingService.tagTypeResult = TagGroup(tags: ["resourcetype": "documentreference"], annotations: annotations)
        taggingService.tagResourceResult = TagGroup(tags: record.tags)
        cryptoService.encryptValuesResult = encryptedRecord.encryptedTags
        cryptoService.decryptValuesResult = encryptedRecord.encryptedTags

        // Common key
        commonKeyService.fetchKeyResult = Just(commonKey).asyncFuture()

        // encrypted body
        cryptoService.encryptValueResult = Just(encryptedRecord.encryptedBodyData).asyncFuture()

        // encrypted data key
        cryptoService.encryptDataResult = encryptedRecord.encryptedDataKeyData
        cryptoService.generateGCKeyResult = record.dataKey

        // decrypt values for data key and body
        let dataInput: (Data, Data) = (encryptedRecord.encryptedDataKeyData, encryptedRecord.encryptedDataKeyData)
        let bodyInput: (Data, Data) = (encryptedRecord.encryptedBodyData, encryptedRecord.encryptedBodyData)
        cryptoService.decryptDataForInput = [dataInput, bodyInput]

        stub("GET", "/users/\(userId)/records", with: [encryptedRecord.json])

        let asyncExpectation = expectation(description: "should return a list of records")
        let searchRecords: SDKFuture<[DecryptedAppDataRecord]> = recordService.searchRecords(for: userId,
                                                                                         from: startDate,
                                                                                         to: endDate,
                                                                                         pageSize: 10,
                                                                                         offset: 0)
        searchRecords.then { records in
            defer { asyncExpectation.fulfill() }
            XCTAssertEqual(records.count, 1)
            XCTAssertEqual(record.resource, appData)
        }

        waitForExpectations(timeout: 5)
    }

    func testSearchNoAppDataResults() {
        let userId = UUID().uuidString
        let startDate = Date()
        let endDate = Date()
        stub("GET", "/users/\(userId)/records", with: [])

        taggingService.tagTypeResult = TagGroup(tags: [:])
        cryptoService.encryptValuesResult = []
        cryptoService.decryptValuesResult = []

        let asyncExpectation = expectation(description: "should return an empty list of records")
        recordService.searchRecords(for: userId,
                                    from: startDate,
                                    to: endDate,
                                    pageSize: 10,
                                    offset: 0,
                                    decryptedRecordType: DecryptedAppDataRecord.self)
            .then { records in
                defer { asyncExpectation.fulfill() }
                XCTAssertEqual(records.count, 0)
        }

        waitForExpectations(timeout: 5)
    }

    func testCountAppDataRecordsWithNonPercentEncodableTags() {
        let annotations = ["hello"]
        let userId = UUID().uuidString
        let recordCount = 101

        stub("HEAD", "/users/\(userId)/records", with: Data(), headers: ["x-total-count" : "\(recordCount)"], code: 200)

        taggingService.tagTypeResult = TagGroup(tags: [:], annotations: annotations)
        cryptoService.encryptValuesResult = []
        cryptoService.decryptValuesResult = []

        let asyncExpectation = expectation(description: "should return header containg record count")
        recordService.countRecords(userId: userId, resourceType: Data.self)
            .then { count in
                defer { asyncExpectation.fulfill() }
                XCTAssertEqual(count, recordCount)
        }

        waitForExpectations(timeout: 5)
    }

    func testCountAppDataRecordsWithPercentEncodableTags() {
        let annotations = ["hello-percent"]
        let userId = UUID().uuidString
        let recordCount = 101

        stub("HEAD", "/users/\(userId)/records", with: Data(), headers: ["x-total-count" : "\(recordCount)"], code: 200)

        taggingService.tagTypeResult = TagGroup(tags: [:], annotations: annotations)
        cryptoService.encryptValuesResult = []
        cryptoService.decryptValuesResult = []

        let asyncExpectation = expectation(description: "should return header containg record count")
        recordService.countRecords(userId: userId, resourceType: Data.self)
            .then { count in
                defer { asyncExpectation.fulfill() }
                XCTAssertEqual(count, recordCount)
            }

        waitForExpectations(timeout: 5)
    }

    func testCountsAppDataRecordsFail() {
        let userId = UUID().uuidString
        let expectedError = Data4LifeSDKError.keyMissingInSerialization(key: "`x-total-count`")

        stub("HEAD", "/users/\(userId)/records", with: Data(), headers: ["x-count" : "\(0)"], code: 200)

        taggingService.tagTypeResult = TagGroup(tags: [:])
        cryptoService.encryptValuesResult = []
        cryptoService.decryptValuesResult = []

        let asyncExpectation = expectation(description: "should fail counting records")
        recordService.countRecords(userId: userId, resourceType: Data.self)
            .then { _ in
                XCTFail("Should return an error")
        } onError: { error in
            XCTAssertEqual(error as? Data4LifeSDKError, expectedError)
        } finally: {
            asyncExpectation.fulfill()
        }

        waitForExpectations(timeout: 5)
    }

    func testFailBuildingAppDataSearchParamsMissingTek() {
        let userId = UUID().uuidString

        taggingService.tagTypeResult = TagGroup(tags: [:], annotations: [])
        cryptoService.tagEncryptionKey = nil
        builder.searchParametersError = Data4LifeSDKError.missingTagKey

        let expectedError = Data4LifeSDKError.missingTagKey

        let asyncExpectation = expectation(description: "should fail building params")
        recordService.searchRecords(for: userId,
                                    from: Date(),
                                    to: Date(),
                                    pageSize: 10,
                                    offset: 0,
                                    decryptedRecordType: DecryptedAppDataRecord.self)
            .then { _ in
                XCTFail("Should return an error")
        } onError: { error in
            XCTAssertEqual(error as? Data4LifeSDKError, expectedError)
        } finally: {
            asyncExpectation.fulfill()
        }

        waitForExpectations(timeout: 5)
    }

    func testFailBuildingAppDataUploadParamsMissingTek() {
        let userId = UUID().uuidString
        let document = FhirFactory.createAppDataResourceData()
        let record = DecryptedRecordFactory.create(document)

        taggingService.tagResourceResult = TagGroup(tags: record.tags, annotations: record.annotations)
        cryptoService.generateGCKeyResult = record.dataKey
        cryptoService.tagEncryptionKey = nil
        builder.uploadParametersError = Data4LifeSDKError.missingTagKey
        userService.fetchUserInfoResult = Just(()).asyncFuture()
        commonKeyService.currentKey = record.dataKey

        let expectedError = Data4LifeSDKError.missingTagKey
        let asyncExpectation = expectation(description: "should fail loading tek")

        let createdRecord: SDKFuture<DecryptedAppDataRecord> = recordService.createRecord(forResource: document, userId: userId)
        createdRecord.then { _ in
            XCTFail("Should return an error")
        } onError: { error in
            XCTAssertEqual(error as? Data4LifeSDKError, expectedError)
        } finally: {
            asyncExpectation.fulfill()
        }

        waitForExpectations(timeout: 5)
    }

    func testFailUploadAppDataRecordMissingCommonKey() {
        let userId = UUID().uuidString

        let document = FhirFactory.createAppDataResourceData()
        let record = DecryptedRecordFactory.create(document)

        let expectedError = Data4LifeSDKError.missingCommonKey
        let asyncExpectation = expectation(description: "should fail loading common key")

        taggingService.tagResourceResult = TagGroup(tags: record.tags)
        userService.fetchUserInfoResult = Just(()).asyncFuture()
        cryptoService.generateGCKeyResult = record.dataKey

        commonKeyService.currentKey = nil
        let createdRecord: SDKFuture<DecryptedAppDataRecord> = recordService.createRecord(forResource: document, userId: userId)
        createdRecord.then { _ in
            XCTFail("Should return an error")
        } onError: { error in
            XCTAssertEqual(error as? Data4LifeSDKError, expectedError)
        } finally: {
            asyncExpectation.fulfill()
        }

        waitForExpectations(timeout: 5)
    }

    func testFetchAppDataRecordsFailsUnsupportedVersion() {
        let userId = UUID().uuidString

        let document = FhirFactory.createAppDataResourceData()
        let record = DecryptedRecordFactory.create(document, dataKey: commonKey)
        var encryptedRecord = encryptedRecordFactory.create(for: record, commonKeyId: commonKeyId)
        encryptedRecord.encryptedAttachmentKey = nil

        // Common key
        commonKeyService.fetchKeyResult = Just(commonKey).asyncFuture()

        // Validator
        versionValidator.fetchCurrentVersionStatusResult = Just(.unsupported).asyncFuture()
        let expectedError = Data4LifeSDKError.unsupportedVersionRunning

        let asyncExpectation = expectation(description: "should return a record")
        recordService.fetchRecord(recordId: record.id, userId: userId, decryptedRecordType: type(of: record))
            .then { _ in
                XCTFail("Should return an error")
        } onError: { error in
            XCTAssertEqual(error as? Data4LifeSDKError, expectedError)
        } finally: {
            asyncExpectation.fulfill()
        }

        waitForExpectations(timeout: 5)
    }
}
