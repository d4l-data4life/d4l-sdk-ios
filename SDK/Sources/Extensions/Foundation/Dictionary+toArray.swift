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

extension Dictionary where Key == String, Value == String {
    func formattedKeyValuePairs(separatedBy separator: Character = "=", usingPercentEncoding: Bool = true) -> [String] {
        return self.compactMap { String.formatKeyValuePair(key: $0, value: $1, usingPercentEncoding: usingPercentEncoding) }
    }
}

extension String {
    static func formatKeyValuePair(key: String, value: String, separatedBy separator: Character = "=", usingPercentEncoding: Bool) -> String? {

        let trimmedKey = key.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)

        if usingPercentEncoding {
            guard let escapedKey = trimmedKey.addingPercentEncoding(withAllowedCharacters: .alphanumerics),
                  let escapedValue = trimmedValue.addingPercentEncoding(withAllowedCharacters: .alphanumerics) else {
                return nil
            }
            return "\(escapedKey.lowercased())\(separator)\(escapedValue.lowercased())"
        } else {
            return "\(trimmedKey.lowercased())\(separator)\(trimmedValue.lowercased())"
        }
    }
}
