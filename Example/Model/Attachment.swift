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
import Data4LifeFHIR
import ModelsR4

enum AttachmentType {
    case stu3(Data4LifeFHIR.Attachment)
    case r4(ModelsR4.Attachment)

    var title: String? {
        switch self {
        case .stu3(let document):
            return document.title
        case .r4(let document):
            return document.title?.value?.string
        }
    }

    var data: Data? {
        switch self {
        case .stu3(let document):
            return document.getData()
        case .r4(let document):
            guard let dataString = document.data?.value?.dataString else {
                return nil
            }
            return Data(base64Encoded: dataString)
        }
    }
}

extension Data4LifeFHIR.DocumentReference {
    static func make(titled title: String, attachments: [Data4LifeFHIR.Attachment]) -> Data4LifeFHIR.DocumentReference {
        let document = DocumentReference()
        document.description_fhir = title
        document.attachments = attachments
        document.indexed = .now
        document.status = .current
        document.type = CodeableConcept(code: "18782-3", display: "Radiology Study observation (findings)", system: "http://loinc.org")
        return document
    }
}

extension ModelsR4.DocumentReference {
    static func make(titled title: String, attachments: [ModelsR4.Attachment]) -> ModelsR4.DocumentReference {
        let document = ModelsR4.DocumentReference.init(content: attachments.map({ ModelsR4.DocumentReferenceContent(attachment: $0)}),
                                                       status: DocumentReferenceStatus.current.asPrimitive())
        document.description_fhir = title.asFHIRStringPrimitive()
        document.type = ModelsR4.CodeableConcept(coding: [ModelsR4.Coding(code: "18782-3".asFHIRStringPrimitive(),
                                                                          display: "Radiology Study observation (findings)".asFHIRStringPrimitive())
        ])
        return document
    }
}
