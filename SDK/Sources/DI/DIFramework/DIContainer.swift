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

typealias DIServiceBuilder = (DIContainer) throws -> Any

class DIContainer {

    private var transientInstanceBuilders = [String: DIServiceBuilder]()

    private var containerInstanceBuilders = [String: DIServiceBuilder]()
    private var containerInstances = [String: Any]()

    private var globalInstanceBuilders = [String: DIServiceBuilder]()
    static private var globalInstances = [String: Any]()

    @discardableResult
    func register<Service>(_ type: Service.Type = Service.self,
                           scope: Scope,
                           _ builder: @escaping (DIContainer) throws -> Service) rethrows -> DIContainer {
        let key = classKey(for: type)
        switch scope {
        case .globalInstance:
            globalInstanceBuilders[key] = builder
        case .containerInstance:
            containerInstanceBuilders[key] = builder
        case .transientInstance:
            transientInstanceBuilders[key] = builder
        }
        return self
    }

    func cleanGlobalInstances() {
        DIContainer.globalInstances = [:]
    }
}

extension DIContainer: DIResolver {

    func resolve<Service>() throws -> Service {
        return try resolve(as: Service.self)
    }

    func resolve<Service, OtherService>(as otherService: OtherService.Type) throws -> Service {

        let key = classKey(for: otherService)

        guard let builderAndScope = registeredBuilderAndScope(for: key) else {
            throw DIContainer.Error.noDependencyRegistered(name: key)
        }

        var instance: Service?

        switch builderAndScope.scope {
        case .globalInstance:
            if let existingInstance = DIContainer.globalInstances[key] as? Service?, existingInstance != nil {
                instance = existingInstance
            } else {
                instance = try builderAndScope.builder(self) as? Service
                DIContainer.globalInstances[key] = instance
            }
        case .containerInstance:
            if let existingInstance = containerInstances[key] as? Service?, existingInstance != nil {
                instance = existingInstance
            } else {
                instance = try builderAndScope.builder(self) as? Service
                containerInstances[key] = instance
            }
        case .transientInstance:
            instance = try builderAndScope.builder(self) as? Service
        }

        guard let service = instance else {
            throw DIContainer.Error.couldNotBuildRegisteredDependency(name: key)
        }

        return service
    }
}

extension DIContainer {
    private func classKey(for type: Any.Type) -> String {
        if let wrapper = type as? Wrapper.Type {
            return String(describing: wrapper.wrappedType)
        } else {
            return String(describing: type)
        }
    }

    private func registeredBuilderAndScope(for key: String) -> (builder: DIServiceBuilder, scope: Scope)? {
        if let instanceBuilder = globalInstanceBuilders[key] {
            return (instanceBuilder, .globalInstance)
        }
        if let instanceBuilder = containerInstanceBuilders[key] {
            return (instanceBuilder, .containerInstance)
        }
        if let instanceBuilder = transientInstanceBuilders[key] {
            return (instanceBuilder, .transientInstance)
        }
        return nil
    }
}
