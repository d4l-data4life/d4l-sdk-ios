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
    static var annotationContainsUppercase: TagGroup = TagGroup(tags: ["tag": "value"], annotations: ["invAlid"])
    static var annotationIsEmpty: TagGroup = TagGroup(tags: ["tag": "value"], annotations: [""])
    static var annotationContainsSymbols: TagGroup = TagGroup(tags: ["tag": "value"], annotations: ["="])
    static var secondAnnotationContainsUppercase: TagGroup = TagGroup(tags: ["tag": "value"], annotations: ["valid", "invAlid"])
    static var secondAnnotationIsEmpty: TagGroup = TagGroup(tags: ["tag": "value"], annotations: ["valid", ""])
    static var secondAnnotationContainsSymbols: TagGroup = TagGroup(tags: ["tag": "value"], annotations: ["valid","="])
    static var annotationMixedValid: TagGroup = TagGroup(tags: ["tag": "value"], annotations: ["valid ---==%%123.321%%==--- valid"])
}

class TagGroupTests: XCTestCase {

    func testLowercasedAnnotation() throws {
        let tagGroup = TagGroup.annotationLowercased
        let parameters = try tagGroup.asParameters()
        XCTAssertEqual(parameters, ["tag=value","custom=valid"])
    }

    func testUppercasedAnnotation() throws {
        let tagGroup = TagGroup.annotationContainsUppercase
        XCTAssertThrowsError(try tagGroup.asParameters(), "should throw upperCase error") { (error) in
            XCTAssertEqual(error as? Data4LifeSDKError,
                           Data4LifeSDKError.upperCasedAnnotationNotAllowed)
        }
    }

    func testEmptyAnnotation() throws {
        let tagGroup = TagGroup.annotationIsEmpty
        XCTAssertThrowsError(try tagGroup.asParameters(), "should throw empty error") { (error) in
            XCTAssertEqual(error as? Data4LifeSDKError,
                           Data4LifeSDKError.emptyAnnotationNotAllowed)
        }
    }

    func testSymbolAnnotation() throws {
        let tagGroup = TagGroup.annotationContainsSymbols
        let parameters = try tagGroup.asParameters()
        XCTAssertEqual(parameters, ["tag=value", "custom=%3d"])
    }

    func testMixedAnnotation() throws {
        let tagGroup = TagGroup.annotationMixedValid
        let parameters = try tagGroup.asParameters()
        XCTAssertEqual(parameters, ["tag=value","custom=valid%20%2d%2d%2d%3d%3d%25%25123%2e321%25%25%3d%3d%2d%2d%2d%20valid"])
    }

    func testSecondUppercasedAnnotation() throws {
        let tagGroup = TagGroup.secondAnnotationContainsUppercase
        XCTAssertThrowsError(try tagGroup.asParameters(), "should throw upperCase error") { (error) in
            XCTAssertEqual(error as? Data4LifeSDKError,
                           Data4LifeSDKError.upperCasedAnnotationNotAllowed)
        }
    }

    func testSecondEmptyAnnotation() throws {
        let tagGroup = TagGroup.secondAnnotationIsEmpty
        XCTAssertThrowsError(try tagGroup.asParameters(), "should throw empty error") { (error) in
            XCTAssertEqual(error as? Data4LifeSDKError,
                           Data4LifeSDKError.emptyAnnotationNotAllowed)
        }
    }

    func testSecondSymbolAnnotation() throws {
        let tagGroup = TagGroup.secondAnnotationContainsSymbols
        let parameters = try tagGroup.asParameters()
        XCTAssertEqual(parameters, ["tag=value", "custom=valid", "custom=%3d"])
    }
}

extension TagGroupTests {

    func testLowercasedAnnotationInit() throws {
        let tagGroup = TagGroup(from: ["tag=value","custom=valid"])
        XCTAssertEqual(tagGroup, TagGroup.annotationLowercased)
    }

    func testMixedValidAnnotationInit() throws {
        let tagGroup = TagGroup(from: ["tag=value","custom=valid%20%2d%2d%2d%3d%3d%25%25123%2e321%25%25%3d%3d%2d%2d%2d%20valid"])
        XCTAssertEqual(tagGroup, TagGroup.annotationMixedValid)
    }
}
