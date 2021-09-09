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

final class LoggerServiceTests: XCTestCase {

    private var debugLogger: LoggerService!
    private var releaseLogger: LoggerService!
    private var currentBuildConfiguration: BuildConfiguration!

    override func setUp() {
        super.setUp()

        self.debugLogger = LoggerService(configuration: LoggerConfiguration.console,
                                         currentBuildConfiguration: .debug)
        self.debugLogger.isLoggingEnabled = true
        self.releaseLogger = LoggerService(configuration: LoggerConfiguration.console,
                                           currentBuildConfiguration: .release)
        releaseLogger.isLoggingEnabled = true
    }

    func testDoesDebugLoggingWorkInDebug() {
        currentBuildConfiguration = .debug
        let debugLogResult = debugLogger.logDebug("Hallo")
        let releaseLogResult = releaseLogger.logDebug("Hallo")
        XCTAssertEqual(debugLogResult, .didLog, "Debug Logging is being called")
        XCTAssertEqual(releaseLogResult, .didNotLog, "Release Logging is not being called")
    }

    func testDoesDebugLoggingNotWorkInRelease() {
        currentBuildConfiguration = .release
        let debugLogResult = debugLogger.logDebug("Hallo")
        let releaseLogResult = releaseLogger.logDebug("Hallo")
        XCTAssertEqual(releaseLogResult, .didNotLog, "Debug Logging is not being called")
        XCTAssertEqual(debugLogResult, .didLog, "Release Logging is being called")
    }

    func testDoesntDebugLoggingWhenNotEnabled() {
        debugLogger.isLoggingEnabled = false
        let debugLogResult = debugLogger.logDebug("Hallo")
        XCTAssertEqual(debugLogResult, .didNotLog, "Debug Logging is not being called")
    }
}
