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
import Then
import Data4LifeCrypto
@testable import Data4LifeSDK

class DocumentServiceMock: DocumentServiceType {

    var createDocumentCalledWith: (Document, Key)?
    var createDocumentResult: Promise<Document>?
    var createDocumentResults: [Promise<Document>]?
    func create(document: Document, key: Key) -> Promise<Document> {
        createDocumentCalledWith = (document, key)
        if let results = createDocumentResults, let first = results.first {
            createDocumentResults = Array(results.dropFirst())
            return first
        }

        return createDocumentResult ?? Promise.reject()
    }

    var createDocumentsCalledWith: ([Document], Key)?
    var createDocumentsResult: Promise<[Document]>?
    func create(documents: [Document], key: Key) -> Promise<[Document]> {
        createDocumentsCalledWith = (documents, key)
        return createDocumentsResult ?? Promise.reject()
    }

    var fetchDocumentCalledWith: (String, Key, Progress)?
    var fetchDocumentResult: Promise<Document>?
    func fetchDocument(withId identifier: String, key: Key, parentProgress: Progress) -> Promise<Document> {
        fetchDocumentCalledWith = (identifier, key, parentProgress)
        return fetchDocumentResult ?? Promise.reject()
    }

    var fetchDocumentsCalledWith: ([String], Key, Progress)?
    var fetchDocumentsResult: Promise<[Document]>?
    func fetchDocuments(withIds identifiers: [String], key: Key, parentProgress: Progress) -> Promise<[Document]> {
        fetchDocumentsCalledWith = (identifiers, key, parentProgress)
        return fetchDocumentsResult ?? Promise.reject()
    }

    var deleteDocumentCalledWith: (String)?
    var deleteDocumentResult: Promise<Void>?
    func deleteDocument(withId id: String) -> Promise<Void> {
        deleteDocumentCalledWith = (id)
        return deleteDocumentResult ?? Promise.reject()
    }

    var deleteDocumentsCalledWith: ([String])?
    var deleteDocumentsResult: Promise<[Void]>?
    func deleteDocuments(withIds identifiers: [String]) -> Promise<[Void]> {
        deleteDocumentsCalledWith = (identifiers)
        return deleteDocumentsResult ?? Promise.reject()
    }
}
