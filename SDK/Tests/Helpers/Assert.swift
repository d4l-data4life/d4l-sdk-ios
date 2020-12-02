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

func XCTAssertEqual(_ lhr: [Any], _ rhr: [Any], file: StaticString = #file, line: UInt = #line) {
    XCTAssertEqual(lhr.count, rhr.count, file: file, line: line)
    for index in 0..<lhr.count {
        if let left = lhr[index] as? String, let right = rhr[index] as? String {
            XCTAssertEqual(left, right, file: file, line: line)
        } else if let left = lhr[index] as? Int, let right = rhr[index] as? Int {
            XCTAssertEqual(left, right, file: file, line: line)
        } else if let left = lhr[index] as? Float, let right = rhr[index] as? Float {
            XCTAssertEqual(left, right, file: file, line: line)
        } else if let left = lhr[index] as? Bool, let right = rhr[index] as? Bool {
            XCTAssertEqual(left, right, file: file, line: line)
        } else if let left = lhr[index] as? [String: Any], let right = rhr[index] as? [String: Any] {
            XCTAssertEqual(left, right, file: file, line: line)
        } else {
            XCTFail(file: file, line: line)
        }
    }
}

func XCTAssertEqual(_ lhr: [String: Any]?, _ rhr: [String: Any]?,
                    file: StaticString = #file, line: UInt = #line) {
    if let lhr = lhr, let rhr = rhr {
        XCTAssertEqual(lhr, rhr, file: file, line: line)
    } else if (lhr == nil) != (rhr == nil) {
        XCTFail("one map is nil", file: file, line: line)
    }
}

func XCTAssertEqual(_ lhr: [String: Any], _ rhr: [String: Any],
                    file: StaticString = #file, line: UInt = #line) {
    lhr.keys.forEach { key in
        if let left = lhr[key] as? String, let right = rhr[key] as? String {
            XCTAssertEqual(left, right, file: file, line: line)
        } else if let left = lhr[key] as? Int, let right = rhr[key] as? Int {
            XCTAssertEqual(left, right, file: file, line: line)
        } else if let left = lhr[key] as? Float, let right = rhr[key] as? Float {
            XCTAssertEqual(left, right, file: file, line: line)
        } else if let left = lhr[key] as? Bool, let right = rhr[key] as? Bool {
            XCTAssertEqual(left, right, file: file, line: line)
        } else if let left = lhr[key] as? [String: Any], let right = rhr[key] as? [String: Any] {
            XCTAssertEqual(left, right, file: file, line: line)
        } else {
            XCTFail(file: file, line: line)
        }
    }
}
