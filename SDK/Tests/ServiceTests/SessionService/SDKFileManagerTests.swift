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

class AppleFileManagerMock: FileManager {
    override func urls(for directory: FileManager.SearchPathDirectory, in domainMask: FileManager.SearchPathDomainMask) -> [URL] {
        return super.urls(for: .cachesDirectory, in: .userDomainMask)
    }
}

class SDKFileManagerTests: XCTestCase {
    var sdkFileManager: SDKFileManager!
    var fileManagerMock: AppleFileManagerMock!

    override func setUp() {
        super.setUp()

        fileManagerMock = AppleFileManagerMock()
        sdkFileManager = SDKFileManager(fileManager: fileManagerMock)
    }

    func testSaveAndRead() {
        let expectedData = Data(count: 1)

        try! sdkFileManager.saveVersionConfiguration(data: expectedData)

        let resultData = try! sdkFileManager.readVersionConfiguration()
        XCTAssertEqual(resultData, expectedData)
    }
}
