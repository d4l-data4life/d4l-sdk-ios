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
    func toKeyValueStringArray(separatedBy separator: Character = "=") -> [String] {
        return self.compactMap { String.makePercentEncodedKeyValuePair(key: $0, value: $1) }
    }
}

extension String {
    static func makePercentEncodedKeyValuePair(key: String, value: String, separatedBy separator: Character = "=") -> String? {
        guard let escapedKey = key.trimmingCharacters(in: .whitespacesAndNewlines)
                .addingPercentEncoding(withAllowedCharacters: .alphanumerics)?.lowercased(),
              let escapedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)
                .addingPercentEncoding(withAllowedCharacters: .alphanumerics)?.lowercased() else {
            return nil
        }
        return "\(escapedKey)\(separator)\(escapedValue)"
    }

    var isLowercased: Bool {
        allSatisfy { !$0.isLetter || $0.isLowercase }
    }
}
