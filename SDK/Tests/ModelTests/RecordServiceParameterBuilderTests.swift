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
    private lazy var decryptedRecord = DecryptedRecordFactory.create(resource, annotations: [], dataKey: dataKey, attachmentKey: nil)
    private lazy var encryptedRecord = encryptedRecordFactory.create(for: decryptedRecord, commonKeyId: commonKeyIdentifier)

    override func setUp() {
        super.setUp()
        let container = Data4LifeDITestContainer()
        container.registerDependencies()

        builder = try! container.resolve()
        cryptoService = try! container.resolve(as: CryptoServiceType.self)
        encryptedRecordFactory = try! container.resolve()

        cryptoService.encryptValueResult = Async(encryptedRecord.data)
        cryptoService.tagEncryptionKey = KeyFactory.createKey(.tag)
        let dataInput: (Data, Data) = (encryptedRecord.encryptedDataKeyData, encryptedRecord.encryptedDataKeyData)
        let bodyInput: (Data, Data) = (encryptedRecord.encryptedBodyData, encryptedRecord.encryptedBodyData)
        cryptoService.generateGCKeyResult = decryptedRecord.dataKey
        cryptoService.encryptDataForInput = [dataInput, bodyInput]
        cryptoService.decryptDataForInput = [dataInput, bodyInput]
    }
}

// Search, Not Supporting Legacy Tags
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

extension RecordServiceParameterBuilderTests {
    func testEncodableSymbolAnnotationForSearchSupportingLegacyTags() throws {
        let tagGroup = TagGroup.annotationContainsEncodableSymbols
        let parameters = try builder.searchParameters(tagGroup: tagGroup)
        XCTAssertEqual(parameters["tags"] as? String, "tag=value,(custom=%3d,custom==,custom=%3D)")
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
        XCTAssertEqual(parameters["tags"] as? String, "tag=value,(custom=%21%28%29%2e,custom=!().)")
    }

    func testMixedAnnotationsForSearchSupportingLegacyTags() throws {
        let tagGroup = TagGroup.annotationMixedValid
        let parameters = try builder.searchParameters(tagGroup: tagGroup)
        XCTAssertEqual(parameters["tags"] as? String,
                       "tag=value,(custom=valid%20%2d%2d%2d%3d%3d%25%25123%2e321%25%25%3d%3d%2d%2d%2d%20valid,custom=valid ---==%%123.321%%==--- valid,custom=valid%20%2d%2d%2d%3D%3D%25%25123%2e321%25%25%3D%3D%2d%2d%2d%20valid)")
    }
    func testSecondUppercasedAnnotationForSearchSupportingLegacyTags() throws {
        let tagGroup = TagGroup.secondAnnotationContainsUppercase
        let parameters = try builder.searchParameters(tagGroup: tagGroup)
        XCTAssertEqual(parameters["tags"] as? String, "tag=value,custom=valid,custom=valid")
    }
    func testSecondSymbolAnnotationForSearchSupportingLegacyTags() throws {
        let tagGroup = TagGroup.secondAnnotationContainsSymbols
        let parameters = try builder.searchParameters(tagGroup: tagGroup)
        XCTAssertEqual(parameters["tags"] as? String, "tag=value,custom=valid,(custom=%3d,custom==,custom=%3D)")
    }

    func testTrimmedAnnotationForSearchSupportingLegacyTags() throws {
        let tagGroup = TagGroup.annotationTrimmedValid
        let parameters = try builder.searchParameters(tagGroup: tagGroup)
        XCTAssertEqual(parameters["tags"] as? String, "tag=value,custom=valid")
    }
}

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

extension RecordServiceParameterBuilderTests {
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
