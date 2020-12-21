//
//  AnySDKResource.swift
//  Data4LifeSDKTests
//
//  Created by Alessio Borraccino on 15.12.20.
//  Copyright © 2020 HPS Gesundheitscloud gGmbH. All rights reserved.
//

import Foundation
@testable import Data4LifeSDK

final class AnySDKResource<T: SDKResource>: SDKResource, Equatable {
    var resource: T?

    init(resource: T?) {
        self.resource = resource
    }

    static var searchTags: [String : String] {
        return [:]
    }

    static var modelVersion: Int { 1 }
    static func == (lhs: AnySDKResource, rhs: AnySDKResource) -> Bool {
        let encoder = JSONEncoder()
        let lhsJson = try? encoder.encode(lhs.resource)
        let rhsJson = try? encoder.encode(rhs.resource)
        return lhsJson == rhsJson
    }

    static func make(from resource: T?) -> AnySDKResource<T> {
        return AnySDKResource<T>(resource: resource)
    }
}
