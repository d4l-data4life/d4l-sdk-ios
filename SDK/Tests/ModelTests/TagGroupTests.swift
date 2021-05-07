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

class TagGroupTests: XCTestCase {

    func testLowercasedAnnotationForSearchNotSupportingLegacyTags() throws {
        let tagGroup = TagGroup.annotationLowercased
        let parameters = try tagGroup.asTagsParameters(for: .search(supportingLegacyTags: false)).asTagExpressions
        XCTAssertEqual(parameters, ["tag=value", "custom=valid"])
    }

    func testLowercasedAnnotationForSearchSupportingLegacyTags() throws {
        let tagGroup = TagGroup.annotationLowercased
        let parameters = try tagGroup.asTagsParameters(for: .search()).asTagExpressions
        XCTAssertEqual(parameters, ["tag=value", "custom=valid"])
    }

    func testUppercasedAnnotationForSearchNotSupportingLegacyTags() throws {
        let tagGroup = TagGroup.annotationContainsUppercase
        let parameters = try tagGroup.asTagsParameters(for: .search(supportingLegacyTags: false)).asTagExpressions
        XCTAssertEqual(parameters, ["tag=value", "custom=valid"])
    }

    func testUppercasedAnnotationForSearchSupportingLegacyTags() throws {
        let tagGroup = TagGroup.annotationContainsUppercase
        let parameters = try tagGroup.asTagsParameters(for: .search()).asTagExpressions
        XCTAssertEqual(parameters, ["tag=value", "custom=valid"])
    }

    func testEncodableSymbolAnnotationForSearchNotSupportingLegacyTags() throws {
        let tagGroup = TagGroup.annotationContainsEncodableSymbols
        let parameters = try tagGroup.asTagsParameters(for: .search(supportingLegacyTags: false)).asTagExpressions
        XCTAssertEqual(parameters, ["tag=value", "custom=%3d"])
    }

    func testEncodableSymbolAnnotationForSearchSupportingLegacyTags() throws {
        let tagGroup = TagGroup.annotationContainsEncodableSymbols
        let parameters = try tagGroup.asTagsParameters(for: .search()).asTagExpressions
        XCTAssertEqual(parameters, ["tag=value", "(custom=%3d,custom==,custom=%3D)"])
    }

    func testJSCustomEncodableSymbolAnnotationForSearchNotSupportingLegacyTags() throws {
        let tagGroup = TagGroup.annotationContainsJSCustomEncodableSymbols
        let parameters = try tagGroup.asTagsParameters(for: .search(supportingLegacyTags: false)).asTagExpressions
        XCTAssertEqual(parameters, ["tag=value", "custom=%21%28%29%2e"])
    }

    func testJSCustomEncodableSymbolAnnotationForSearchSupportingLegacyTags() throws {
        let tagGroup = TagGroup.annotationContainsJSCustomEncodableSymbols
        let parameters = try tagGroup.asTagsParameters(for: .search()).asTagExpressions
        XCTAssertEqual(parameters, ["tag=value", "(custom=%21%28%29%2e,custom=!().)"])
    }

    func testMixedAnnotationForSearchNotSupportingLegacyTags() throws {
        let tagGroup = TagGroup.annotationMixedValid
        let parameters = try tagGroup.asTagsParameters(for: .search(supportingLegacyTags: false)).asTagExpressions
        XCTAssertEqual(parameters, ["tag=value","custom=valid%20%2d%2d%2d%3d%3d%25%25123%2e321%25%25%3d%3d%2d%2d%2d%20valid"])
    }

    func testMixedAnnotationsForSearchSupportingLegacyTags() throws {
        let tagGroup = TagGroup.annotationMixedValid
        let parameters = try tagGroup.asTagsParameters(for: .search()).asTagExpressions
        XCTAssertEqual(parameters, ["tag=value", // swiftlint:disable line_length
                                    "(custom=valid%20%2d%2d%2d%3d%3d%25%25123%2e321%25%25%3d%3d%2d%2d%2d%20valid,custom=valid ---==%%123.321%%==--- valid,custom=valid%20%2d%2d%2d%3D%3D%25%25123%2e321%25%25%3D%3D%2d%2d%2d%20valid)"])
    }

    func testSecondUppercasedAnnotationForSearchNotSupportingLegacyTags() throws {
        let tagGroup = TagGroup.secondAnnotationContainsUppercase
        let parameters = try tagGroup.asTagsParameters(for: .search(supportingLegacyTags: false)).asTagExpressions
        XCTAssertEqual(parameters, ["tag=value", "custom=valid", "custom=valid"])
    }

    func testSecondUppercasedAnnotationForSearchSupportingLegacyTags() throws {
        let tagGroup = TagGroup.secondAnnotationContainsUppercase
        let parameters = try tagGroup.asTagsParameters(for: .search()).asTagExpressions
        XCTAssertEqual(parameters, ["tag=value", "custom=valid", "custom=valid"])
    }

    func testSecondSymbolAnnotationForSearchNotSupportingLegacyTags() throws {
        let tagGroup = TagGroup.secondAnnotationContainsSymbols
        let parameters = try tagGroup.asTagsParameters(for: .search(supportingLegacyTags: false)).asTagExpressions
        XCTAssertEqual(parameters, ["tag=value", "custom=valid", "custom=%3d"])
    }

    func testSecondSymbolAnnotationForSearchSupportingLegacyTags() throws {
        let tagGroup = TagGroup.secondAnnotationContainsSymbols
        let parameters = try tagGroup.asTagsParameters(for: .search()).asTagExpressions
        XCTAssertEqual(parameters, ["tag=value", "custom=valid", "(custom=%3d,custom==,custom=%3D)"])
    }

    func testTrimmedAnnotationForSearchNotSupportingLegacyTags() throws {
        let tagGroup = TagGroup.annotationTrimmedValid
        let parameters = try tagGroup.asTagsParameters(for: .search(supportingLegacyTags: false)).asTagExpressions
        XCTAssertEqual(parameters, ["tag=value","custom=valid"])
    }

    func testTrimmedAnnotationForSearchSupportingLegacyTags() throws {
        let tagGroup = TagGroup.annotationTrimmedValid
        let parameters = try tagGroup.asTagsParameters(for: .search()).asTagExpressions
        XCTAssertEqual(parameters, ["tag=value","custom=valid"])
    }
}

extension TagGroupTests {

    func testLowercasedAnnotationForUpload() throws {
        let tagGroup = TagGroup.annotationLowercased
        let parameters = try tagGroup.asTagsParameters(for: .upload).asTagExpressions
        XCTAssertEqual(parameters, ["tag=value", "custom=valid"])
    }

    func testUppercasedAnnotationForUpload() throws {
        let tagGroup = TagGroup.annotationContainsUppercase
        let parameters = try tagGroup.asTagsParameters(for: .upload).asTagExpressions
        XCTAssertEqual(parameters, ["tag=value", "custom=valid"])
    }

    func testEncodableSymbolAnnotationForUpload() throws {
        let tagGroup = TagGroup.annotationContainsEncodableSymbols
        let parameters = try tagGroup.asTagsParameters(for: .upload).asTagExpressions
        XCTAssertEqual(parameters, ["tag=value", "custom=%3d"])
    }

    func testJSCustomEncodableSymbolAnnotationForUpload() throws {
        let tagGroup = TagGroup.annotationContainsJSCustomEncodableSymbols
        let parameters = try tagGroup.asTagsParameters(for: .upload).asTagExpressions
        XCTAssertEqual(parameters, ["tag=value", "custom=%21%28%29%2e"])
    }

    func testMixedAnnotationsForUpload() throws {
        let tagGroup = TagGroup.annotationMixedValid
        let parameters = try tagGroup.asTagsParameters(for: .upload).asTagExpressions
        XCTAssertEqual(parameters, ["tag=value", 
                                    "custom=valid%20%2d%2d%2d%3d%3d%25%25123%2e321%25%25%3d%3d%2d%2d%2d%20valid"])
    }

    func testSecondUppercasedAnnotationForUpload() throws {
        let tagGroup = TagGroup.secondAnnotationContainsUppercase
        let parameters = try tagGroup.asTagsParameters(for: .upload).asTagExpressions
        XCTAssertEqual(parameters, ["tag=value", "custom=valid", "custom=valid"])
    }

    func testSecondSymbolAnnotationForUpload() throws {
        let tagGroup = TagGroup.secondAnnotationContainsSymbols
        let parameters = try tagGroup.asTagsParameters(for: .upload).asTagExpressions
        XCTAssertEqual(parameters, ["tag=value", "custom=valid", "custom=%3d"])
    }

    func testTrimmedAnnotationForUpload() throws {
        let tagGroup = TagGroup.annotationTrimmedValid
        let parameters = try tagGroup.asTagsParameters(for: .upload).asTagExpressions
        XCTAssertEqual(parameters, ["tag=value","custom=valid"])
    }
}

extension TagGroupTests {
    func testEmptyAnnotationErrorGetsCalledForSearchSupportingLegacyTags() throws {
        let tagGroup = TagGroup.annotationIsEmpty
        XCTAssertThrowsError(try tagGroup.asTagsParameters(for: .search()), "should throw empty error") { (error) in
            XCTAssertEqual(error as? Data4LifeSDKError,
                           Data4LifeSDKError.emptyAnnotationNotAllowed)
        }
    }

    func testEmptyAnnotationErrorGetsCalledForSearchNotSupportingLegacyTags() throws {
        let tagGroup = TagGroup.annotationIsEmpty
        XCTAssertThrowsError(try tagGroup.asTagsParameters(for: .search(supportingLegacyTags: false)), "should throw empty error") { (error) in
            XCTAssertEqual(error as? Data4LifeSDKError,
                           Data4LifeSDKError.emptyAnnotationNotAllowed)
        }
    }

    func testEmptyAnnotationErrorGetsCalledForUpload() throws {
        let tagGroup = TagGroup.annotationIsEmpty
        XCTAssertThrowsError(try tagGroup.asTagsParameters(for: .upload), "should throw empty error") { (error) in
            XCTAssertEqual(error as? Data4LifeSDKError,
                           Data4LifeSDKError.emptyAnnotationNotAllowed)
        }
    }

    func testSecondEmptyAnnotationErrorGetsCalledForSearchSupportingLegacyTags() throws {
        let tagGroup = TagGroup.secondAnnotationIsEmpty
        XCTAssertThrowsError(try tagGroup.asTagsParameters(for: .search()), "should throw empty error") { (error) in
            XCTAssertEqual(error as? Data4LifeSDKError,
                           Data4LifeSDKError.emptyAnnotationNotAllowed)
        }
    }

    func testSecondEmptyAnnotationErrorGetsCalledForSearchNotSupportingLegacyTags() throws {
        let tagGroup = TagGroup.secondAnnotationIsEmpty
        XCTAssertThrowsError(try tagGroup.asTagsParameters(for: .search(supportingLegacyTags: false)), "should throw empty error") { (error) in
            XCTAssertEqual(error as? Data4LifeSDKError,
                           Data4LifeSDKError.emptyAnnotationNotAllowed)
        }
    }

    func testSecondEmptyAnnotationErrorGetsCalledForUpload() throws {
        let tagGroup = TagGroup.secondAnnotationIsEmpty
        XCTAssertThrowsError(try tagGroup.asTagsParameters(for: .upload), "should throw empty error") { (error) in
            XCTAssertEqual(error as? Data4LifeSDKError,
                           Data4LifeSDKError.emptyAnnotationNotAllowed)
        }
    }
}

extension TagGroupTests {

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
