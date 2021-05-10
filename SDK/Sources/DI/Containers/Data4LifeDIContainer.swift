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

final class Data4LifeDIContainer: DIContainer { }

extension Data4LifeDIContainer {

    func registerDependencies(with clientConfiguration: ClientConfiguration) {

        do {
            try registerGlobalDependencies(using: clientConfiguration.loggerConfiguration)
            try register(scope: .transientInstance) { (_) -> Foundation.Bundle in
                Bundle(for: Data4LifeDIContainer.self)
            }.register(scope: .transientInstance) { (_) -> PropertyListDecoder in
                PropertyListDecoder()
            }.register(scope: .transientInstance) { (container) -> InfoServiceType in
                InfoService(container: container)
            }.register(scope: .transientInstance) { (_) -> UserDefaults in
                UserDefaults(suiteName: clientConfiguration.appGroupId) ?? UserDefaults.standard
            }.register(scope: .containerInstance) { (container) -> KeychainServiceType in
                let keychainName = try clientConfiguration.keychainName()
                return KeychainService(container: container, name: keychainName, groupId: clientConfiguration.keychainGroupId)
            }.register(scope: .containerInstance) { (container) -> RequestInterceptorType in
                let infoService: InfoServiceType = try container.resolve()
                let sdkVersion = infoService.fetchSDKVersion()
                return SessionServiceInterceptor(keychainService: try container.resolve(),
                                                 sdkVersion: sdkVersion)
            }.register(scope: .transientInstance) { (_) -> SDKFileManagerType in
                SDKFileManager()
            }.register(scope: .containerInstance) { (container) -> SDKVersionValidatorType in
                SDKVersionValidator(container: container)
            }.register(scope: .containerInstance) { (container) -> SessionService in
                SessionService(hostname: try clientConfiguration.environmentHost(),
                               sdkBundle: try container.resolve(),
                               versionValidator: try container.resolve(),
                               interceptor: try container.resolve())
            }.register(scope: .containerInstance) { (container) -> OAuthServiceType in
                let authURL = try Router.authorizeUrl()
                let tokenURL = try Router.fetchTokenUrl()
                let redirectUrl = try clientConfiguration.redirectURL()

                return OAuthService(clientId: clientConfiguration.clientId,
                                    clientSecret: clientConfiguration.secret,
                                    redirectURL: redirectUrl,
                                    authURL: authURL,
                                    tokenURL: tokenURL,
                                    keychainService: try container.resolve(),
                                    sessionService: try container.resolve())
            }.register(scope: .containerInstance) { _ -> TaggingServiceType in
                let partnerId = try clientConfiguration.partnerId()
                return TaggingService(clientId: clientConfiguration.clientId,
                                      partnerId: partnerId)
            }.register(scope: .containerInstance) { (container) -> CryptoServiceType in
                let keyPairTag = "de.gesundheitscloud.keypair"
                return CryptoService(container: container, keyPairTag: keyPairTag)
            }.register(scope: .containerInstance) { (container) -> CommonKeyServiceType in
                CommonKeyService(container: container)
            }.register(scope: .containerInstance) { (container) -> UserServiceType in
                UserService(container: container)
            }.register(scope: .containerInstance) { (container) -> DocumentServiceType in
                DocumentService(container: container)
            }.register(scope: .containerInstance) { (container) -> AttachmentServiceType in
                AttachmentService(container: container)
            }.register(scope: .transientInstance) { (_) -> Resizable in
                ImageResizer()
            }.register(scope: .containerInstance) { (container) -> RecordServiceType in
                RecordService(container: container)
            }.register(scope: .containerInstance) { (container) -> FhirServiceType in
                FhirService(container: container)
            }.register(scope: .containerInstance) { (container) -> AppDataServiceType in
                AppDataService(container: container)
            }.register(scope: .containerInstance) { (_) -> InitializationVectorGeneratorProtocol in
                InitializationVectorGenerator()
            }.register(scope: .containerInstance) { (container) -> RecordServiceParameterBuilder in
                RecordServiceParameterBuilder(container: container)
            }
        } catch {
            fatalError(error.localizedDescription)
        }
    }

    private func registerGlobalDependencies(using loggerConfiguration: LoggerConfiguration) throws {
        try register(scope: .transientInstance) { _ -> LoggerContainer in
            let loggerContainer = LoggerContainer()
            loggerContainer.registerDependencies(with: loggerConfiguration)
            return loggerContainer
        }.register(scope: .transientInstance) { resolver -> LoggerService in
            let loggerContainer: LoggerContainer = try resolver.resolve()
            let loggerService: LoggerService = try loggerContainer.resolve()
            return loggerService
        }
    }
}
