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

final class ErasedSDKResource: Equatable {

    var resource: Any
    init<T: SDKResource>(resource: T) {
        self.resource = resource
    }

    func getValue<T: SDKResource>(as type: T.Type = T.self) -> T {
        resource as! T
    }

    static var searchTags: [String : String] {
        return [:]
    }

    static var modelVersion: Int { 1 }
    static func == (lhs: ErasedSDKResource, rhs: ErasedSDKResource) -> Bool {
        return lhs.getValue() == rhs.getValue()
    }

    static func make<T: SDKResource>(from resource: T) -> ErasedSDKResource {
        return ErasedSDKResource(resource: resource)
    }
}

extension SDKResource {

    var erased: ErasedSDKResource { ErasedSDKResource(resource: self)}
}
