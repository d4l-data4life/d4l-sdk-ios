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
@_implementationOnly import Data4LifeCrypto

struct TagsParameter: Hashable {

    enum OperationType {
        case search(supportingLegacyTags: Bool = true)
        case upload
    }

    struct OrComponent: Hashable {
        let formattedTag: String

        init(key: String, value:String, separator: Character = "=") {
            self.formattedTag = "\(key)\(separator)\(value)"
        }

        init(tag: String) {
            self.formattedTag = tag
        }
    }

    let orComponents: [OrComponent]

    init(_ formattedTag: String) {
        self.orComponents = [OrComponent(tag: formattedTag)]
    }

    init(_ singleOrComponent: OrComponent) {
        self.orComponents = [singleOrComponent]
    }

    init(_ orComponents: [OrComponent]) {
        self.orComponents = orComponents
    }

    var tagExpression: String {
        if orComponents.count == 1, let onlyComponent = orComponents.first {
            return onlyComponent.formattedTag
        } else {
            return "(\(orComponents.formattedTags.joined(separator: ",")))"
        }
    }
}

extension TagGroup {
    func asTagsParameters(for operationType: TagsParameter.OperationType, separatedBy separator: Character = "=") throws -> [TagsParameter] {

        try validateAnnotations()

        let formattedAnnotations: [TagsParameter] = try annotations.compactMap { entry in
            let key = TaggingService.Keys.custom.rawValue.lowercased()
            let annotation = entry.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            return try formatSingleTag(withKey: key, value: annotation, separator: separator, for: operationType)
        }

        let formattedTags: [TagsParameter] = try tags.compactMap { entry in
            let key = entry.key.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            let value = entry.value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            return try formatSingleTag(withKey: key, value: value, separator: separator, for: operationType)
        }

        return formattedTags + formattedAnnotations
    }
}

extension TagGroup {
    private func validateAnnotations() throws {
        for annotation in annotations {
            guard !annotation.isEmpty else {
                throw Data4LifeSDKError.emptyAnnotationNotAllowed
            }
        }
    }

    private func formatSingleTag(withKey key: String, value: String, separator: Character, for operationType: TagsParameter.OperationType) throws -> TagsParameter {
        switch operationType {
        case .upload, .search(false):
            return try formatSingleTagAsTagsParameterWithSingleComponent(tagKey: key,
                                                                         tagValue: value,
                                                                         separatedBy: separator)
        case .search(true):
            return try formatSingleTagAsTagsParameterWithOrComponents(tagKey: key,
                                                                      tagValue: value,
                                                                      separatedBy: separator)
        }
    }

    private func formatSingleTagAsTagsParameterWithSingleComponent(tagKey: String, tagValue: String, separatedBy separator: Character = "=") throws -> TagsParameter {
        let component = try formatSingleTagWithPercentEncodingAndFullyLowercased(tagKey: tagKey,
                                                                                 tagValue: tagValue,
                                                                                 separatedBy: separator)
        return TagsParameter(component)
    }

    private func formatSingleTagAsTagsParameterWithOrComponents(tagKey: String, tagValue: String, separatedBy separator: Character = "=") throws -> TagsParameter {

        let trimmedKey = tagKey.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let trimmedValue = tagValue.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        let tagEncodedAndFullyLowercased = try formatSingleTagWithPercentEncodingAndFullyLowercased(tagKey: trimmedKey, tagValue: trimmedValue, separatedBy: separator)
        let tagNonEncodedAndLowercasedForAndroidLegacy = formatSingleTagWithoutPercentEncoding(tagKey: trimmedKey, tagValue: trimmedValue, separatedBy: separator)
        let tagCustomEncodedForJSLegacy = try formatSingleTagWithCustomJSPercentEncoding(tagKey: trimmedKey, tagValue: trimmedValue, separatedBy: separator)

        let orExpressionComponents = [tagEncodedAndFullyLowercased,
                                      tagNonEncodedAndLowercasedForAndroidLegacy,
                                      tagCustomEncodedForJSLegacy]
            .removingDuplicates
        return TagsParameter(orExpressionComponents)
    }

    private func formatSingleTagWithPercentEncodingAndFullyLowercased(tagKey: String, tagValue: String, separatedBy separator: Character = "=") throws -> TagsParameter.OrComponent {
        guard let escapedKey = tagKey.addingPercentEncoding(withAllowedCharacters: .alphanumerics),
              let escapedValue = tagValue.addingPercentEncoding(withAllowedCharacters: .alphanumerics) else {
            throw Data4LifeSDKError.invalidCharacterInTag
        }
        let encodedTagComponent = TagsParameter.OrComponent(key: escapedKey.lowercased(),
                                                            value: escapedValue.lowercased(),
                                                            separator: separator)
        return encodedTagComponent
    }

    private func formatSingleTagWithoutPercentEncoding(tagKey: String, tagValue: String, separatedBy separator: Character = "=") -> TagsParameter.OrComponent {
        let encodedTagComponent = TagsParameter.OrComponent(key: tagKey,
                                                            value: tagValue,
                                                            separator: separator)
        return encodedTagComponent
    }

    private func formatSingleTagWithCustomJSPercentEncoding(tagKey: String, tagValue: String, separatedBy separator: Character = "=") throws -> TagsParameter.OrComponent {
        let customEncodedCharacters = "!()*-._~"
        let customEncodings = customEncodedCharacters.reduce([Character: String]()) { result, character in
            var encodings = result
            encodings[character] = String(character).addingPercentEncoding(withAllowedCharacters: .alphanumerics)?.lowercased()
            return encodings
        }

        let allowedCharacterSet = CharacterSet(charactersIn: customEncodedCharacters).union(.alphanumerics)
        guard let escapedKeyCharacters = tagKey
                .addingPercentEncoding(withAllowedCharacters: allowedCharacterSet)?
                .flatMap({ customEncodings[$0] ?? String($0) }),
              let escapedValueCharacters  = tagValue
                .addingPercentEncoding(withAllowedCharacters: allowedCharacterSet)?
                .flatMap({ customEncodings[$0] ?? String($0) }) else {
            throw Data4LifeSDKError.invalidCharacterInTag
        }

        let escapedKey = String(escapedKeyCharacters)
        let escapedValue = String(escapedValueCharacters)
        let encodedTagComponent = TagsParameter.OrComponent(key: escapedKey,
                                                            value: escapedValue,
                                                            separator: separator)
        return encodedTagComponent
    }
}

extension CryptoService {
    func encrypt(tagsParameters: [TagsParameter], key: Key) throws -> [TagsParameter] {
        return try tagsParameters.map { tagsParameter in
            let encodedTags = try tagsParameter.orComponents.map { try encrypt(string: $0.formattedTag, key: key) }
            return TagsParameter(encodedTags.map { TagsParameter.OrComponent(tag: $0) })
        }
    }
}

extension Array where Element: Hashable {
    var removingDuplicates: [Element] {
        let orderedSet = NSOrderedSet(array: self as [Any])
        return orderedSet.array.compactMap { $0 as? Element }
    }
}

extension Array where Element == TagsParameter {
    var asTagExpressions: [String] {
        map { $0.tagExpression }
    }
}

extension Array where Element == TagsParameter.OrComponent {
    var formattedTags: [String] {
        map { $0.formattedTag }
    }
}
