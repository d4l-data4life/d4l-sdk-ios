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
import Data4LifeCrypto
import Then

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
    func countRecords<R: SDKResource>(userId: String, resourceType: R.Type, annotations: [String]) -> Async<Int>
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
    let sessionService: SessionService
    let taggingService: TaggingServiceType
    let cryptoService: CryptoServiceType
    let commonKeyService: CommonKeyServiceType
    let userService: UserServiceType

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
            let encrypted: EncryptedRecord = try await(self.sessionService.request(route: route).responseDecodable())
            return try await(DR.from(encryptedRecord: encrypted,
                                     cryptoService: self.cryptoService,
                                     commonKeyService: self.commonKeyService))
        }
    }

    func deleteRecord(recordId: String, userId: String) -> Async<Void> {
        return async {
            let route = Router.deleteRecord(userId: userId, recordId: recordId)
            return try await(self.sessionService.request(route: route).responseEmpty())
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
            let tagGroup = try await(self.taggingService.makeTagGroup(for: DR.Resource.self, annotations: annotations))
            let params = try await(self.buildParameters(from: startDate,
                                                        to: endDate,
                                                        offset: offset,
                                                        pageSize: pageSize,
                                                        tagGroup: tagGroup))

            let route = Router.searchRecords(userId: userId, parameters: params)
            let encryptedRecords: [EncryptedRecord] = try await(
                self.sessionService.request(route: route).responseDecodable()
            )

            guard encryptedRecords.isEmpty == false else {
                return []
            }
            return try encryptedRecords.map {
                try await(DR.from(encryptedRecord: $0,
                                  cryptoService: self.cryptoService,
                                  commonKeyService: self.commonKeyService))
            }
        }
    }

    func countRecords<R: SDKResource>(userId: String, resourceType: R.Type, annotations: [String] = []) -> Async<Int> {
        return async {
            let tagGroup = try await(self.taggingService.makeTagGroup(for: resourceType, annotations: annotations))
            let params = try await(self.buildParameters(tagGroup: tagGroup))
            let route = Router.countRecords(userId: userId, parameters: params)
            let headers = try await(self.sessionService.request(route: route).responseHeaders())

            guard let countString = headers["x-total-count"] as? String, let count = Int(countString) else {
                throw Data4LifeSDKError.keyMissingInSerialization(key: "`x-total-count`")
            }

            return count
        }
    }
}

private extension RecordService {
    func uploadRecord<DR: DecryptedRecord>(forResource resource: DR.Resource,
                                           userId: String,
                                           dataKey: Key,
                                           attachmentKey: Key? = nil,
                                           oldTags: [String: String]? = nil,
                                           annotations: [String]? = nil,
                                           decryptedRecordType: DR.Type = DR.self,
                                           uploadRequest: @escaping (Parameters) -> Router) -> Async<DR> {
        return async {
            let tagGroup = try await(self.taggingService.makeTagGroup(for: resource, oldTags: oldTags ?? [:], annotations: annotations))

            // Load crypto keys
            guard let tek = self.cryptoService.tek else {
                throw Data4LifeSDKError.missingTagKey
            }

            //Update current common key
            try await(self.userService.fetchUserInfo())

            let commonKeyId = self.commonKeyService.currentId ?? CommonKeyService.initialId

            guard let commonKey = self.commonKeyService.currentKey else {
                throw Data4LifeSDKError.missingCommonKey
            }

            // Encrypt tags
            let encryptedTags = try self.cryptoService.encrypt(values: tagGroup.asParameters(), key: tek)

            // Encrypt Resource body
            let encryptedResource: Data = try await(self.cryptoService.encrypt(value: resource, key: dataKey))
            let encryptedBody = encryptedResource.base64EncodedString()

            // Encrypt GC keys
            let jsonDataKey: Data = try JSONEncoder().encode(dataKey)
            let encDataKey:Data = try self.cryptoService.encrypt(data: jsonDataKey, key: commonKey)

            var params:Parameters = ["encrypted_tags": encryptedTags,
                                     "encrypted_body": encryptedBody,
                                     "date": Date().yyyyMmDdFormattedString(),
                                     "encrypted_key": encDataKey.base64EncodedString(),
                                     "common_key_id": commonKeyId,
                                     "model_version": DR.Resource.modelVersion]

            // Add attachment key if present
            if let attKey = attachmentKey {
                let jsonAttKey: Data = try JSONEncoder().encode(attKey)
                let encAttKey: Data = try self.cryptoService.encrypt(data: jsonAttKey, key: commonKey)
                params["attachment_key"] = encAttKey.base64EncodedString()
            }

            // Create new resource
            let route = uploadRequest(params)
            let encryptedRecord: EncryptedRecord = try await(
                self.sessionService.request(route: route).responseDecodable()
            )

            return try await(DR.from(encryptedRecord: encryptedRecord,
                                     cryptoService: self.cryptoService,
                                     commonKeyService: self.commonKeyService))
        }
    }

    func buildParameters(from startDate: Date? = nil,
                         to endDate: Date? = nil,
                         offset: Int? = nil,
                         pageSize: Int? = nil,
                         tagGroup: TagGroup) throws -> Async<Parameters> {
        return async {
            var parameters: Parameters = [:]
            guard let tek = self.cryptoService.tek else {
                throw Data4LifeSDKError.notLoggedIn
            }

            let encryptedTags = try self.cryptoService.encrypt(values: tagGroup.asParameters(), key: tek)

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

            if encryptedTags.isEmpty == false {
                parameters["tags"] = encryptedTags.joined(separator: ",")
            }

            return parameters
        }
    }
}
