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

import Foundation

extension Array where Element: Hashable {
    var removingDuplicates: [Element] {
        let orderedSet = NSOrderedSet(array: self as [Any])
        return orderedSet.array.compactMap { $0 as? Element }
    }
}

extension Array where Element == String {
    var lowercased: [Element] {
        map { $0.lowercased() }
    }
}

extension Dictionary where Key == String, Value == String {
    var lowercased: [Key: Value] {
        let entries = map { entry in
            (entry.key.lowercased(), entry.value.lowercased())
        }
        return Dictionary(entries, uniquingKeysWith: { $1 })
    }
}