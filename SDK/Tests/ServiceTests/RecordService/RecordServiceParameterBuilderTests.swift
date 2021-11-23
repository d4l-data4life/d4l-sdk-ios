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
import Data4LifeFHIR

fileprivate extension TagGroup {
    static var annotationLowercased: TagGroup = TagGroup(tags: ["tag": "value"], annotations: ["valid"])
    static var annotationContainsUppercase: TagGroup = TagGroup(tags: ["tag": "value"], annotations: ["vAlid"])
    static var annotationIsEmpty: TagGroup = TagGroup(tags: ["tag": "value"], annotations: [""])
    static var annotationContainsEncodableSymbols: TagGroup = TagGroup(tags: ["tag": "value"], annotations: ["="])
    static var annotationContainsJSCustomEncodableSymbols: TagGroup = TagGroup(tags: ["tag": "value"], annotations: ["!()."])
    static var annotationTrimmedValid: TagGroup = TagGroup(tags: ["tag": "value"], annotations: [" valid "])
    static var annotationMixedValid: TagGroup = TagGroup(tags: ["tag": "value"], annotations: [" vALid ---==%%123.321%%==--- valiD "])

    static var secondAnnotationContainsUppercase: TagGroup = TagGroup(tags: ["tag": "value"], annotations: ["valid", "vAlid"])
    static var secondAnnotationIsEmpty: TagGroup = TagGroup(tags: ["tag": "value"], annotations: ["valid", ""])
    static var secondAnnotationContainsSymbols: TagGroup = TagGroup(tags: ["tag": "value"], annotations: ["valid","="])

    var normalized: TagGroup {
        let tags = self.tags.map { ( $0.key.lowercased().trimmingCharacters(in: .whitespacesAndNewlines), $0.value.lowercased().trimmingCharacters(in: .whitespacesAndNewlines))}
        let annotations = self.annotations.map { $0.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)}
        return TagGroup(tags: Dictionary(uniqueKeysWithValues: tags), annotations: annotations)
    }
}

final class RecordServiceParameterBuilderTests: XCTestCase {

    private var cryptoService: CryptoServiceMock!
    private var builder: RecordServiceParameterBuilder!
    private var encryptedRecordFactory: EncryptedRecordFactory!

    private let resource = Patient()
    private let commonKey = KeyFactory.createKey(.common)
    private let commonKeyIdentifier = UUID().uuidString
    private let dataKey = KeyFactory.createKey(.data)
    private lazy var decryptedRecord = DecryptedRecordFactory.create(resource, annotations: [], dataKey: dataKey, attachmentKey: dataKey)
    private lazy var encryptedRecord = encryptedRecordFactory.create(for: decryptedRecord, commonKeyId: commonKeyIdentifier)

    override func setUp() {
        super.setUp()
        let container = Data4LifeDITestContainer()
        container.registerDependencies()

        builder = try! container.resolve()
        cryptoService = try! container.resolve(as: CryptoServiceType.self)
        encryptedRecordFactory = try! container.resolve()

        cryptoService.encryptValueResult = Just(encryptedRecord.data).asyncFuture()
        cryptoService.tagEncryptionKey = KeyFactory.createKey(.tag)
        let dataInput: (Data, Data) = (encryptedRecord.encryptedDataKeyData, encryptedRecord.encryptedDataKeyData)
        let bodyInput: (Data, Data) = (encryptedRecord.encryptedBodyData, encryptedRecord.encryptedBodyData)
        cryptoService.generateGCKeyResult = decryptedRecord.dataKey
        cryptoService.encryptDataForInput = [dataInput, bodyInput]
        cryptoService.decryptDataForInput = [dataInput, bodyInput]
    }
}

// MARK: - All Parameter Tests
extension RecordServiceParameterBuilderTests {
    func testAllSearchParameters() throws {
        let toDate = Calendar.current.date(from: DateComponents(year: 1983, month: 1, day: 11))!
        let fromDate = Calendar.current.date(byAdding: DateComponents(day: -1), to: toDate)!
        let tagGroup = TagGroup.annotationLowercased
        let query = SearchQueryFactory.create(limit: 20, offset: 1, startDate: fromDate, endDate: toDate, tagGroup: tagGroup)
        let parameters = try builder.searchParameters(query: query,
                                                      supportingLegacyTags: false)
        XCTAssertEqual(parameters["tags"] as? String, "tag=value,custom=valid")
        XCTAssertEqual(parameters["start_date"] as? String, "1983-01-10")
        XCTAssertEqual(parameters["end_date"] as? String, "1983-01-11")
        XCTAssertEqual(parameters["offset"] as? Int, 1)
        XCTAssertEqual(parameters["limit"] as? Int, 20)
    }

    func testAllUploadParameters() throws {
        let tagGroup = TagGroup.annotationLowercased
        let uploadDate = Calendar.current.date(from: DateComponents(year: 1983, month: 1, day: 10))!
        let parameters = try builder.uploadParameters(resource: resource,
                                                      uploadDate: uploadDate,
                                                      commonKey: commonKey,
                                                      commonKeyIdentifier: commonKeyIdentifier,
                                                      dataKey: dataKey,
                                                      attachmentKey: dataKey,
                                                      tagGroup: tagGroup)
        XCTAssertEqual(parameters["encrypted_tags"] as? [String], ["tag=value","custom=valid"])
        XCTAssertEqual(parameters["encrypted_body"] as? String, encryptedRecord.encryptedBodyData.base64EncodedString())
        XCTAssertEqual(parameters["date"] as? String, "1983-01-10")
        XCTAssertEqual(parameters["attachment_key"] as? String, encryptedRecord.encryptedAttachmentKey)
        XCTAssertEqual(parameters["encrypted_key"] as? String, encryptedRecord.encryptedDataKey)
        XCTAssertEqual(parameters["model_version"] as? Int, Patient.modelVersion)
        XCTAssertEqual(parameters["common_key_id"] as? String, commonKeyIdentifier)
    }
}

// MARK: - Tags Tests, Search, Not Supporting Legacy Tags
extension RecordServiceParameterBuilderTests {
    func testLowercasedAnnotationForSearchNotSupportingLegacyTags() throws {
        let tagGroup = TagGroup.annotationLowercased
        let parameters = try builder.searchParameters(tagGroup: tagGroup, supportingLegacyTags: false)
        XCTAssertEqual(parameters["tags"] as? String, "tag=value,custom=valid")
    }

    func testUppercasedAnnotationForSearchNotSupportingLegacyTags() throws {
        let tagGroup = TagGroup.annotationContainsUppercase
        let parameters = try builder.searchParameters(tagGroup: tagGroup, supportingLegacyTags: false)
        XCTAssertEqual(parameters["tags"] as? String, "tag=value,custom=valid")
    }

    func testEncodableSymbolAnnotationForSearchNotSupportingLegacyTags() throws {
        let tagGroup = TagGroup.annotationContainsEncodableSymbols
        let parameters = try builder.searchParameters(tagGroup: tagGroup, supportingLegacyTags: false)
        XCTAssertEqual(parameters["tags"] as? String, "tag=value,custom=%3d")
    }

    func testJSCustomEncodableSymbolAnnotationForSearchNotSupportingLegacyTags() throws {
        let tagGroup = TagGroup.annotationContainsJSCustomEncodableSymbols
        let parameters = try builder.searchParameters(tagGroup: tagGroup, supportingLegacyTags: false)
        XCTAssertEqual(parameters["tags"] as? String, "tag=value,custom=%21%28%29%2e")
    }

    func testMixedAnnotationForSearchNotSupportingLegacyTags() throws {
        let tagGroup = TagGroup.annotationMixedValid
        let parameters = try builder.searchParameters(tagGroup: tagGroup, supportingLegacyTags: false)
        XCTAssertEqual(parameters["tags"] as? String, "tag=value,custom=valid%20%2d%2d%2d%3d%3d%25%25123%2e321%25%25%3d%3d%2d%2d%2d%20valid")
    }

    func testSecondUppercasedAnnotationForSearchNotSupportingLegacyTags() throws {
        let tagGroup = TagGroup.secondAnnotationContainsUppercase
        let parameters = try builder.searchParameters(tagGroup: tagGroup, supportingLegacyTags: false)
        XCTAssertEqual(parameters["tags"] as? String, "tag=value,custom=valid,custom=valid")
    }

    func testSecondSymbolAnnotationForSearchNotSupportingLegacyTags() throws {
        let tagGroup = TagGroup.secondAnnotationContainsSymbols
        let parameters = try builder.searchParameters(tagGroup: tagGroup, supportingLegacyTags: false)
        XCTAssertEqual(parameters["tags"] as? String, "tag=value,custom=valid,custom=%3d")
    }

    func testTrimmedAnnotationForSearchNotSupportingLegacyTags() throws {
        let tagGroup = TagGroup.annotationTrimmedValid
        let parameters = try builder.searchParameters(tagGroup: tagGroup, supportingLegacyTags: false)
        XCTAssertEqual(parameters["tags"] as? String, "tag=value,custom=valid")
    }
}

// MARK: - Tags Tests, Search, Supporting Legacy Tags
extension RecordServiceParameterBuilderTests {
    func testEncodableSymbolAnnotationForSearchSupportingLegacyTags() throws {
        let tagGroup = TagGroup.annotationContainsEncodableSymbols
        let parameters = try builder.searchParameters(tagGroup: tagGroup)
        XCTAssertEqual(parameters["tags"] as? String, "tag=value,(custom=%3d,custom=%3D,custom==)")
    }

    func testLowercasedAnnotationForSearchSupportingLegacyTags() throws {
        let tagGroup = TagGroup.annotationLowercased
        let parameters = try builder.searchParameters(tagGroup: tagGroup)
        XCTAssertEqual(parameters["tags"] as? String, "tag=value,custom=valid")
    }

    func testUppercasedAnnotationForSearchSupportingLegacyTags() throws {
        let tagGroup = TagGroup.annotationContainsUppercase
        let parameters = try builder.searchParameters(tagGroup: tagGroup)
        XCTAssertEqual(parameters["tags"] as? String, "tag=value,custom=valid")
    }
    func testJSCustomEncodableSymbolAnnotationForSearchSupportingLegacyTags() throws {
        let tagGroup = TagGroup.annotationContainsJSCustomEncodableSymbols
        let parameters = try builder.searchParameters(tagGroup: tagGroup)
        XCTAssertEqual(parameters["tags"] as? String, "tag=value,(custom=%21%28%29%2e,custom=%21%28%29%2E,custom=!().)")
    }

    func testMixedAnnotationsForSearchSupportingLegacyTags() throws {
        let tagGroup = TagGroup.annotationMixedValid
        let parameters = try builder.searchParameters(tagGroup: tagGroup)
        XCTAssertEqual(parameters["tags"] as? String, // swiftlint:disable line_length
                       "tag=value,(custom=valid%20%2d%2d%2d%3d%3d%25%25123%2e321%25%25%3d%3d%2d%2d%2d%20valid,custom=valid%20%2D%2D%2D%3D%3D%25%25123%2E321%25%25%3D%3D%2D%2D%2D%20valid,custom=valid ---==%%123.321%%==--- valid,custom=valid%20%2d%2d%2d%3D%3D%25%25123%2e321%25%25%3D%3D%2d%2d%2d%20valid)")
    }
    func testSecondUppercasedAnnotationForSearchSupportingLegacyTags() throws {
        let tagGroup = TagGroup.secondAnnotationContainsUppercase
        let parameters = try builder.searchParameters(tagGroup: tagGroup)
        XCTAssertEqual(parameters["tags"] as? String, "tag=value,custom=valid,custom=valid")
    }
    func testSecondSymbolAnnotationForSearchSupportingLegacyTags() throws {
        let tagGroup = TagGroup.secondAnnotationContainsSymbols
        let parameters = try builder.searchParameters(tagGroup: tagGroup)
        XCTAssertEqual(parameters["tags"] as? String, "tag=value,custom=valid,(custom=%3d,custom=%3D,custom==)")
    }

    func testTrimmedAnnotationForSearchSupportingLegacyTags() throws {
        let tagGroup = TagGroup.annotationTrimmedValid
        let parameters = try builder.searchParameters(tagGroup: tagGroup)
        XCTAssertEqual(parameters["tags"] as? String, "tag=value,custom=valid")
    }
}

// MARK: - Tags Tests, Upload
extension RecordServiceParameterBuilderTests {

    func testLowercasedAnnotationForUpload() throws {

        let tagGroup = TagGroup.annotationLowercased
        let parameters = try builder.uploadParameters(resource: resource,
                                                      commonKey: commonKey,
                                                      commonKeyIdentifier: commonKeyIdentifier,
                                                      dataKey: dataKey,
                                                      attachmentKey: nil,
                                                      tagGroup: tagGroup)
        XCTAssertEqual(parameters["encrypted_tags"] as? [String], ["tag=value","custom=valid"])
    }

    func testUppercasedAnnotationForUpload() throws {
        let tagGroup = TagGroup.annotationContainsUppercase
        let parameters = try builder.uploadParameters(resource: resource,
                                                      commonKey: commonKey,
                                                      commonKeyIdentifier: commonKeyIdentifier,
                                                      dataKey: dataKey,
                                                      attachmentKey: nil,
                                                      tagGroup: tagGroup)
        XCTAssertEqual(parameters["encrypted_tags"] as? [String], ["tag=value","custom=valid"])
    }

    func testEncodableSymbolAnnotationForUpload() throws {
        let tagGroup = TagGroup.annotationContainsEncodableSymbols
        let parameters = try builder.uploadParameters(resource: resource,
                                                      commonKey: commonKey,
                                                      commonKeyIdentifier: commonKeyIdentifier,
                                                      dataKey: dataKey,
                                                      attachmentKey: nil,
                                                      tagGroup: tagGroup)
        XCTAssertEqual(parameters["encrypted_tags"] as? [String], ["tag=value","custom=%3d"])
    }

    func testJSCustomEncodableSymbolAnnotationForUpload() throws {
        let tagGroup = TagGroup.annotationContainsJSCustomEncodableSymbols
        let parameters = try builder.uploadParameters(resource: resource,
                                                      commonKey: commonKey,
                                                      commonKeyIdentifier: commonKeyIdentifier,
                                                      dataKey: dataKey,
                                                      attachmentKey: nil,
                                                      tagGroup: tagGroup)
        XCTAssertEqual(parameters["encrypted_tags"] as? [String], ["tag=value","custom=%21%28%29%2e"])
    }

    func testMixedAnnotationsForUpload() throws {
        let tagGroup = TagGroup.annotationMixedValid
        let parameters = try builder.uploadParameters(resource: resource,
                                                      commonKey: commonKey,
                                                      commonKeyIdentifier: commonKeyIdentifier,
                                                      dataKey: dataKey,
                                                      attachmentKey: nil,
                                                      tagGroup: tagGroup)
        XCTAssertEqual(parameters["encrypted_tags"] as? [String], ["tag=value","custom=valid%20%2d%2d%2d%3d%3d%25%25123%2e321%25%25%3d%3d%2d%2d%2d%20valid"])
    }

    func testSecondUppercasedAnnotationForUpload() throws {
        let tagGroup = TagGroup.secondAnnotationContainsUppercase
        let parameters = try builder.uploadParameters(resource: resource,
                                                      commonKey: commonKey,
                                                      commonKeyIdentifier: commonKeyIdentifier,
                                                      dataKey: dataKey,
                                                      attachmentKey: nil,
                                                      tagGroup: tagGroup)
        XCTAssertEqual(parameters["encrypted_tags"] as? [String], ["tag=value","custom=valid","custom=valid"])
    }

    func testSecondSymbolAnnotationForUpload() throws {
        let tagGroup = TagGroup.secondAnnotationContainsSymbols
        let parameters = try builder.uploadParameters(resource: resource,
                                                      commonKey: commonKey,
                                                      commonKeyIdentifier: commonKeyIdentifier,
                                                      dataKey: dataKey,
                                                      attachmentKey: nil,
                                                      tagGroup: tagGroup)
        XCTAssertEqual(parameters["encrypted_tags"] as? [String], ["tag=value","custom=valid","custom=%3d"])
    }

    func testTrimmedAnnotationForUpload() throws {
        let tagGroup = TagGroup.annotationTrimmedValid
        let parameters = try builder.uploadParameters(resource: resource,
                                                      commonKey: commonKey,
                                                      commonKeyIdentifier: commonKeyIdentifier,
                                                      dataKey: dataKey,
                                                      attachmentKey: nil,
                                                      tagGroup: tagGroup)
        XCTAssertEqual(parameters["encrypted_tags"] as? [String], ["tag=value","custom=valid"])
    }
}

// MARK: - Tags Tests, Thrown errors
extension RecordServiceParameterBuilderTests {

    func testTagEncryptionKeyMissing() throws {
        cryptoService.tagEncryptionKey = nil
        let tagGroup = TagGroup.annotationTrimmedValid
        XCTAssertThrowsError(try builder.searchParameters(tagGroup: tagGroup), "should throw tag encryption key missing error") { (error) in
            XCTAssertEqual(error as? Data4LifeSDKError,
                           Data4LifeSDKError.missingTagKey)
        }
    }

    func testEmptyAnnotationErrorGetsCalledForSearchSupportingLegacyTags() throws {
        let tagGroup = TagGroup.annotationIsEmpty
        XCTAssertThrowsError(try builder.searchParameters(tagGroup: tagGroup), "should throw empty error") { (error) in
            XCTAssertEqual(error as? Data4LifeSDKError,
                           Data4LifeSDKError.emptyAnnotationNotAllowed)
        }
    }

    func testEmptyAnnotationErrorGetsCalledForSearchNotSupportingLegacyTags() throws {
        let tagGroup = TagGroup.annotationIsEmpty
        XCTAssertThrowsError(try builder.searchParameters(tagGroup: tagGroup, supportingLegacyTags: false), "should throw empty error") { (error) in
            XCTAssertEqual(error as? Data4LifeSDKError,
                           Data4LifeSDKError.emptyAnnotationNotAllowed)
        }
    }

    func testEmptyAnnotationErrorGetsCalledForUpload() throws {
        let tagGroup = TagGroup.annotationIsEmpty
        XCTAssertThrowsError(try builder.uploadParameters(resource: resource,
                                                          commonKey: commonKey,
                                                          commonKeyIdentifier: commonKeyIdentifier,
                                                          dataKey: dataKey,
                                                          attachmentKey: nil,
                                                          tagGroup: tagGroup), "should throw empty error") { (error) in
            XCTAssertEqual(error as? Data4LifeSDKError,
                           Data4LifeSDKError.emptyAnnotationNotAllowed)
        }
    }

    func testSecondEmptyAnnotationErrorGetsCalledForSearchSupportingLegacyTags() throws {
        let tagGroup = TagGroup.secondAnnotationIsEmpty
        XCTAssertThrowsError(try builder.searchParameters(tagGroup: tagGroup), "should throw empty error") { (error) in
            XCTAssertEqual(error as? Data4LifeSDKError,
                           Data4LifeSDKError.emptyAnnotationNotAllowed)
        }
    }

    func testSecondEmptyAnnotationErrorGetsCalledForSearchNotSupportingLegacyTags() throws {
        let tagGroup = TagGroup.secondAnnotationIsEmpty
        XCTAssertThrowsError(try builder.searchParameters(tagGroup: tagGroup, supportingLegacyTags: false), "should throw empty error") { (error) in
            XCTAssertEqual(error as? Data4LifeSDKError,
                           Data4LifeSDKError.emptyAnnotationNotAllowed)
        }
    }

    func testSecondEmptyAnnotationErrorGetsCalledForUpload() throws {
        let tagGroup = TagGroup.secondAnnotationIsEmpty
        XCTAssertThrowsError(try builder.uploadParameters(resource: resource,
                                                          commonKey: commonKey,
                                                          commonKeyIdentifier: commonKeyIdentifier,
                                                          dataKey: dataKey,
                                                          attachmentKey: nil,
                                                          tagGroup: tagGroup), "should throw empty error") { (error) in
            XCTAssertEqual(error as? Data4LifeSDKError,
                           Data4LifeSDKError.emptyAnnotationNotAllowed)
        }
    }
}

// MARK: - Initializers
extension RecordServiceParameterBuilderTests {

    func testLowercasedAnnotationInit() throws {
        let tagGroup = TagGroup(from: ["tag=value",
                                       "custom=valid"])
        XCTAssertEqual(tagGroup, TagGroup.annotationLowercased)
    }

    func testMixedValidAnnotationInit() throws {
        let tagGroup = TagGroup(from: ["tag=value","custom=valid%20%2d%2d%2d%3d%3d%25%25123%2e321%25%25%3d%3d%2d%2d%2d%20valid"])
        XCTAssertEqual(tagGroup, TagGroup.annotationMixedValid.normalized)
    }
}
