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
    static var annotationContainsSymbols: TagGroup = TagGroup(tags: ["tag": "value"], annotations: ["="])
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

    func testLowercasedAnnotation() throws {
        let tagGroup = TagGroup.annotationLowercased
        let parameters = try tagGroup.asParameters(for: .search())
        XCTAssertEqual(parameters, ["tag=value",
                                    "custom=valid"])
    }

    func testUppercasedAnnotation() throws {
        let tagGroup = TagGroup.annotationContainsUppercase
        let parameters = try tagGroup.asParameters(for: .search())
        XCTAssertEqual(parameters, ["tag=value",
                                    "custom=valid"])
    }

    func testEmptyAnnotation() throws {
        let tagGroup = TagGroup.annotationIsEmpty
        XCTAssertThrowsError(try tagGroup.asParameters(for: .search()), "should throw empty error") { (error) in
            XCTAssertEqual(error as? Data4LifeSDKError,
                           Data4LifeSDKError.emptyAnnotationNotAllowed)
        }
    }

    func testSymbolAnnotationSupportingLegacyTags() throws {
        let tagGroup = TagGroup.annotationContainsSymbols
        let parameters = try tagGroup.asParameters(for: .search())
        XCTAssertEqual(parameters, ["tag=value", "(custom=%3d,custom==,custom=%3D)"])
    }

    func testSymbolAnnotationNonSupportingLegacyTags() throws {
        let tagGroup = TagGroup.annotationContainsSymbols
        let parameters = try tagGroup.asParameters(for: .search(supportingLegacyTags: false))
        XCTAssertEqual(parameters, ["tag=value", "custom=%3d"])
    }

    func testMixedAnnotationNonSupportingLegacyTags() throws {
        let tagGroup = TagGroup.annotationMixedValid
        let parameters = try tagGroup.asParameters(for: .search(supportingLegacyTags: false))
        XCTAssertEqual(parameters, ["tag=value","custom=valid%20%2d%2d%2d%3d%3d%25%25123%2e321%25%25%3d%3d%2d%2d%2d%20valid"])
    }

    func testMixedAnnotationsSupportingLegacyTags() throws {
        let tagGroup = TagGroup.annotationMixedValid
        let parameters = try tagGroup.asParameters(for: .search())
        XCTAssertEqual(parameters, ["tag=value",
                                    "(custom=valid%20%2d%2d%2d%3d%3d%25%25123%2e321%25%25%3d%3d%2d%2d%2d%20valid,custom=valid ---==%%123.321%%==--- valid,custom=valid%20%2d%2d%2d%3D%3D%25%25123%2e321%25%25%3D%3D%2d%2d%2d%20valid)"])
    }

    func testSecondUppercasedAnnotation() throws {
        let tagGroup = TagGroup.secondAnnotationContainsUppercase
        let parameters = try tagGroup.asParameters(for: .search())
        XCTAssertEqual(parameters, ["tag=value", "custom=valid", "custom=valid"])
    }

    func testSecondEmptyAnnotation() throws {
        let tagGroup = TagGroup.secondAnnotationIsEmpty
        XCTAssertThrowsError(try tagGroup.asParameters(for: .search()), "should throw empty error") { (error) in
            XCTAssertEqual(error as? Data4LifeSDKError,
                           Data4LifeSDKError.emptyAnnotationNotAllowed)
        }
    }

    func testSecondSymbolAnnotationNotSupportingLegacyTags() throws {
        let tagGroup = TagGroup.secondAnnotationContainsSymbols
        let parameters = try tagGroup.asParameters(for: .search(supportingLegacyTags: false))
        XCTAssertEqual(parameters, ["tag=value", "custom=valid", "custom=%3d"])
    }

    func testSecondSymbolAnnotationSupportingLegacyTags() throws {
        let tagGroup = TagGroup.secondAnnotationContainsSymbols
        let parameters = try tagGroup.asParameters(for: .search())
        XCTAssertEqual(parameters, ["tag=value", "custom=valid", "(custom=%3d,custom==,custom=%3D)"])
    }

    func testTrimmedAnnotation() throws {
        let tagGroup = TagGroup.annotationTrimmedValid
        let parameters = try tagGroup.asParameters(for: .search())
        XCTAssertEqual(parameters, ["tag=value","custom=valid"])
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
