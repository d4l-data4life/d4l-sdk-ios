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
import Combine
import Data4LifeCrypto
@testable import Data4LifeSDK

enum DocumentServiceMockError: Error {
    case noResultSet
}

final class DocumentServiceMock: DocumentServiceType {

    var createDocumentCalledWith: (BlobDocument, Key)?
    var createDocumentResult: SDKFuture<BlobDocument>?
    var createDocumentResults: [SDKFuture<BlobDocument>]?
    func create(document: BlobDocument, key: Key) -> SDKFuture<BlobDocument> {
        createDocumentCalledWith = (document, key)
        if let results = createDocumentResults, let first = results.first {
            createDocumentResults = Array(results.dropFirst())
            return first
        }

        return createDocumentResult ?? Fail(error: DocumentServiceMockError.noResultSet).asyncFuture()
    }

    var createDocumentsCalledWith: ([BlobDocument], Key)?
    var createDocumentsResult: SDKFuture<[BlobDocument]>?
    func create(documents: [BlobDocument], key: Key) -> SDKFuture<[BlobDocument]> {
        createDocumentsCalledWith = (documents, key)
        return createDocumentsResult ?? Fail(error: DocumentServiceMockError.noResultSet).asyncFuture()
    }

    var fetchDocumentCalledWith: (String, Key, Progress)?
    var fetchDocumentResult: SDKFuture<BlobDocument>?
    func fetchDocument(withId identifier: String, key: Key, parentProgress: Progress) -> SDKFuture<BlobDocument> {
        fetchDocumentCalledWith = (identifier, key, parentProgress)
        return fetchDocumentResult ?? Fail(error: DocumentServiceMockError.noResultSet).asyncFuture()
    }

    var fetchDocumentsCalledWith: ([String], Key, Progress)?
    var fetchDocumentsResult: SDKFuture<[BlobDocument]>?
    func fetchDocuments(withIds identifiers: [String], key: Key, parentProgress: Progress) -> SDKFuture<[BlobDocument]> {
        fetchDocumentsCalledWith = (identifiers, key, parentProgress)
        return fetchDocumentsResult ?? Fail(error: DocumentServiceMockError.noResultSet).asyncFuture()
    }

    var deleteDocumentCalledWith: (String)?
    var deleteDocumentResult: SDKFuture<Void>?
    func deleteDocument(withId id: String) -> SDKFuture<Void> {
        deleteDocumentCalledWith = (id)
        return deleteDocumentResult ?? Fail(error: DocumentServiceMockError.noResultSet).asyncFuture()
    }

    var deleteDocumentsCalledWith: ([String])?
    var deleteDocumentsResult: SDKFuture<Void>?
    func deleteDocuments(withIds identifiers: [String]) -> SDKFuture<Void> {
        deleteDocumentsCalledWith = (identifiers)
        return deleteDocumentsResult ?? Fail(error: DocumentServiceMockError.noResultSet).asyncFuture()
    }
}
