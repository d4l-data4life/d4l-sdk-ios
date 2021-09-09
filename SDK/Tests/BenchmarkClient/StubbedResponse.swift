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

enum StubbedResponse {
    // create/fetch resources
    case carePlan
    case diagnosticReport
    case observation

    // fetch DocumentReference+Attachment
    case fetchDocumentReference
    case fetchDocumentReferenceToken
    case fetchDocumentReferenceAttachmentBlob

    // create DocumentReference+Attachment stubs
    case createDocumentReferenceInitial
    case createDocumentReferenceToken
    case createDocumentReferenceAttachmentBlob
    case createDocumentReferenceUpdated
    case createDocumentReferenceFinal

    var data: Data {
        var resource: (name: String, `extension`: String) {
            switch self {
            case .fetchDocumentReference:
                return ("doc-ref-fetched", ".json")
            case .fetchDocumentReferenceToken:
                return ("doc-ref-token", ".json")
            case .fetchDocumentReferenceAttachmentBlob:
                return ("doc-ref-attachment-data", "")
            case .carePlan:
                return ("care-plan", ".json")
            case .observation:
                return ("observation", ".json")
            case .diagnosticReport:
                return ("diagnostic-report", ".json")
            case .createDocumentReferenceInitial:
                return ("create-document-reference", ".json")
            case .createDocumentReferenceToken:
                return ("create-document-reference-token", ".json")
            case .createDocumentReferenceAttachmentBlob:
                return ("create-document-reference-blob", ".json")
            case .createDocumentReferenceUpdated:
                return ("create-document-reference-updated", ".json")
            case .createDocumentReferenceFinal:
                return ("create-document-reference-final", ".json")

            }
        }
        let url = Bundle.main.url(forResource: resource.name, withExtension: resource.extension)!
        return try! Data(contentsOf: url)
    }
}