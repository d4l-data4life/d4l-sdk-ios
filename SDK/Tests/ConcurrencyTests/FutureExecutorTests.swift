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

class FutureExecutorTests: XCTestCase {
    enum Error: Swift.Error {
        case first
        case second
    }
}

// MARK: - No Error cases
extension FutureExecutorTests {

    func testAsyncFinishesOnCreation() {
        var originalCounter = 0
        XCTAssertEqual(originalCounter, 0)
        let runningExpectation = expectation(description: "future runs on creation")
        combineAsync { () -> Int in
            originalCounter += 1
            XCTAssertEqual(originalCounter, 1)
            runningExpectation.fulfill()
            return originalCounter
        }

        waitForExpectations(timeout: 5)
    }

    func testAwaitOneFuture() {

        var originalCounter = 0
        XCTAssertEqual(originalCounter, 0)
        let future = combineAsync { () -> Int in
            XCTAssertEqual(originalCounter, 0)
            originalCounter += 1
            XCTAssertEqual(originalCounter, 1)
            return originalCounter
        }

        let newCounter = combineAwait(future)
        XCTAssertEqual(newCounter, 1)
    }

    func testAwaitTwoFuturesAtTheEnd() {

        var originalCounter = 0
        XCTAssertEqual(originalCounter, 0)
        let futureOne = combineAsync { () -> Int in
            originalCounter += 1
            return originalCounter
        }

        let futureTwo = combineAsync { () -> Int in
            originalCounter += 2
            return originalCounter
        }

        _ = combineAwait(futureOne)
        let lastCounter = combineAwait(futureTwo)
        XCTAssertEqual(lastCounter, 3)
    }

    func testAwaitTwoFuturesSynchronously() {

        var originalCounter = 0
        XCTAssertEqual(originalCounter, 0)
        let futureOne = combineAsync { () -> Int in
            originalCounter += 1
            return originalCounter
        }

        let newCounter = combineAwait(futureOne)
        XCTAssertEqual(newCounter, 1)

        let futureTwo = combineAsync { () -> Int in
            originalCounter += 2
            return originalCounter
        }

        let lastCounter = combineAwait(futureTwo)
        XCTAssertEqual(lastCounter, 3)
    }

    func testCompleteAndFinally() {

        let expectationOne = expectation(description: "completed is called")
        let expectationTwo = expectation(description: "finally is called")

        var originalCounter = 0
        XCTAssertEqual(originalCounter, 0)

        let future = combineAsync { () -> Int in
            originalCounter += 1
            return originalCounter
        }.map { number -> String in
            return String(number)
        }

        future.complete { result in
            XCTAssertEqual(result.value, "1")
            expectationOne.fulfill()
            originalCounter += 1
        } finally: {
            XCTAssertEqual(originalCounter, 2)
            expectationTwo.fulfill()
        }

        waitForExpectations(timeout: 5)
    }

    func testCompleteCancellation() {

        let counterExpectation = expectation(description: "Counter was only changed from first part of future")
        let queue = DispatchQueue(label: "test")
        var originalCounter = 0

        let future = combineAsync { () -> Int in
            originalCounter += 1
            return originalCounter
        }
        .delay(for: 0.5, scheduler: queue)
        .map { number -> String in
            originalCounter += 1
            return "\(number)"
        }

        let cancellable = future.complete { _ in
            originalCounter += 1
        } finally: {
            originalCounter += 1
        }

        cancelTask(cancellable)
        queue.asyncAfter(deadline: DispatchTime.now().advanced(by: DispatchTimeInterval.milliseconds(100))) {
            XCTAssertEqual(originalCounter, 1)
            counterExpectation.fulfill()
        }
        waitForExpectations(timeout: 5)
    }

    func testAsyncFutureSuccessPath() throws {

        let futureOne = combineAsync { () -> Int in
            return 2
        }

        let futureTwo = combineAsync { () -> Int in
            return 4
        }

        let concatenatedFuture = Publishers.Concatenate(prefix: futureOne, suffix: futureTwo).collect().asyncFuture()
        let result = combineAwait(concatenatedFuture)
        XCTAssertEqual(result, [2,4])
    }
}

// MARK: - Error cases
extension FutureExecutorTests {
    func testAwaitErroredFuture() throws {

        let future: SDKFuture<Int> = combineAsync { () -> Int in
            throw Error.first
        }

        XCTAssertThrowsError(try combineAwait(future))
    }

    func testAwaitTwoConcatenatedErroredFuturesAtTheEnd() throws {

        let futureOne: SDKFuture<Int> = combineAsync { () -> Int in
            throw Error.first
        }

        let futureTwo: SDKFuture<Int> = combineAsync { () -> Int in
            throw Error.second
        }

        let concatenatedFuture = Publishers.Concatenate(prefix: futureOne, suffix: futureTwo).collect().asyncFuture()
        XCTAssertThrowsError(try combineAwait(concatenatedFuture), "should throw first error", { error in
            XCTAssertEqual(error as? FutureExecutorTests.Error, FutureExecutorTests.Error.first)
        })
    }
}
