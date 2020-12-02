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

import Foundation

enum CustomFormat: String, CaseIterable {
    case iso8601Date = "yyyy-MM-dd"
    case iso8601DateTime = "yyyy-MM-dd'T'HH:mm:ss.SSS"
    case iso8601TimeZone = "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"
}

extension DateFormatter {
    static func with(format: CustomFormat) -> DateFormatter {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = format.rawValue
        return dateFormatter
    }
}

extension Date {
    func ISO8601FormattedString() -> String {
        let dateFormatter = DateFormatter.with(format: .iso8601DateTime)
        return dateFormatter.string(from: self)
    }

    func yyyyMmDdFormattedString() -> String {
        let dateFormatter = DateFormatter.with(format: .iso8601Date)
        return dateFormatter.string(from: self)
    }
}
