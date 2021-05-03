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

import XCTest
@testable import Data4LifeSDK
import Then
import Data4LifeFHIR
import Data4LifeCrypto

class DocumentServiceTests: XCTestCase {

    var sessionService: SessionService!
    var keychainService: KeychainServiceMock!
    var cryptoService: CryptoServiceMock!
    var documentService: DocumentService!
    var versionValidator: SDKVersionValidatorMock!

    override func setUp() {
        super.setUp()

        let container = Data4LifeDITestContainer()
        container.registerDependencies()
        documentService = DocumentService(container: container)

        do {
            sessionService = try container.resolve()
            keychainService = try container.resolve(as: KeychainServiceType.self)
            cryptoService = try container.resolve(as: CryptoServiceType.self)
            versionValidator = try container.resolve(as: SDKVersionValidatorType.self)
        } catch {
            XCTFail(error.localizedDescription)
        }

        Router.baseUrl = "https://example.com"
        versionValidator.fetchCurrentVersionStatusResult = Async.resolve(.supported)
    }

    func testCreateSingleDocument() {
        let userId = UUID().uuidString
        let documentId = UUID().uuidString
        let data = Data([0x00, 0x00])
        let encryptedData = Data([0x01, 0x01, 0x01])
        let key = KeyFactory.createKey(.attachment)
        let document = Document(data: data)
        let documentResponse = DocumentResponse(identifier: documentId)
        let responseData = try! JSONEncoder().encode(documentResponse)

        keychainService[.userId] = userId
        cryptoService.encryptDataResult = encryptedData
        stub("POST", "/users/\(userId)/documents", with: responseData)

        let asyncExpectation = expectation(description: "Should create a document")
        documentService.create(document: document, key: key)
            .then { result in
                XCTAssertEqual(result.id, documentId)
                XCTAssertEqual(result.data, data)
                XCTAssertRouteCalled("POST", "/users/\(userId)/documents")
                XCTAssertRequestDataEquals("POST", "/users/\(userId)/documents", with: encryptedData as Any)
            }.onError { error in
                XCTFail(String(describing: error))
            }.finally {
                asyncExpectation.fulfill()
        }

        wait(for: [asyncExpectation], timeout: 5)
    }

    func testCreateDocuments() {
        let userId = UUID().uuidString
        let documentId = UUID().uuidString
        let data = Data([0x00, 0x00])
        let encryptedData = Data([0x01, 0x01, 0x01])
        let key = KeyFactory.createKey(.attachment)
        let document = Document(data: data)
        let documentResponse = DocumentResponse(identifier: documentId)
        let responseData = try! JSONEncoder().encode(documentResponse)

        keychainService[.userId] = userId
        cryptoService.encryptDataResult = encryptedData
        stub("POST", "/users/\(userId)/documents", with: responseData)

        let asyncExpectation = expectation(description: "Should create a document")
        documentService.create(documents: [document], key: key)
            .then { result in
                XCTAssertEqual(result.first?.id, documentId)
                XCTAssertEqual(result.first?.data, data)
                XCTAssertRouteCalled("POST", "/users/\(userId)/documents")
                XCTAssertRequestDataEquals("POST", "/users/\(userId)/documents", with: encryptedData as Any)
            }.onError { error in
                XCTFail(String(describing: error))
            }.finally {
                asyncExpectation.fulfill()
        }

        wait(for: [asyncExpectation], timeout: 5)
    }

    func testFetchDocuments() {
        let progress = Progress()
        let userId = UUID().uuidString
        let documentId = UUID().uuidString
        let data = Data([0x00, 0x00])
        let encryptedData = Data([0x01, 0x01, 0x01])
        let key = KeyFactory.createKey(.attachment)

        keychainService[.userId] = userId
        cryptoService.decryptDataResult = data
        stub("GET", "/users/\(userId)/documents/\(documentId)", with: encryptedData)

        let asyncExpectation = expectation(description: "Should fetch a document")
        documentService.fetchDocuments(withIds: [documentId], key: key, parentProgress: progress)
            .then { result in
                XCTAssertEqual(result.first?.id, documentId)
                XCTAssertEqual(result.first?.data, data)
                XCTAssertRouteCalled("GET", "/users/\(userId)/documents/\(documentId)")
            }.onError { error in
                XCTFail(String(describing: error))
            }.finally {
                asyncExpectation.fulfill()
        }

        wait(for: [asyncExpectation], timeout: 5)
    }

    func testFetchDocumentCancellingRequest() {
        let progress = Progress()
        let userId = UUID().uuidString
        let documentId = UUID().uuidString
        let data = Data([0x00, 0x00])
        let encryptedData = Data([0x01, 0x01, 0x01])
        let key = KeyFactory.createKey(.attachment)

        keychainService[.userId] = userId
        cryptoService.decryptDataResult = data
        stub("GET", "/users/\(userId)/documents/\(documentId)", with: encryptedData)

        let asyncExpectation = expectation(description: "Should throw error cancelled download")
        documentService.fetchDocumentDelayed(withId: documentId, key: key, parentProgress: progress)
            .then { _ in
                XCTFail("Should return an error")
            }.onError { error in
                XCTAssertEqual((error as? URLError)?.code, URLError.cancelled)
            }.finally {
                asyncExpectation.fulfill()
        }

        progress.cancel()

        wait(for: [asyncExpectation], timeout: 5)
    }

    func testDeleteDocument() {
        let userId = UUID().uuidString
        let documentId = UUID().uuidString

        keychainService[.userId] = userId
        stub("DELETE", "/users/\(userId)/documents/\(documentId)", with: [])

        let asyncExpectation = expectation(description: "Should fetch a document")
        documentService.deleteDocument(withId: documentId)
            .then {
                XCTAssertRouteCalled("DELETE", "/users/\(userId)/documents/\(documentId)")
            }.onError { error in
                XCTFail(String(describing: error))
            }.finally {
                asyncExpectation.fulfill()
        }

        wait(for: [asyncExpectation], timeout: 5)
    }

    func testFetchDocumentsFailsUnsupportedVersion() {
        let progress = Progress()
        let userId = UUID().uuidString
        let documentId = UUID().uuidString
        let key = KeyFactory.createKey(.attachment)

        keychainService[.userId] = userId
        versionValidator.fetchCurrentVersionStatusResult = Async.resolve(.unsupported)
        let expectedError = Data4LifeSDKError.unsupportedVersionRunning

        let asyncExpectation = expectation(description: "Should fetch a document")
        documentService.fetchDocuments(withIds: [documentId], key: key, parentProgress: progress)
            .then { _ in
                XCTFail("Should return an error")
            }.onError { error in
                XCTAssertEqual(error as? Data4LifeSDKError, expectedError)
            }.finally {
                asyncExpectation.fulfill()
        }

        wait(for: [asyncExpectation], timeout: 5)
    }
}

fileprivate extension DocumentService {

    func fetchDocumentDelayed(withId identifier: String, key: Key, parentProgress: Progress) -> Promise<Document> {

        return Async { (resolve: @escaping (Document) -> Void, reject: @escaping (Error) -> Void) in

            do {
                let userId = try wait(self.keychainService.get(.userId))
                let route = Router.fetchDocument(userId: userId, documentId: identifier)
                let request = try self.sessionService.request(route: route)

                // This needs the Content-Length header in order to get totalUnitCount's progress working
                parentProgress.addChild(request.downloadProgress, withPendingUnitCount: 1)

                // This provides cancel functionality
                request.downloadProgress.cancellationHandler = { [weak request] in
                    request?.cancel()
                    reject(URLError.init(URLError.cancelled))
                }

                let encryptedData = try wait(request.responseData())
                let decryptedData = try self.cryptoService.decrypt(data: encryptedData, key: key)
                DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + 5) {
                    resolve(Document(id: identifier, data: decryptedData))
                }
            } catch {
                reject(error)
            }
        }
    }
}
