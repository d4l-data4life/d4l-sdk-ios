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

class TaskTests: XCTestCase {
    private var task: Task!
    private var progress: Progress!

    override func setUp() {
        super.setUp()

        let progress = Progress(totalUnitCount: 3)
        self.progress = progress
        self.task = Task(progress)
    }

    func testInitializeTask() {
        XCTAssertEqual(task.isActive, true, "Task should be active")
    }

    func testCancel() {
        XCTAssertEqual(task.isActive, true, "Task should be active")
        task.cancel()
        XCTAssertEqual(task.isActive, false, "Task should be not active")
    }

    func testOnFractionCompleted() {
        let asyncExpectation = expectation(description: "Should return onFractionCompleted closure")

        task.observeFractionCompleted { _ in
             asyncExpectation.fulfill()
        }

        progress.becomeCurrent(withPendingUnitCount: 3)
        progress.resignCurrent()
        wait(for: [asyncExpectation], timeout: 5)
    }

    func testIsNotActive() {
        let asyncExpectation = expectation(description: "Task should be inactive after completion")

        task.observeFractionCompleted { [unowned self] _ in
            XCTAssertFalse(self.task.isActive)
            asyncExpectation.fulfill()
        }

        progress.becomeCurrent(withPendingUnitCount: 3)
        progress.resignCurrent()
        wait(for: [asyncExpectation], timeout: 5)
    }
}
