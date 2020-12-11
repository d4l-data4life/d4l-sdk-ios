//
//  Document.swift
//  Example
//
//  Created by Alessio Borraccino on 11.12.20.
//  Copyright © 2020 HPS Gesundheitscloud gGmbH. All rights reserved.
//

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
