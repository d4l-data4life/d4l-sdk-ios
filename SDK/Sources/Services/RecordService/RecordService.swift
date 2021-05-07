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
@_implementationOnly import Then

protocol RecordServiceType {
    func createRecord<DR: DecryptedRecord>(forResource resource: DR.Resource,
                                           annotations: [String],
                                           userId: String,
                                           attachmentKey: Key?,
                                           decryptedRecordType: DR.Type) -> Async<DR>
    func fetchRecord<DR: DecryptedRecord>(recordId: String,
                                          userId: String,
                                          decryptedRecordType: DR.Type) -> Async<DR>
    func updateRecord<DR: DecryptedRecord>(forResource resource: DR.Resource,
                                           annotations: [String]?,
                                           userId: String,
                                           recordId: String,
                                           attachmentKey: Key?,
                                           decryptedRecordType: DR.Type) -> Async<DR>
    func deleteRecord(recordId: String, userId: String) -> Async<Void>
    func countRecords<R: SDKResource>(userId: String,
                                      resourceType: R.Type,
                                      annotations: [String]) -> Async<Int>
    func searchRecords<DR: DecryptedRecord>(for userId: String,
                                            from startDate: Date?,
                                            to endDate: Date?,
                                            pageSize: Int?,
                                            offset: Int?,
                                            annotations: [String],
                                            decryptedRecordType: DR.Type) -> Async<[DR]>
}

extension RecordServiceType {
    func fetchRecord<DR: DecryptedRecord>(recordId: String,
                                          userId: String) -> Async<DR> {
        return fetchRecord(recordId: recordId, userId: userId, decryptedRecordType: DR.self)
    }
}

struct RecordService: RecordServiceType {
    private let sessionService: SessionService
    private let taggingService: TaggingServiceType
    private let cryptoService: CryptoServiceType
    private let commonKeyService: CommonKeyServiceType
    private let userService: UserServiceType

    init(container: DIContainer) {
        do {
            self.sessionService = try container.resolve()
            self.cryptoService = try container.resolve()
            self.commonKeyService = try container.resolve()
            self.taggingService = try container.resolve()
            self.userService = try container.resolve()
        } catch {
            fatalError(error.localizedDescription)
        }
    }

    func createRecord<DR: DecryptedRecord>(forResource resource: DR.Resource,
                                           annotations: [String] = [],
                                           userId: String,
                                           attachmentKey: Key? = nil,
                                           decryptedRecordType: DR.Type = DR.self) -> Async<DR> {
        func createRequest(parameters: Parameters) -> Router {
            return Router.createRecord(userId: userId, parameters: parameters)
        }

        return cryptoService.generateGCKey(.data).then { key in
            return self.uploadRecord(forResource: resource,
                                     userId: userId,
                                     dataKey: key,
                                     attachmentKey: attachmentKey,
                                     annotations: annotations,
                                     decryptedRecordType: decryptedRecordType,
                                     uploadRequest: createRequest)
        }
    }

    func updateRecord<DR: DecryptedRecord>(forResource resource: DR.Resource,
                                           annotations: [String]? = nil,
                                           userId: String,
                                           recordId: String,
                                           attachmentKey: Key? = nil,
                                           decryptedRecordType: DR.Type = DR.self) -> Async<DR> {
        func updateRequest(parameters: Parameters) -> Router {
            return Router.updateRecord(userId: userId, recordId: recordId, parameters: parameters)
        }

        let promise: Async<DR> = fetchRecord(recordId: recordId, userId: userId, decryptedRecordType: decryptedRecordType).then { record in

            return self.uploadRecord(forResource: resource,
                                     userId: userId,
                                     dataKey: record.dataKey,
                                     attachmentKey: record.attachmentKey ?? attachmentKey,
                                     oldTags: record.tags,
                                     annotations: annotations ?? record.annotations,
                                     decryptedRecordType: decryptedRecordType,
                                     uploadRequest: updateRequest)
        }
        return promise
    }

    func fetchRecord<DR: DecryptedRecord>(recordId: String,
                                          userId: String,
                                          decryptedRecordType: DR.Type = DR.self) -> Async<DR> {
        return async {
            let route = Router.fetchRecord(userId: userId, recordId: recordId)
            let encrypted: EncryptedRecord = try wait(self.sessionService.request(route: route).responseDecodable())
            return try wait(DR.from(encryptedRecord: encrypted,
                                     cryptoService: self.cryptoService,
                                     commonKeyService: self.commonKeyService))
        }
    }

    func deleteRecord(recordId: String, userId: String) -> Async<Void> {
        return async {
            let route = Router.deleteRecord(userId: userId, recordId: recordId)
            return try wait(self.sessionService.request(route: route).responseEmpty())
        }
    }

    func searchRecords<DR: DecryptedRecord>(for userId: String,
                                            from startDate: Date?,
                                            to endDate: Date?,
                                            pageSize: Int?,
                                            offset: Int?,
                                            annotations: [String] = [],
                                            decryptedRecordType: DR.Type = DR.self) -> Async<[DR]> {
        return async {
            let tagGroup = try wait(self.taggingService.makeTagGroup(for: DR.Resource.self, annotations: annotations))
            let parameters = try wait(self.makeSearchParameters(from: startDate,
                                                             to: endDate,
                                                             offset: offset,
                                                             pageSize: pageSize,
                                                             tagGroup: tagGroup))

            let route = Router.searchRecords(userId: userId, parameters: parameters)
            let encryptedRecords: [EncryptedRecord] = try wait(
                self.sessionService.request(route: route).responseDecodable()
            )

            guard encryptedRecords.isEmpty == false else {
                return []
            }
            return try encryptedRecords.map {
                try wait(DR.from(encryptedRecord: $0,
                                 cryptoService: self.cryptoService,
                                 commonKeyService: self.commonKeyService))
            }
        }
    }

    func countRecords<R: SDKResource>(userId: String, resourceType: R.Type, annotations: [String] = []) -> Async<Int> {
        return async {
            let tagGroup = try wait(self.taggingService.makeTagGroup(for: resourceType, annotations: annotations))
            let params = try wait(self.makeSearchParameters(tagGroup: tagGroup))
            let route = Router.countRecords(userId: userId, parameters: params)
            let headers = try wait(self.sessionService.request(route: route).responseHeaders())

            guard
                let countString = headers["x-total-count"] as? String,
                let count = Int(countString) else {
                throw Data4LifeSDKError.keyMissingInSerialization(key: "`x-total-count`")
            }

            return count
        }
    }
}

// MARK: - Upload Record (Create and Update)
extension RecordService {
    private func uploadRecord<DR: DecryptedRecord>(forResource resource: DR.Resource,
                                                   userId: String,
                                                   dataKey: Key,
                                                   attachmentKey: Key? = nil,
                                                   oldTags: [String: String]? = nil,
                                                   annotations: [String]? = nil,
                                                   decryptedRecordType: DR.Type = DR.self,
                                                   uploadRequest: @escaping (Parameters) -> Router) -> Async<DR> {
        return async {

            guard let tek = self.cryptoService.tek else {
                throw Data4LifeSDKError.missingTagKey
            }

            try wait(self.userService.fetchUserInfo())
            let commonKeyId = self.commonKeyService.currentId ?? CommonKeyService.initialId
            guard let commonKey = self.commonKeyService.currentKey else {
                throw Data4LifeSDKError.missingCommonKey
            }

            let tagGroup = try wait(self.taggingService.makeTagGroup(for: resource, oldTags: oldTags ?? [:], annotations: annotations))

            let uploadParameters = try makeUploadParameters(resource: resource,
                                                            commonKey: commonKey,
                                                            commonKeyIdentifier: commonKeyId,
                                                            dataKey: dataKey,
                                                            attachmentKey: attachmentKey,
                                                            tagEncryptionKey: tagEncryptionKey,
                                                            tagGroup: tagGroup)
            let route = uploadRequest(uploadParameters)
            let encryptedRecord: EncryptedRecord = try wait(
                self.sessionService.request(route: route).responseDecodable()
            )

            return try wait(DR.from(encryptedRecord: encryptedRecord,
                                     cryptoService: self.cryptoService,
                                     commonKeyService: self.commonKeyService))
        }
    }
}

// MARK: - Parameter Builders
extension RecordService {

    private func makeUploadParameters<R: SDKResource>(resource: R,
                                                      commonKey: Key,
                                                      commonKeyIdentifier: String,
                                                      dataKey: Key,
                                                      attachmentKey: Key?,
                                                      tagEncryptionKey: Key,
                                                      tagGroup: TagGroup) throws -> Parameters {

        var parameters: Parameters = Parameters()

        parameters["date"] = Date().yyyyMmDdFormattedString()
        parameters["common_key_id"] = commonKeyIdentifier
        parameters["model_version"] = R.modelVersion

        let encryptedTagParameters = try self.cryptoService.encrypt(tagsParameters: try tagGroup.asTagsParameters(for: .upload), key: tagEncryptionKey)
        parameters["encrypted_tags"] = encryptedTagParameters.asTagExpressions

        let encryptedResource: Data = try wait(self.cryptoService.encrypt(value: resource, key: dataKey))
        let encryptedBody = encryptedResource.base64EncodedString()
        parameters["encrypted_body"] = encryptedBody

        let jsonDataKey: Data = try JSONEncoder().encode(dataKey)
        let encryptedDataKey: Data = try self.cryptoService.encrypt(data: jsonDataKey, key: commonKey)
        parameters["encrypted_key"] = encryptedDataKey.base64EncodedString()

        if let attachmentKey = attachmentKey {
            let jsonAttachmentKey: Data = try JSONEncoder().encode(attachmentKey)
            let encryptedAttachmentKey: Data = try self.cryptoService.encrypt(data: jsonAttachmentKey, key: commonKey)
            parameters["attachment_key"] = encryptedAttachmentKey.base64EncodedString()
        }

        return parameters
    }

    private func makeSearchParameters(from startDate: Date? = nil,
                                      to endDate: Date? = nil,
                                      offset: Int? = nil,
                                      pageSize: Int? = nil,
                                      tagGroup: TagGroup) throws -> Async<Parameters> {
        return async {

            var parameters = Parameters()

            guard let tagEncryptionKey = self.cryptoService.tagEncryptionKey else {
                throw Data4LifeSDKError.notLoggedIn
            }

            if let startDate = startDate {
                parameters["start_date"] = startDate.yyyyMmDdFormattedString()
            }
            if let endDate = endDate {
                parameters["end_date"] = endDate.yyyyMmDdFormattedString()
            }
            if let pageSize = pageSize {
                parameters["limit"] = pageSize
            }
            if let offset = offset {
                parameters["offset"] = offset
            }

            if tagGroup.hasTags {
                let tagsParameters = try tagGroup.asTagsParameters(for: .search())
                let encryptedTagsParameters = try self.cryptoService.encrypt(tagsParameters: tagsParameters, key: tek)
                parameters["tags"] = encryptedTagsParameters.asTagExpressions.joined(separator: ",")
            }
            return parameters
        }
    }
}

// MARK: - Helpers
extension CryptoServiceType {
    func encrypt(tagsParameters: [TagsParameter], key: Key) throws -> [TagsParameter] {
        return try tagsParameters.map { tagsParameter in
            let encodedTags = try tagsParameter.orComponents.map { try encrypt(string: $0.formattedTag, key: key) }
            return TagsParameter(encodedTags.map { TagsParameter.OrComponent(formattedTag: $0) })
        }
    }
}
