//
//  RecordServiceParameterBuilder.swift
//  Data4LifeSDK
//
//  Created by Alessio Borraccino on 07.05.21.
//  Copyright © 2021 HPS Gesundheitscloud gGmbH. All rights reserved.
//

// swiftlint:disable nesting
import Foundation
@_implementationOnly import Data4LifeCrypto

protocol RecordServiceParameterBuilderProtocol {
    func uploadParameters<R: SDKResource>(resource: R,
                                          commonKey: Key,
                                          commonKeyIdentifier: String,
                                          dataKey: Key,
                                          attachmentKey: Key?,
                                          tagGroup: TagGroup) throws -> Parameters
    func searchParameters(from startDate: Date?,
                          to endDate: Date?,
                          offset: Int?,
                          pageSize: Int?,
                          tagGroup: TagGroup,
                          supportingLegacyTags: Bool) throws -> Parameters
}

struct RecordServiceParameterBuilder: RecordServiceParameterBuilderProtocol {

    enum ParameterKey {
        enum Upload: String {
            case date = "date"
            case commonKeyIdentifier = "common_key_id"
            case modelVersion = "model_version"
            case encryptedTags = "encrypted_tags"
            case encryptedBody = "encrypted_body"
            case encryptedKey = "encrypted_key"
            case attachmentKey = "attachment_key"
        }
        enum Search: String {
            case startDate = "start_date"
            case endDate = "end_date"
            case limit = "limit"
            case offset = "offset"
            case tags = "tags"
        }
    }

    enum OperationType {
        case search(supportingLegacyTags: Bool = true)
        case upload
    }

    struct TagsParameter: Hashable {

        struct OrComponent: Hashable {
            let formattedTag: String

            init(key: String, value:String, separator: Character = "=") {
                self.formattedTag = "\(key)\(separator)\(value)"
            }

            init(formattedTag: String) {
                self.formattedTag = formattedTag
            }
        }

        let orComponents: [OrComponent]
    }

    private let cryptoService: CryptoServiceType

    init(container: DIContainer) {
        do {
            self.cryptoService = try container.resolve()
        } catch {
            fatalError(error.localizedDescription)
        }
    }
}

extension RecordServiceParameterBuilder.TagsParameter {

    init(_ formattedTag: String) {
        self.orComponents = [OrComponent(formattedTag: formattedTag)]
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

extension RecordServiceParameterBuilder {

    func uploadParameters<R: SDKResource>(resource: R,
                                          commonKey: Key,
                                          commonKeyIdentifier: String,
                                          dataKey: Key,
                                          attachmentKey: Key?,
                                          tagGroup: TagGroup) throws -> Parameters {

        var parameters: Parameters = Parameters()

        parameters[ParameterKey.Upload.date.rawValue] = Date().yyyyMmDdFormattedString()
        parameters[ParameterKey.Upload.commonKeyIdentifier.rawValue] = commonKeyIdentifier
        parameters[ParameterKey.Upload.modelVersion.rawValue] = R.modelVersion

        let encryptedTagParameters = try encrypt(tagsParameters: try tagsParameters(from: tagGroup, for: .upload),
                                                 key: try tagEncryptionKey())
        parameters[ParameterKey.Upload.encryptedTags.rawValue] = encryptedTagParameters.asTagExpressions

        let encryptedResource: Data = try wait(self.cryptoService.encrypt(value: resource, key: dataKey))
        let encryptedBody = encryptedResource.base64EncodedString()
        parameters[ParameterKey.Upload.encryptedBody.rawValue] = encryptedBody

        let jsonDataKey: Data = try JSONEncoder().encode(dataKey)
        let encryptedDataKey: Data = try self.cryptoService.encrypt(data: jsonDataKey, key: commonKey)
        parameters[ParameterKey.Upload.encryptedKey.rawValue] = encryptedDataKey.base64EncodedString()

        if let attachmentKey = attachmentKey {
            let jsonAttachmentKey: Data = try JSONEncoder().encode(attachmentKey)
            let encryptedAttachmentKey: Data = try self.cryptoService.encrypt(data: jsonAttachmentKey, key: commonKey)
            parameters[ParameterKey.Upload.attachmentKey.rawValue] = encryptedAttachmentKey.base64EncodedString()
        }

        return parameters
    }

    func searchParameters(from startDate: Date? = nil,
                          to endDate: Date? = nil,
                          offset: Int? = nil,
                          pageSize: Int? = nil,
                          tagGroup: TagGroup,
                          supportingLegacyTags: Bool = true) throws -> Parameters {

        var parameters = Parameters()

        if let startDate = startDate {
            parameters[ParameterKey.Search.startDate.rawValue] = startDate.yyyyMmDdFormattedString()
        }
        if let endDate = endDate {
            parameters[ParameterKey.Search.endDate.rawValue] = endDate.yyyyMmDdFormattedString()
        }
        if let pageSize = pageSize {
            parameters[ParameterKey.Search.limit.rawValue] = pageSize
        }
        if let offset = offset {
            parameters[ParameterKey.Search.offset.rawValue] = offset
        }

        if tagGroup.hasTags {
            let tagsParameters = try tagsParameters(from: tagGroup, for: .search(supportingLegacyTags: supportingLegacyTags))
            let encryptedTagsParameters = try encrypt(tagsParameters: tagsParameters, key: try tagEncryptionKey())
            parameters[ParameterKey.Search.tags.rawValue] = encryptedTagsParameters.asTagExpressions.joined(separator: ",")
        }
        return parameters
    }
}

// MARK: - Crypto Helpers
extension RecordServiceParameterBuilder {
    private func tagEncryptionKey() throws -> Key {
        guard let tagEncryptionKey = self.cryptoService.tagEncryptionKey else {
            throw Data4LifeSDKError.missingTagKey
        }
        return tagEncryptionKey
    }

    private func encrypt(tagsParameters: [TagsParameter], key: Key) throws -> [TagsParameter] {
        return try tagsParameters.map { tagsParameter in
            let encodedTags = try tagsParameter.orComponents.map { try cryptoService.encrypt(string: $0.formattedTag, key: key) }
            return TagsParameter(encodedTags.map { TagsParameter.OrComponent(formattedTag: $0) })
        }
    }
}

// MARK: - Tag formatting helpers
extension RecordServiceParameterBuilder {

    private func tagsParameters(from tagGroup: TagGroup, for operationType: RecordServiceParameterBuilder.OperationType, separatedBy separator: Character = "=") throws -> [TagsParameter] {

        try tagGroup.validateAnnotations()

        let formattedAnnotations: [TagsParameter] = try tagGroup.annotations.compactMap { entry in
            let key = TaggingService.Keys.custom.rawValue.lowercased()
            let annotation = entry.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            return try formatSingleTag(withKey: key, value: annotation, separator: separator, for: operationType)
        }

        let formattedTags: [TagsParameter] = try tagGroup.tags.compactMap { entry in
            let key = entry.key.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            let value = entry.value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            return try formatSingleTag(withKey: key, value: value, separator: separator, for: operationType)
        }

        return formattedTags + formattedAnnotations
    }

    private func formatSingleTag(withKey key: String, value: String, separator: Character, for operationType: RecordServiceParameterBuilder.OperationType) throws -> TagsParameter {
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

// MARK: - Extension helpers
extension Array where Element == RecordServiceParameterBuilder.TagsParameter {
    var asTagExpressions: [String] {
        map { $0.tagExpression }
    }
}

extension Array where Element == RecordServiceParameterBuilder.TagsParameter.OrComponent {
    var formattedTags: [String] {
        map { $0.formattedTag }
    }
}
