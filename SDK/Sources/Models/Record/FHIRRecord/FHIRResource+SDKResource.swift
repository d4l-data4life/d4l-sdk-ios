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
import Data4LifeFHIRCore
import Data4LifeFHIR
import ModelsR4

protocol SDKResource: ModelVersionInformation, Codable {
    static var searchTags: [String: String] { get }
}

protocol FhirSDKResource: AnyFhirResource, SDKResource {
    var fhirIdentifier: String? { get set }
    static var fhirVersion: String { get }
    static var resourceTypeString: String { get }
    static var baseResourceTypeString: String { get }
}

extension FhirSDKResource {
    static var searchTags: [String : String] {
        var tags = [String: String]()
        if Self.resourceTypeString != baseResourceTypeString {
            tags[TaggingService.Keys.resourceType.rawValue] = Self.resourceTypeString
        }
        tags[TaggingService.Keys.fhirVersion.rawValue] = Self.fhirVersion
        return tags.lowercased
    }
}

extension FhirSDKResource {
    func map<R: FhirSDKResource>(to type: R.Type) throws -> R {
        guard let mapped = self as? R else {
            throw Data4LifeSDKError.invalidResourceCouldNotConvertToType(String(describing: type))
        }
        return mapped
    }
}

extension Optional where Wrapped == FhirSDKResource {
    func map<R: FhirSDKResource>(to type: R.Type) throws -> R {
        guard let resource = self else { throw Data4LifeSDKError.invalidRecordMissingResource }
        return try resource.map(to: R.self)
    }
}

extension FhirStu3Resource: FhirSDKResource {

    static var baseResourceTypeString: String { FhirStu3Resource.resourceType }
    static var resourceTypeString: String { Self.resourceType }

    var fhirIdentifier: String? {
        get { id }
        set { id = newValue }
    }
}

extension FhirR4Resource: FhirSDKResource {

    static var baseResourceTypeString: String { FhirR4Resource.resourceType.rawValue }
    static var resourceTypeString: String { Self.resourceType.rawValue }

    var fhirIdentifier: String? {
        get { id?.value?.string }
        set { id = newValue?.asFHIRStringPrimitive() }
    }
}
