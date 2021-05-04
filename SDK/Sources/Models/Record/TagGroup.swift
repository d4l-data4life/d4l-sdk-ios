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
@_implementationOnly import Then

struct TagGroup: Equatable {
    let tags: [String: String]
    let annotations: [String]

    init(tags: [String: String], annotations: [String] = []) {
        self.tags = tags
        self.annotations = annotations
    }

    init(from parameters: [String], separatedBy separator: Character = "=") {
        var tagsDictionary = [String: String]()
        var annotationsList = [String]()

        for decryptedTag in parameters {
            guard let (key, value) = decryptedTag.splitKeyAndValue(separatedBy: separator) else { break }
            if key == TaggingService.Keys.custom.rawValue {
                annotationsList.append(value)
            } else {
                tagsDictionary[key] = value
            }
        }

        self.tags = tagsDictionary
        self.annotations = annotationsList
    }

    func asParameters(separatedBy separator: Character = "=") throws -> [String] {
        try validateAnnotations()
        let formattedAnnotations: [String] = try annotations.compactMap {
            try formatSingleTagAsExpression(tagKey: TaggingService.Keys.custom.rawValue, tagValue: $0, separatedBy: separator)
        }
        let formattedTags: [String] = try tags.compactMap { entry in
            try formatSingleTagAsExpression(tagKey: entry.key, tagValue: entry.value, separatedBy: separator)
        }

        return formattedTags + formattedAnnotations
    }

    private func validateAnnotations() throws {
        for annotation in annotations {
            guard !annotation.isEmpty else {
                throw Data4LifeSDKError.emptyAnnotationNotAllowed
            }
        }
    }

    private func formatSingleTagAsExpression(tagKey: String, tagValue: String, separatedBy separator: Character = "=") throws -> String {
        let trimmedKey = tagKey.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let trimmedValue = tagValue.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        if trimmedKey.hasPercentEncodableCharacters() || trimmedValue.hasPercentEncodableCharacters() {
            let tagNonEncodedAndLowercasedForAndroidLegacy = formatSingleTagWithoutPercentEncoding(tagKey: trimmedKey, tagValue: trimmedValue, separatedBy: separator)
            let tagEncodedAndFullyLowercased = try formatSingleTagWithPercentEncodingAndFullyLowercased(tagKey: trimmedKey, tagValue: trimmedValue, separatedBy: separator)
            let tagCustomEncodedForJSLegacy = try formatSingleTagWithCustomJSPercentEncoding(tagKey: trimmedKey, tagValue: trimmedValue, separatedBy: separator)
            let orExpressionComponents = [tagNonEncodedAndLowercasedForAndroidLegacy,
                                          tagEncodedAndFullyLowercased,
                                          tagCustomEncodedForJSLegacy]
            return "(\(orExpressionComponents.joined(separator: ",")))"
        } else {
            return formatSingleTagWithoutPercentEncoding(tagKey: trimmedKey, tagValue: trimmedValue, separatedBy: separator)
        }
    }

    private func formatSingleTagWithPercentEncodingAndFullyLowercased(tagKey: String, tagValue: String, separatedBy separator: Character = "=") throws -> String {
        guard let escapedKey = tagKey.addingPercentEncoding(withAllowedCharacters: .alphanumerics),
              let escapedValue = tagValue.addingPercentEncoding(withAllowedCharacters: .alphanumerics) else {
            throw Data4LifeSDKError.invalidCharacterInTag
        }
        return "\(escapedKey.lowercased())\(separator)\(escapedValue.lowercased())"
    }

    private func formatSingleTagWithoutPercentEncoding(tagKey: String, tagValue: String, separatedBy separator: Character = "=") -> String {
        return "\(tagKey.lowercased())\(separator)\(tagValue.lowercased())"
    }

    private func formatSingleTagWithCustomJSPercentEncoding(tagKey: String, tagValue: String, separatedBy separator: Character = "=") throws -> String {
        let allowedCharacterSet = CharacterSet(charactersIn: "!()*-._~").union(.alphanumerics)
        guard let escapedKey = tagKey.addingPercentEncoding(withAllowedCharacters: allowedCharacterSet),
              let escapedValue = tagValue.addingPercentEncoding(withAllowedCharacters: allowedCharacterSet) else {
            throw Data4LifeSDKError.invalidCharacterInTag
        }

        let percentEncodedPair = "\(escapedKey)\(separator)\(escapedValue)"
        let customEncodings: [Character: String] = [ "!": "%21",
                                                     "(": "%28",
                                                     ")": "%29",
                                                     "*": "%2a",
                                                     "-": "%2d",
                                                     ".": "%2e",
                                                     "_": "%5f",
                                                     "~": "%7e"]
        return percentEncodedPair.map { customEncodings[$0] ?? String($0) }.joined()
    }
}

private extension String {
    func hasPercentEncodableCharacters(withAllowedCharacters allowedCharacterSet: CharacterSet = .alphanumerics) -> Bool {
        let percentEncodedString = addingPercentEncoding(withAllowedCharacters: allowedCharacterSet)
        return self != percentEncodedString
    }
}
