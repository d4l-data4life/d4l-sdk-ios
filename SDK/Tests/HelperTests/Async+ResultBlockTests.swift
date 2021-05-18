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

class AsyncResultBlockTests: XCTestCase {

    func testComplete() {
        let value = 1

        let asyncSuccessExpectation = expectation(description: "should call with success")
        Just(value).complete({ result in
            defer { asyncSuccessExpectation.fulfill() }
            XCTAssertNotNil(result.value)
            XCTAssertEqual(result.value, value)
        }, finally: nil)

        waitForExpectations(timeout: 5)

        let asyncFailureExpectation = expectation(description: "should call with failure")

        Async<Any>.reject().complete({ result in
            defer { asyncFailureExpectation.fulfill() }
            XCTAssertNil(result.value)
        }, finally: nil)

        waitForExpectations(timeout: 5)
    }

    func testCompleteWithFinally() {
        let asyncCompleteExpectation = expectation(description: "should call before finally")
        let asyncFinallyExpectation = expectation(description: "should call after complete")
        var didCallComplete = false

        let completeBlock: (Result<Void, Error>) -> Void = { _ in
            XCTAssertFalse(didCallComplete)
            asyncCompleteExpectation.fulfill()
            didCallComplete = true
        }

        let finallyBlock: () -> Void = {
            XCTAssertTrue(didCallComplete)
            asyncFinallyExpectation.fulfill()
        }

        Async<Void>.resolve().complete(completeBlock, finally: finallyBlock)
        wait(for: [asyncCompleteExpectation, asyncFinallyExpectation], timeout: 2)
    }
}
