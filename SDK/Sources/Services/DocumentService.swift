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
import Alamofire

protocol DocumentServiceType {
    func create(document: Document, key: Key) -> Promise<Document>
    func create(documents: [Document], key: Key) -> Promise<[Document]>
    func fetchDocument(withId identifier: String, key: Key, parentProgress: Progress) -> Promise<Document>
    func fetchDocuments(withIds identifiers: [String], key: Key, parentProgress: Progress) -> Promise<[Document]>
    func deleteDocument(withId: String) -> Promise<Void>
    func deleteDocuments(withIds identifiers: [String]) -> Promise<[Void]>
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

    func create(document: Document, key: Key) -> Promise<Document> {
        return async {
            let userId = try await(self.keychainService.get(.userId))
            let encryptedData = try self.cryptoService.encrypt(data: document.data, key: key)
            let route = Router.createDocument(userId: userId, headers: [("Content-Type", "application/octet-stream")])
            let response: DocumentResponse = try await(self.sessionService.upload(data: encryptedData, route: route).responseDecodable())
            return Document(id: response.identifier, data: document.data)
        }
    }

    func fetchDocument(withId identifier: String, key: Key, parentProgress: Progress) -> Promise<Document> {

        return Async { (resolve: @escaping (Document) -> Void, reject: @escaping (Error) -> Void) in

            do {
                let userId = try await(self.keychainService.get(.userId))
                let route = Router.fetchDocument(userId: userId, documentId: identifier)
                let request = try self.sessionService.request(route: route)

                // This needs the Content-Length header in order to get totalUnitCount's progress working
                parentProgress.addChild(request.progress, withPendingUnitCount: 1)

                // This provides cancel functionality
                request.progress.cancellationHandler = { [weak request] in
                    request?.cancel()
                    reject(URLError.init(URLError.cancelled))
                }

                let encryptedData = try await(request.responseData())
                let decryptedData = try self.cryptoService.decrypt(data: encryptedData, key: key)
                resolve(Document(id: identifier, data: decryptedData))
            } catch {
                reject(error)
            }
        }
    }

    func deleteDocument(withId identifier: String) -> Promise<Void> {
        return async {
            let userId = try await(self.keychainService.get(.userId))
            let route = Router.deleteDocument(userId: userId, documentId: identifier)
            return try await(self.sessionService.request(route: route).responseEmpty())
        }
    }

    func deleteDocuments(withIds identifiers: [String]) -> Promise<[Void]> {
        let requests = identifiers.map { self.deleteDocument(withId: $0) }
        return Promises.whenAll(requests)
    }

    func fetchDocuments(withIds identifiers: [String], key: Key, parentProgress: Progress) -> Promise<[Document]> {
        let requests = identifiers.map { self.fetchDocument(withId: $0, key: key, parentProgress: parentProgress) }
        return Promises.whenAll(requests)
    }

    func create(documents: [Document], key: Key) -> Promise<[Document]> {
        let requests = documents.map { self.create(document: $0, key: key) }
        return Promises.whenAll(requests)
    }
}
