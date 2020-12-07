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

protocol FhirVersionInformation {
    static var fhirVersion: String { get }
}

protocol ModelVersionInformation {
    static var modelVersion: Int { get }
}

extension FhirStu3Element: FhirVersionInformation, ModelVersionInformation {
    static var fhirVersion: String {
        return "3.0.1"
    }
    static var modelVersion: Int {
        return 1
    }
}

extension FhirStu3Resource: FhirVersionInformation, ModelVersionInformation {
    static var fhirVersion: String {
        return "3.0.1"
    }
    static var modelVersion: Int {
        return 1
    }
}

extension FhirR4Resource: FhirVersionInformation, ModelVersionInformation {
    static var fhirVersion: String {
        return "4.0.1"
    }
    static var modelVersion: Int {
        return 1
    }
}

extension FhirR4Element: FhirVersionInformation, ModelVersionInformation {
    static var fhirVersion: String {
        return "4.0.1"
    }
    static var modelVersion: Int {
        return 1
    }
}
