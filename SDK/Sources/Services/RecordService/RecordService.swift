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

protocol RecordServiceType {
    func createRecord<DR: DecryptedRecord>(forResource resource: DR.Resource,
                                           annotations: [String],
                                           userId: String,
                                           attachmentKey: Key?,
                                           decryptedRecordType: DR.Type) -> SDKFuture<DR>
    func fetchRecord<DR: DecryptedRecord>(recordId: String,
                                          userId: String,
                                          decryptedRecordType: DR.Type) -> SDKFuture<DR>
    func updateRecord<DR: DecryptedRecord>(forResource resource: DR.Resource,
                                           annotations: [String]?,
                                           userId: String,
                                           recordId: String,
                                           attachmentKey: Key?,
                                           decryptedRecordType: DR.Type) -> SDKFuture<DR>
    func deleteRecord(recordId: String, userId: String) -> SDKFuture<Void>
    func countRecords<R: SDKResource>(userId: String,
                                      resourceType: R.Type,
                                      annotations: [String]) -> SDKFuture<Int>
    func searchRecords<DR: DecryptedRecord>(for userId: String,
                                            from startDate: Date?,
                                            to endDate: Date?,
                                            pageSize: Int?,
                                            offset: Int?,
                                            annotations: [String],
                                            decryptedRecordType: DR.Type) -> SDKFuture<[DR]>
}

extension RecordServiceType {
    func fetchRecord<DR: DecryptedRecord>(recordId: String,
                                          userId: String) -> SDKFuture<DR> {
        return fetchRecord(recordId: recordId, userId: userId, decryptedRecordType: DR.self)
    }
}

struct RecordService: RecordServiceType {
    private let sessionService: SessionService
    private let taggingService: TaggingServiceType
    private let cryptoService: CryptoServiceType
    private let commonKeyService: CommonKeyServiceType
    private let userService: UserServiceType
    private let parameterBuilder: RecordServiceParameterBuilderProtocol

    init(container: DIContainer) {
        do {
            self.sessionService = try container.resolve()
            self.cryptoService = try container.resolve()
            self.commonKeyService = try container.resolve()
            self.taggingService = try container.resolve()
            self.userService = try container.resolve()
            self.parameterBuilder = try container.resolve()
        } catch {
            fatalError(error.localizedDescription)
        }
    }

    func createRecord<DR: DecryptedRecord>(forResource resource: DR.Resource,
                                           annotations: [String] = [],
                                           userId: String,
                                           attachmentKey: Key? = nil,
                                           decryptedRecordType: DR.Type = DR.self) -> SDKFuture<DR> {
        func createRequest(parameters: Parameters) -> Router {
            return Router.createRecord(userId: userId, parameters: parameters)
        }

       return cryptoService
        .generateGCKey(.data)
        .flatMap { key in
            return self.uploadRecord(forResource: resource,
                                     userId: userId,
                                     dataKey: key,
                                     attachmentKey: attachmentKey,
                                     annotations: annotations,
                                     decryptedRecordType: decryptedRecordType,
                                     uploadRequest: createRequest) }
        .eraseToAnyPublisher()
        .asyncFuture()
    }

    func updateRecord<DR: DecryptedRecord>(forResource resource: DR.Resource,
                                           annotations: [String]? = nil,
                                           userId: String,
                                           recordId: String,
                                           attachmentKey: Key? = nil,
                                           decryptedRecordType: DR.Type = DR.self) -> SDKFuture<DR> {
        func updateRequest(parameters: Parameters) -> Router {
            return Router.updateRecord(userId: userId, recordId: recordId, parameters: parameters)
        }

        return combineAsync {
            let record = try combineAwait(self.fetchRecord(recordId: recordId, userId: userId, decryptedRecordType: decryptedRecordType))
            let updatedRecord = try combineAwait(self.uploadRecord(forResource: resource,
                                                                   userId: userId,
                                                                   dataKey: record.dataKey,
                                                                   attachmentKey: record.attachmentKey ?? attachmentKey,
                                                                   oldTags: record.tags,
                                                                   annotations: annotations ?? record.annotations,
                                                                   decryptedRecordType: decryptedRecordType,
                                                                   uploadRequest: updateRequest))
            return updatedRecord
        }
    }

    func fetchRecord<DR: DecryptedRecord>(recordId: String,
                                          userId: String,
                                          decryptedRecordType: DR.Type = DR.self) -> SDKFuture<DR> {
        return combineAsync {
            let route = Router.fetchRecord(userId: userId, recordId: recordId)
            let encrypted: EncryptedRecord = try combineAwait(self.sessionService.request(route: route).responseDecodable())
            let decryptedRecord = try DR.from(encryptedRecord: encrypted,
                                              cryptoService: self.cryptoService,
                                              commonKeyService: self.commonKeyService)
            return decryptedRecord
        }
    }

    func deleteRecord(recordId: String, userId: String) -> SDKFuture<Void> {
        return combineAsync {
            let route = Router.deleteRecord(userId: userId, recordId: recordId)
            return try combineAwait(self.sessionService.request(route: route).responseEmpty())
        }
    }

    func searchRecords<DR: DecryptedRecord>(for userId: String,
                                            from startDate: Date?,
                                            to endDate: Date?,
                                            pageSize: Int?,
                                            offset: Int?,
                                            annotations: [String] = [],
                                            decryptedRecordType: DR.Type = DR.self) -> SDKFuture<[DR]> {
        return combineAsync {
            let tagGroup = self.taggingService.makeTagGroup(for: DR.Resource.self, annotations: annotations)
            let parameters = try parameterBuilder.searchParameters(from: startDate,
                                                                   to: endDate,
                                                                   offset: offset,
                                                                   pageSize: pageSize,
                                                                   tagGroup: tagGroup,
                                                                   supportingLegacyTags: true)

            let route = Router.searchRecords(userId: userId, parameters: parameters)
            let encryptedRecords: [EncryptedRecord] = try combineAwait(
                self.sessionService.request(route: route).responseDecodable()
            )

            guard encryptedRecords.isEmpty == false else {
                return []
            }
            return try encryptedRecords.map {
                try DR.from(encryptedRecord: $0,
                            cryptoService: self.cryptoService,
                            commonKeyService: self.commonKeyService)
            }
        }
    }

    func countRecords<R: SDKResource>(userId: String, resourceType: R.Type, annotations: [String] = []) -> SDKFuture<Int> {
        return combineAsync {
            let tagGroup = self.taggingService.makeTagGroup(for: resourceType, annotations: annotations)
            let params = try parameterBuilder.searchParameters(tagGroup: tagGroup)
            let route = Router.countRecords(userId: userId, parameters: params)
            let headers = try combineAwait(self.sessionService.request(route: route).responseHeaders())

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
                                                   uploadRequest: @escaping (Parameters) -> Router) -> SDKFuture<DR> {
        return combineAsync {

            try combineAwait(self.userService.fetchUserInfo())
            let commonKeyId = self.commonKeyService.currentId ?? CommonKeyService.initialId
            guard let commonKey = self.commonKeyService.currentKey else {
                throw Data4LifeSDKError.missingCommonKey
            }

            let tagGroup = self.taggingService.makeTagGroup(for: resource, oldTags: oldTags ?? [:], annotations: annotations)

            let uploadParameters = try parameterBuilder.uploadParameters(resource: resource,
                                                                         uploadDate: Date(),
                                                                         commonKey: commonKey,
                                                                         commonKeyIdentifier: commonKeyId,
                                                                         dataKey: dataKey,
                                                                         attachmentKey: attachmentKey,
                                                                         tagGroup: tagGroup)
            let route = uploadRequest(uploadParameters)
            let encryptedRecord: EncryptedRecord = try combineAwait(
                self.sessionService.request(route: route).responseDecodable()
            )

            return try DR.from(encryptedRecord: encryptedRecord,
                               cryptoService: self.cryptoService,
                               commonKeyService: self.commonKeyService)
        }
    }
}
