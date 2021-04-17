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

@_exported import Data4LifeFHIR
@_exported import ModelsR4

public typealias FhirStu3Resource = Data4LifeFHIR.DomainResource
public typealias FhirResource = FhirStu3Resource
public typealias FhirR4Resource = ModelsR4.DomainResource

public protocol AnyFhirResource {}

extension FhirStu3Resource: AnyFhirResource {}
extension FhirR4Resource: AnyFhirResource {}

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
