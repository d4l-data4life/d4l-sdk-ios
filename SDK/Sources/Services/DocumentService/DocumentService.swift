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
@_implementationOnly import Data4LifeCrypto
@_implementationOnly import Alamofire
import Combine

protocol DocumentServiceType {
    func create(document: AttachmentDocument, key: Key) -> SDKFuture<AttachmentDocument>
    func create(documents: [AttachmentDocument], key: Key) -> SDKFuture<[AttachmentDocument]>
    func fetchDocument(withId identifier: String, key: Key, parentProgress: Progress) -> SDKFuture<AttachmentDocument>
    func fetchDocuments(withIds identifiers: [String], key: Key, parentProgress: Progress) -> SDKFuture<[AttachmentDocument]>
    func deleteDocument(withId: String) -> SDKFuture<Void>
    func deleteDocuments(withIds identifiers: [String]) -> SDKFuture<Void>
}

class DocumentService: DocumentServiceType {

    let sessionService: SessionService
    let cryptoService: CryptoServiceType
    let keychainService: KeychainServiceType
    private var observations: [NSKeyValueObservation] = []

    init(container: DIContainer) {
        do {
            self.sessionService = try container.resolve()
            self.cryptoService = try container.resolve()
            self.keychainService = try container.resolve()
        } catch {
            fatalError(error.localizedDescription)
        }
    }

    func create(document: AttachmentDocument, key: Key) -> SDKFuture<AttachmentDocument> {
        return combineAsync {
            guard let data = document.data else {
                throw Data4LifeSDKError.invalidAttachmentMissingData
            }
            let userId = try self.keychainService.get(.userId)
            let encryptedData = try self.cryptoService.encrypt(data: data, key: key)
            let route = Router.createDocument(userId: userId, headers: [("Content-Type", "application/octet-stream")])
            let response: DocumentResponse = try combineAwait(self.sessionService.upload(data: encryptedData, route: route).responseDecodable())
            return AttachmentDocument(id: response.identifier, data: document.data)
        }
    }

    func fetchDocument(withId identifier: String, key: Key, parentProgress: Progress) -> SDKFuture<AttachmentDocument> {

        return SDKFuture { promise in
            do {
                let userId = try self.keychainService.get(.userId)
                let route = Router.fetchDocument(userId: userId, documentId: identifier)
                let request = try self.sessionService.request(route: route)

                // This needs the Content-Length header in order to get totalUnitCount's progress working
                parentProgress.addChild(request.downloadProgress, withPendingUnitCount: 1)

                // This provides cancel functionality
                request.downloadProgress.cancellationHandler = { [weak request] in
                    request?.cancel()
                    promise(.failure(Data4LifeSDKError.downloadActionWasCancelled))
                }

                let encryptedData = try combineAwait(request.responseData())
                let decryptedData = try self.cryptoService.decrypt(data: encryptedData, key: key)
                promise(.success(AttachmentDocument(id: identifier, data: decryptedData)))
            } catch {
                promise(.failure(error))
            }
        }.asyncFuture()
    }

    func deleteDocument(withId identifier: String) -> SDKFuture<Void> {
        return combineAsync {
            let userId = try self.keychainService.get(.userId)
            let route = Router.deleteDocument(userId: userId, documentId: identifier)
            return try combineAwait(self.sessionService.request(route: route).responseEmpty())
        }
    }

    func deleteDocuments(withIds identifiers: [String]) -> SDKFuture<Void> {
        let requests = identifiers.map { self.deleteDocument(withId: $0) }
        return Publishers.MergeMany(requests).last().eraseToAnyPublisher().asyncFuture()
    }

    func fetchDocuments(withIds identifiers: [String], key: Key, parentProgress: Progress) -> SDKFuture<[AttachmentDocument]> {
        let requests = identifiers.map { self.fetchDocument(withId: $0, key: key, parentProgress: parentProgress) }
        return Publishers.MergeMany(requests).collect().eraseToAnyPublisher().asyncFuture()
    }

    func create(documents: [AttachmentDocument], key: Key) -> SDKFuture<[AttachmentDocument]> {
        let requests = documents.map { self.create(document: $0, key: key) }
        return Publishers.MergeMany(requests).collect().eraseToAnyPublisher().asyncFuture()
    }
}