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
@testable import Data4LifeSDK

public class Stubber {
    public var client: Data4LifeClient

    public func configure() {
        InteractiveURLProtocol.delegate = self
        InteractiveURLProtocol.storeResponses = false
    }

    public init() {
        let environment = D4LEnvironment.staging
        Router.baseUrl = environment.apiBaseString

        let clientConfig = ClientConfiguration(clientId: "xxxxxx",
                                               secret: "xxxxxxx",
                                               redirectURLString: "http://localhost",
                                               environment: environment)

        Resource.partnerId = try! clientConfig.partnerId()

        let container = Data4LifeDIContainer()
        container.registerDependencies(with: clientConfig)

        // Overrides registration of original dependencies with stubbed ones
        container.register(scope: .containerInstance) { (resolver) -> SessionService in
            let configuration = URLSessionConfiguration.default
            configuration.protocolClasses = [StubbedURLProtocol.self]

            return SessionService(configuration: configuration,
                                  versionValidator: try! resolver.resolve(),
                                  serverTrustManager: nil,
                                  interceptor: try? resolver.resolve())
        }.register(scope: .containerInstance) { (container) -> KeychainServiceType in
            let keychainName = ClientConfiguration.Keychain.baseName
            return KeychainService(container: container, name: keychainName, groupId: clientConfig.keychainGroupId)
        }

        client = Data4LifeClient(container: container,
                                 environment: environment)
    }
}

extension Stubber: InteractiveURLProtocolDelegate {
    func shouldRespond(to request: URLRequest) -> Data? {
        guard let urlString = request.url?.absoluteString, let method = request.httpMethod else { return nil }

        let response: StubbedResponse = .observation
        if urlString.contains("records"), method == "GET" {
            // if request contains `limit` param use it to create appropriate number of resources, otherwise return single resource
            if let queryComponents = request.url?.query?.components(separatedBy: "&"),
               let recordsQueryCount = queryComponents.filter({ $0.contains("limit") }).first?.components(separatedBy: "=").last {
                var results: [Any] = []
                for _ in 0..<Int(recordsQueryCount)! {
                    guard let object = try? JSONSerialization.jsonObject(with: response.data, options: .allowFragments) else {
                        fatalError()
                    }
                    results.append(object)
                }
                let payloadData = try! JSONSerialization.data(withJSONObject: results, options: .prettyPrinted)
                return payloadData
            } else {
                return response.data
            }
        } else if urlString.contains("records"), method == "POST" {
            return response.data
        } else if urlString.contains("token"), method == "GET" {
            return StubbedResponse.fetchDocumentReferenceToken.data
        } else if urlString.contains("blob"), method == "GET" {
            return StubbedResponse.fetchDocumentReferenceAttachmentBlob.data
        } else {
            return nil
        }
    }
}
