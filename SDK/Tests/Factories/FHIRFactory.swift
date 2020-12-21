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
import Data4LifeFHIR
import ModelsR4

struct FhirFactory {

    static func createDomainResource() -> Data4LifeFHIR.DomainResource {
        return Data4LifeFHIR.DomainResource()
    }

    static func createQuestionnaire(items: [Data4LifeFHIR.QuestionnaireItem]? = nil) -> Data4LifeFHIR.Questionnaire {
        let bundle = Bundle(for: Data4LifeDITestContainer.self)
        let questionnaire: Data4LifeFHIR.Questionnaire = try! bundle.decodable(fromJSON: "Questionnaire")

        if let items = items {
            questionnaire.item = items
        }

        return questionnaire
    }

    static func createExpansionQuestionnaire() -> Data4LifeFHIR.Questionnaire {
        let bundle = Bundle(for: Data4LifeDITestContainer.self)
        let questionnaire: Data4LifeFHIR.Questionnaire = try! bundle.decodable(fromJSON: "questionnaire-expansion")
        return questionnaire
    }

    static func createQuestionnaireItem(id: String? = nil, initial: Data4LifeFHIR.Attachment? = nil, items: [Data4LifeFHIR.QuestionnaireItem]? = nil) -> Data4LifeFHIR.QuestionnaireItem {
        let item = QuestionnaireItem()
        item.id = id
        item.item = items
        item.initialAttachment = initial
        return item
    }

    static func createQuestionnaireResponse(items: [Data4LifeFHIR.QuestionnaireResponseItem]? = nil) -> Data4LifeFHIR.QuestionnaireResponse {
        let bundle = Bundle(for: Data4LifeDITestContainer.self)
        let response: Data4LifeFHIR.QuestionnaireResponse = try! bundle.decodable(fromJSON: "QuestionnaireResponse")

        if let items = items {
            response.item = items
        }

        return response
    }

    static func createQuestionnaireResponseItem(id: String = UUID().uuidString,
                                                answers: [Data4LifeFHIR.QuestionnaireResponseItemAnswer]? = nil,
                                                nestedItems: [Data4LifeFHIR.QuestionnaireResponseItem]? = nil) -> Data4LifeFHIR.QuestionnaireResponseItem {
        let responseItem = QuestionnaireResponseItem()
        responseItem.id = id
        if let answers = answers {
            responseItem.answer = answers
        }
        if let nestedItems = nestedItems {
            responseItem.item = nestedItems
        }
        return responseItem
    }

    static func createQuestionnaireResponseItemAnswer(id: String = UUID().uuidString,
                                                      attachment: Data4LifeFHIR.Attachment? = nil) -> Data4LifeFHIR.QuestionnaireResponseItemAnswer {
        let responseItemAnswer = Data4LifeFHIR.QuestionnaireResponseItemAnswer()
        responseItemAnswer.id = id
        if let attachment = attachment {
            responseItemAnswer.valueAttachment = attachment
        }

        return responseItemAnswer
    }

    static func createStu3CarePlanResource() -> Data4LifeFHIR.CarePlan {
        let reference = Reference(UUID().uuidString)
        return CarePlan(intent: .option, status: .active, subject: reference)
    }

    static func createR4CarePlanResource() -> ModelsR4.CarePlan {
        let reference = ModelsR4.Reference(reference: UUID().uuidString.asFHIRStringPrimitive())
        return ModelsR4.CarePlan(intent: RequestIntent.option.asPrimitive(), status: RequestStatus.active.asPrimitive(), subject: reference)
    }

    static func createStu3PatientResource(with attachments: [Data4LifeFHIR.Attachment]? = nil) -> Data4LifeFHIR.Patient {
        let bundle = Bundle(for: Data4LifeDITestContainer.self)
        let patient: Data4LifeFHIR.Patient = try! bundle.decodable(fromJSON: "Patient")
        patient.photo = attachments
        return patient
    }

    static func createR4PatientResource(with attachments: [ModelsR4.Attachment]? = nil) -> ModelsR4.Patient {
        let bundle = Bundle(for: Data4LifeDITestContainer.self)
        let patient: ModelsR4.Patient = try! bundle.decodable(fromJSON: "Patient")
        patient.photo = attachments
        return patient
    }

    static func createObservationResource(valueAttachment: Data4LifeFHIR.Attachment? = nil, components: [Data4LifeFHIR.ObservationComponent]? = nil) -> Data4LifeFHIR.Observation {
        let bundle = Bundle(for: Data4LifeDITestContainer.self)
        let observation: Data4LifeFHIR.Observation = try! bundle.decodable(fromJSON: "ObservationFixture")

        if let valueAttachment = valueAttachment {
            observation.valueAttachment = valueAttachment
        }

        if let components = components {
            observation.component = components
        }

        return observation
    }

    static func createObservationComponentResource(valueAttachment: Data4LifeFHIR.Attachment? = nil) -> Data4LifeFHIR.ObservationComponent {
        let bundle = Bundle(for: Data4LifeDITestContainer.self)
        let component: Data4LifeFHIR.ObservationComponent = try! bundle.decodable(fromJSON: "ObservationComponent")

        if let valueAttachment = valueAttachment {
            component.valueAttachment = valueAttachment
        }

        return component
    }

    static func createStu3DocumentReferenceResource(with attachments: [Data4LifeFHIR.Attachment] = []) -> Data4LifeFHIR.DocumentReference {
        let type = CodeableConcept(code: UUID().uuidString, display: UUID().uuidString, system: UUID().uuidString)
        let content = attachments.map { DocumentReferenceContent(attachment: $0) }
        return DocumentReference(content: content, indexed: .now, status: .current, type: type)
    }

    static func createR4DocumentReferenceResource(with attachments: [ModelsR4.Attachment] = []) -> ModelsR4.DocumentReference {
        let coding = ModelsR4.Coding(code: UUID().uuidString.asFHIRStringPrimitive(), display: UUID().uuidString.asFHIRStringPrimitive(), system: "https://www.google.com".asFHIRURIPrimitive())
        let type = ModelsR4.CodeableConcept(coding: [coding])
        let content = attachments.map { ModelsR4.DocumentReferenceContent(attachment: $0) }
        return ModelsR4.DocumentReference(content: content,
                                          id: UUID().uuidString.asFHIRStringPrimitive(),
                                          status: DocumentReferenceStatus.current.asPrimitive(),
                                          type: type)
    }

    static func createUploadedAttachmentElement() -> Data4LifeFHIR.Attachment {
        let attachment = try! Attachment.with(title: UUID().uuidString,
                                              creationDate: .now,
                                              contentType: UUID().uuidString,
                                              data: Data([0xFF, 0xD8, 0xFF, 0xDB, 0x01, 0x02]))
        attachment.id = UUID().uuidString
        return attachment
    }

    static func createImageAttachmentElement(imageData: Data? = nil) -> Data4LifeFHIR.Attachment {
        return try! Attachment.with(title: UUID().uuidString,
                                    creationDate: .now,
                                    contentType: UUID().uuidString,
                                    data: imageData ?? Data([0xFF, 0xD8, 0xFF, 0xDB, 0x01, 0x02]))
    }

    static func createStu3AttachmentElement() -> Data4LifeFHIR.Attachment {
        return try! Attachment.with(title: UUID().uuidString,
                                    creationDate: .now,
                                    contentType: UUID().uuidString,
                                    data: Data([0x25, 0x50, 0x44, 0x46, 0x2d]))
    }

    static func createR4AttachmentElement() -> ModelsR4.Attachment {
        return try! Attachment.with(title: UUID().uuidString,
                                    creationDate: Date(),
                                    contentType: UUID().uuidString,
                                    data: Data([0x25, 0x50, 0x44, 0x46, 0x2d]))
    }

    static func createSampleImageAttachment() -> Data4LifeFHIR.Attachment {
        let bundle = Bundle(for: Data4LifeDITestContainer.self)
        let data = bundle.data(forResource: "sample", withExtension: "jpg")!
        return try! Attachment.with(title: UUID().uuidString, creationDate: .now, contentType: UUID().uuidString, data: data)
    }

    static func createAppDataResource() -> SomeAppDataResource {
        return SomeAppDataResource(title: "appdata", subtitle: "appdata subtitle")
    }

    static func createAppDataResourceData() -> Data {
        return try! createAppDataResource().encodedData(with: JSONEncoder())
    }
}

struct SomeAppDataResource: Codable, Equatable {
    var title: String
    var subtitle: String
}
