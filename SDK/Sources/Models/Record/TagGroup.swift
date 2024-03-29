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

struct TagGroup: Equatable {
    let tags: [String: String]
    let annotations: [String]

    init(tags: [String: String], annotations: [String] = []) {
        self.tags = tags
        self.annotations = annotations
    }

    init(from decryptedTags: [String], separatedBy separator: Character = "=") {
        var tagsDictionary = [String: String]()
        var annotationsList = [String]()

        for decryptedTag in decryptedTags {
            guard let (key, value) = decryptedTag.decodeKeyAndValue(separatedBy: separator) else { break }
            if key == TaggingService.Keys.custom.rawValue {
                annotationsList.append(value)
            } else {
                tagsDictionary[key] = value
            }
        }

        self.tags = tagsDictionary
        self.annotations = annotationsList
    }

    var hasTags: Bool {
        return !tags.isEmpty || !annotations.isEmpty
    }

    func validateAnnotations() throws {
        for annotation in annotations {
            guard !annotation.isEmpty else {
                throw Data4LifeSDKError.emptyAnnotationNotAllowed
            }
        }
    }
}

fileprivate extension String {
    func decodeKeyAndValue(separatedBy separator: Character = "=") -> (String, String)? {
        let keyValue = self.split(separator: separator)
        guard keyValue.count == 2,
              let unescapedKey = String(keyValue[0]).removingPercentEncoding,
              let unescapedValue = String(keyValue[1]).removingPercentEncoding else {
            return nil
        }
        return (unescapedKey, unescapedValue)
    }
}
