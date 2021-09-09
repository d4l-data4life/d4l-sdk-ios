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
import Alamofire
import SafariServices
import Combine
@testable import Data4LifeSDK
import ModelsR4
import Data4LifeCrypto

class Data4LifeClientFhirR4Tests: XCTestCase {
    var client: Data4LifeClient!

    var sessionService: SessionService!
    var oAuthService: OAuthServiceMock!
    var userService: UserServiceMock!
    var cryptoService: CryptoServiceMock!
    var commonKeyService: CommonKeyServiceMock!
    var fhirService: FhirServiceMock<DecryptedFhirR4Record<ModelsR4.DocumentReference>, ModelsR4.Attachment>!
    var appDataService: AppDataServiceMock!
    var keychainService: KeychainServiceMock!
    var recordService: RecordServiceMock<ModelsR4.DocumentReference,DecryptedFhirR4Record<ModelsR4.DocumentReference>>!
    var environment: Environment!
    var versionValidator: SDKVersionValidatorMock!

    override func setUp() {
        super.setUp()

        environment = .development

        let container = Data4LifeDITestContainer()
        container.registerDependencies()
        container.register(scope: .containerInstance) { (_) -> FhirServiceType in
            FhirServiceMock<DecryptedFhirR4Record<ModelsR4.DocumentReference>, ModelsR4.Attachment>()
        }
        container.register(scope: .containerInstance) { (_) -> RecordServiceType in
            RecordServiceMock<ModelsR4.DocumentReference, DecryptedFhirR4Record<ModelsR4.DocumentReference>>()
        }
        self.client = Data4LifeClient(container: container,
                                      environment: environment,
                                      platform: .d4l)

        do {
            self.sessionService = try container.resolve()
            self.oAuthService = try container.resolve(as: OAuthServiceType.self)
            self.userService = try container.resolve(as: UserServiceType.self)
            self.cryptoService = try container.resolve(as: CryptoServiceType.self)
            self.commonKeyService = try container.resolve(as: CommonKeyServiceType.self)
            self.fhirService = try container.resolve(as: FhirServiceType.self)
            self.recordService = try container.resolve(as: RecordServiceType.self)
            self.keychainService = try container.resolve(as: KeychainServiceType.self)
            self.versionValidator = try container.resolve(as: SDKVersionValidatorType.self)
            self.appDataService = try container.resolve(as: AppDataServiceType.self)
        } catch {
            XCTFail(error.localizedDescription)
        }

        self.keychainService[.userId] = UUID().uuidString
        fhirService.keychainService = keychainService
        fhirService.recordService = recordService
        fhirService.cryptoService = cryptoService
        appDataService.keychainService = keychainService
        appDataService.recordService = recordService
        appDataService.cryptoService = cryptoService
    }

    override func tearDown() {
        super.tearDown()
        clearStubs()
    }
}

extension Data4LifeClientFhirR4Tests {

    func testCreateResourceWithAnnotations() {
        let annotations = [UUID().uuidString]
        let resource = FhirFactory.createR4DocumentReferenceResource()
        let record = RecordFactory.create(resource, annotations: annotations)
        fhirService.createFhirRecordResult = Just(record).asyncFuture()

        let asyncExpectation = expectation(description: "Should return success result")
        client.createFhirR4Record(resource, annotations: annotations) { result in
            defer { asyncExpectation.fulfill() }
            XCTAssertNil(result.error)
            XCTAssertNotNil(result.value)
            XCTAssertEqual(result.value?.fhirResource, resource)
            XCTAssertEqual(result.value?.annotations, annotations)
            XCTAssertEqual(self.fhirService.createFhirRecordCalledWith?.0, resource)
            XCTAssertEqual(self.fhirService.createFhirRecordCalledWith?.1, annotations)
        }

        waitForExpectations(timeout: 5)
    }

    func testUpdateResource() {
        let annotations = [UUID().uuidString]
        let updateResource = FhirFactory.createR4DocumentReferenceResource()
        let record = RecordFactory.create(updateResource, annotations: annotations)

        fhirService.updateFhirRecordResult = Just(record).asyncFuture()

        let asyncExpectation = expectation(description: "Should return success result")
        client.updateFhirR4Record(updateResource, annotations: annotations) { result in
            defer { asyncExpectation.fulfill() }

            XCTAssertNil(result.error)
            XCTAssertNotNil(result.value)
            XCTAssertEqual(result.value?.fhirResource, updateResource)
            XCTAssertEqual(result.value?.annotations, annotations)

            XCTAssertEqual(self.fhirService.updateFhirRecordCalledWith?.0, updateResource)
            XCTAssertEqual(self.fhirService.updateFhirRecordCalledWith?.1, annotations)
        }

        waitForExpectations(timeout: 5)
    }

    func testFetchResource() {
        let resource = FhirFactory.createR4DocumentReferenceResource()
        let resourceId = UUID().uuidString
        resource.id = resourceId.asFHIRStringPrimitive()
        let record = RecordFactory.create(resource)

        fhirService.fetchRecordWithIdResult = Just(record).asyncFuture()

        let asyncExpectation = expectation(description: "Should return success result")
        client.fetchFhirR4Record(withId: resourceId, of: ModelsR4.DocumentReference.self) { result in
            defer { asyncExpectation.fulfill() }

            XCTAssertNil(result.error)
            XCTAssertNotNil(result.value)
            XCTAssertEqual(result.value?.fhirResource, resource)
            XCTAssertEqual(self.fhirService.fetchRecordWithIdCalledWith?.0.asFHIRStringPrimitive(), resource.id)
        }

        waitForExpectations(timeout: 5)
    }

    func testDeleteResource() {
        let resourceId = UUID().uuidString
        fhirService.deleteRecordResult = Just(()).asyncFuture()

        let asyncExpectation = expectation(description: "Should return success result")
        client.deleteFhirR4Record(withId: resourceId) { result in
            defer { asyncExpectation.fulfill() }

            XCTAssertNil(result.error)
            XCTAssertNotNil(result.value)
            XCTAssertEqual(self.fhirService.deleteRecordCalledWith, resourceId)
        }

        waitForExpectations(timeout: 5)
    }

    func testSearchResources() {
        let annotations = [UUID().uuidString]
        let resources = [FhirFactory.createR4DocumentReferenceResource(), FhirFactory.createR4DocumentReferenceResource()]
        let records = resources.map { RecordFactory.create($0, annotations: annotations) }
        fhirService.fetchRecordsResult = Just(records).asyncFuture()

        let asyncExpectation = expectation(description: "Should return success result")
        client.fetchFhirR4Records(of: ModelsR4.DocumentReference.self, annotations: annotations) { result in
            defer { asyncExpectation.fulfill() }

            XCTAssertNil(result.error)
            XCTAssertNotNil(result.value)
            XCTAssertEqual(result.value?.first?.fhirResource, records.first?.fhirResource)
            XCTAssertEqual(result.value?.last?.fhirResource, records.last?.fhirResource)
            XCTAssertEqual(result.value?.first?.annotations, annotations)
            XCTAssertEqual(result.value?.last?.annotations, annotations)
            XCTAssertEqual(self.fhirService.fetchRecordsCalledWith?.3, annotations)
        }

        waitForExpectations(timeout: 5)
    }

    func testCountResources() {
        let annotations = [UUID().uuidString]
        let resourceCount = 2
        let resourceType = ModelsR4.DocumentReference.self

        fhirService.countRecordsResult = Just(resourceCount).asyncFuture()

        let asyncExpectation = expectation(description: "Should return success result")
        client.countFhirR4Records(of: resourceType, annotations: annotations) { result in
            defer { asyncExpectation.fulfill() }

            XCTAssertNil(result.error)
            XCTAssertNotNil(result.value)
            XCTAssertEqual(result.value, resourceCount)
            XCTAssertEqual(self.fhirService.countRecordsCalledWith?.1, annotations)
        }

        waitForExpectations(timeout: 5)
    }
}
