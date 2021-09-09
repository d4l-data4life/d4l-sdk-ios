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

import Data4LifeFHIR
import ModelsR4

enum DocumentVersion: String {
    case stu3
    case r4
}

enum DocumentType {
    case stu3(Data4LifeFHIR.DocumentReference)
    case r4(ModelsR4.DocumentReference)

    var fhirDescription: String? {
        switch self {
        case .stu3(let document):
            return document.description_fhir
        case .r4(let document):
            return document.description_fhir?.value?.string
        }
    }

    var fhirIdentifier: String? {
        switch self {
        case .stu3(let document):
            return document.id
        case .r4(let document):
            return document.id?.value?.string
        }
    }

    var attachmentIdentifiers: [String] {
        switch self {
        case .stu3(let document):
            return document.attachments?.compactMap({ $0.id }) ?? []
        case .r4(let document):
            return document.content.compactMap({ $0.attachment.id?.value?.string })
        }
    }
}
