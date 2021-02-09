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
import ModelsR4

protocol FhirSDKResource: AnyFhirResource, SDKResource {
    var fhirIdentifier: String? { get set }
}

extension FhirStu3Resource: FhirSDKResource {
    static var searchTags: [String : String] {
        var tags = [String: String]()
        if Self.resourceType != Data4LifeFHIR.DomainResource.resourceType {
            tags[TaggingService.Keys.resourceType.rawValue] = Self.resourceType
        }
        tags[TaggingService.Keys.fhirVersion.rawValue] = Self.fhirVersion
        tags.lowercased()
        return tags
    }

    var fhirIdentifier: String? {
        get { id }
        set { id = newValue }
    }
}

extension FhirR4Resource: FhirSDKResource {
    static var searchTags: [String : String] {
        var tags = [String: String]()
        if Self.resourceType != ModelsR4.DomainResource.resourceType {
            tags[TaggingService.Keys.resourceType.rawValue] = Self.resourceType.rawValue
        }
        tags[TaggingService.Keys.fhirVersion.rawValue] = Self.fhirVersion
        tags.lowercased()
        return tags
    }

    var fhirIdentifier: String? {
        get { id?.value?.string }
        set { id = newValue?.asFHIRStringPrimitive() }
    }
}
