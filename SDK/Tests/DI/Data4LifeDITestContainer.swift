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

@testable import Data4LifeSDK
import Data4LifeCrypto

final class Data4LifeDITestContainer: DIContainer {}
extension Data4LifeDITestContainer {
    func registerDependencies() {

        register(scope: .containerInstance) { (_) -> SDKVersionValidatorType in
            SDKVersionValidatorMock()
        }.register(scope: .containerInstance) { (_) -> SDKFileManagerType in
            SDKFileManagerMock()
        }.register(scope: .containerInstance) { (_) -> InfoServiceType in
            InfoServiceMock()
        }.register(scope: .containerInstance) { (container) -> SessionService in
            SessionService.stubbedSessionService(versionValidator: try! container.resolve())
        }.register(scope: .containerInstance) { (_) -> KeychainServiceType in
            KeychainServiceMock()
        }.register(scope: .containerInstance) { (_) -> RecordServiceType in
            RecordServiceMock<Data4LifeFHIR.DocumentReference, DecryptedFhirStu3Record<Data4LifeFHIR.DocumentReference>>()
        }.register(scope: .containerInstance) { (_) -> OAuthServiceType in
            OAuthServiceMock()
        }.register(scope: .containerInstance) { (_) -> UserServiceType in
            UserServiceMock()
        }.register(scope: .containerInstance) { (_) -> CryptoServiceType in
            CryptoServiceMock()
        }.register(scope: .containerInstance) { (_) -> FhirServiceType in
            FhirServiceMock<DecryptedFhirStu3Record<Data4LifeFHIR.DocumentReference>, Attachment>()
        }.register(scope: .containerInstance) { (_) -> RequestInterceptorType in
            RequestInterceptorMock()
        }.register(scope: .containerInstance) { (_) -> DocumentServiceType in
            DocumentServiceMock()
        }.register(scope: .containerInstance) { (_) -> TaggingServiceType in
            TaggingServiceMock()
        }.register(scope: .containerInstance) { (_) -> AttachmentServiceType in
            AttachmentServiceMock()
        }.register(scope: .containerInstance) { (_) -> Bundle in
            Bundle(for: Data4LifeDITestContainer.self)
        }.register(scope: .containerInstance) { (_) -> Resizable in
            ImageResizerMock()
        }.register(scope: .containerInstance) { (_) -> PropertyListDecoder in
            PropertyListDecoder()
        }.register(scope: .containerInstance) { (_) -> UserDefaults in
            UserDefaults(suiteName: "Data4LifeTests")!
        }.register(scope: .containerInstance) { (_) -> CommonKeyServiceType in
            CommonKeyServiceMock()
        }.register(scope: .containerInstance) { (_) -> AppDataServiceType in
            AppDataServiceMock()
        }.register(scope: .containerInstance) { (_) -> InitializationVectorGeneratorProtocol in
            InitializationVectorGenerator()
        }
    }
}
