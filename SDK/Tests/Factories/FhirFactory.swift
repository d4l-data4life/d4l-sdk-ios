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

// MARK: - Stu3
struct FhirFactory {

    static func createStu3DomainResource() -> Data4LifeFHIR.DomainResource {
        return Data4LifeFHIR.DomainResource()
    }

    static func createStu3Questionnaire(items: [Data4LifeFHIR.QuestionnaireItem]? = nil) -> Data4LifeFHIR.Questionnaire {
        let bundle = Bundle(for: Data4LifeDITestContainer.self)
        let questionnaire: Data4LifeFHIR.Questionnaire = try! bundle.decodable(fromJSON: "stu3-questionnaire")

        if let items = items {
            questionnaire.item = items
        }

        return questionnaire
    }

    static func createStu3ExpansionQuestionnaire() -> Data4LifeFHIR.Questionnaire {
        let bundle = Bundle(for: Data4LifeDITestContainer.self)
        let questionnaire: Data4LifeFHIR.Questionnaire = try! bundle.decodable(fromJSON: "questionnaire-expansion")
        return questionnaire
    }

    static func createStu3QuestionnaireItem(id: String? = nil, initial: Data4LifeFHIR.Attachment? = nil, items: [Data4LifeFHIR.QuestionnaireItem]? = nil) -> Data4LifeFHIR.QuestionnaireItem {
        let item = QuestionnaireItem()
        item.id = id
        item.item = items
        item.initialAttachment = initial
        return item
    }

    static func createStu3QuestionnaireResponse(items: [Data4LifeFHIR.QuestionnaireResponseItem]? = nil) -> Data4LifeFHIR.QuestionnaireResponse {
        let bundle = Bundle(for: Data4LifeDITestContainer.self)
        let response: Data4LifeFHIR.QuestionnaireResponse = try! bundle.decodable(fromJSON: "stu3-questionnaire-response")

        if let items = items {
            response.item = items
        }

        return response
    }

    static func createStu3QuestionnaireResponseItem(id: String = UUID().uuidString,
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

    static func createStu3QuestionnaireResponseItemAnswer(id: String = UUID().uuidString,
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

    static func createStu3ObservationResource(valueAttachment: Data4LifeFHIR.Attachment? = nil, components: [Data4LifeFHIR.ObservationComponent]? = nil) -> Data4LifeFHIR.Observation {
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

    static func createStu3ObservationComponentResource(valueAttachment: Data4LifeFHIR.Attachment? = nil) -> Data4LifeFHIR.ObservationComponent {
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

    static func createUploadedAttachmentElement() -> Data4LifeFHIR.Attachment {
        let attachment = try! Attachment.with(title: UUID().uuidString,
                                              creationDate: .now,
                                              contentType: UUID().uuidString,
                                              data: Data([0xFF, 0xD8, 0xFF, 0xDB, 0x01, 0x02]))
        attachment.id = UUID().uuidString
        return attachment
    }

    static func createStu3ImageAttachmentElement(imageData: Data? = nil) -> Data4LifeFHIR.Attachment {
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

    static func createStu3SampleImageAttachment() -> Data4LifeFHIR.Attachment {
        let bundle = Bundle(for: Data4LifeDITestContainer.self)
        let data = bundle.data(forResource: "sample", withExtension: "jpg")!
        return try! Attachment.with(title: UUID().uuidString, creationDate: .now, contentType: UUID().uuidString, data: data)
    }
}

// MARK: - R4
extension FhirFactory {
    static func createR4DocumentReferenceResource(with attachments: [ModelsR4.Attachment] = []) -> ModelsR4.DocumentReference {
        let coding = ModelsR4.Coding(code: UUID().uuidString.asFHIRStringPrimitive(), display: UUID().uuidString.asFHIRStringPrimitive(), system: "https://www.google.com".asFHIRURIPrimitive())
        let type = ModelsR4.CodeableConcept(coding: [coding])
        let content = attachments.map { ModelsR4.DocumentReferenceContent(attachment: $0) }
        return ModelsR4.DocumentReference(content: content,
                                          id: UUID().uuidString.asFHIRStringPrimitive(),
                                          status: DocumentReferenceStatus.current.asPrimitive(),
                                          type: type)
    }

    static func createR4Questionnaire(items: [ModelsR4.QuestionnaireItem]? = nil) -> ModelsR4.Questionnaire {
        let bundle = Bundle(for: Data4LifeDITestContainer.self)
        let questionnaire: ModelsR4.Questionnaire = try! bundle.decodable(fromJSON: "r4-questionnaire")

        if let items = items {
            questionnaire.item = items
        }

        return questionnaire
    }

    static func createR4QuestionnaireItem(id: String? = nil, initial: ModelsR4.Attachment? = nil, items: [ModelsR4.QuestionnaireItem]? = nil) -> ModelsR4.QuestionnaireItem {
        let initial = [initial.map({ QuestionnaireItemInitial(value: .attachment($0))})].compactMap({$0})
        let item = ModelsR4.QuestionnaireItem.init(linkId: (id ?? UUID().uuidString).asFHIRStringPrimitive(), type: QuestionnaireItemType.attachment.asPrimitive())
        item.id = id?.asFHIRStringPrimitive()
        item.item = items
        item.initial = initial.isEmpty ? nil : initial
        return item
    }

    static func createR4PatientResource(with attachments: [ModelsR4.Attachment]? = nil) -> ModelsR4.Patient {
        let bundle = Bundle(for: Data4LifeDITestContainer.self)
        let patient: ModelsR4.Patient = try! bundle.decodable(fromJSON: "Patient")
        patient.photo = attachments
        return patient
    }

    static func createR4QuestionnaireResponse(items: [ModelsR4.QuestionnaireResponseItem]? = nil) -> ModelsR4.QuestionnaireResponse {
        let bundle = Bundle(for: Data4LifeDITestContainer.self)
        let response: ModelsR4.QuestionnaireResponse = try! bundle.decodable(fromJSON: "r4-questionnaire-response")
        if let items = items {
            response.item = items
        }
        return response
    }

    static func createR4QuestionnaireResponseItem(id: String = UUID().uuidString,
                                                  answers: [ModelsR4.QuestionnaireResponseItemAnswer]? = nil,
                                                  nestedItems: [ModelsR4.QuestionnaireResponseItem]? = nil) -> ModelsR4.QuestionnaireResponseItem {
        let responseItem = ModelsR4.QuestionnaireResponseItem(linkId: id.asFHIRStringPrimitive())
        responseItem.id = id.asFHIRStringPrimitive()
        if let answers = answers {
            responseItem.answer = answers
        }
        if let nestedItems = nestedItems {
            responseItem.item = nestedItems
        }
        return responseItem
    }

    static func createR4QuestionnaireResponseItemAnswer(id: String = UUID().uuidString,
                                                        attachment: ModelsR4.Attachment? = nil) -> ModelsR4.QuestionnaireResponseItemAnswer {
        let responseItemAnswer = ModelsR4.QuestionnaireResponseItemAnswer()
        responseItemAnswer.id = id.asFHIRStringPrimitive()
        if let attachment = attachment {
            responseItemAnswer.value = .attachment(attachment)
        }

        return responseItemAnswer
    }

    static func createR4SampleImageAttachment() -> ModelsR4.Attachment {
        let bundle = Bundle(for: Data4LifeDITestContainer.self)
        let data = bundle.data(forResource: "sample", withExtension: "jpg")!
        return try! Attachment.with(title: UUID().uuidString, creationDate: Date(), contentType: UUID().uuidString, data: data)
    }

    static func createR4AttachmentElement() -> ModelsR4.Attachment {
        return try! Attachment.with(title: UUID().uuidString,
                                    creationDate: Date(),
                                    contentType: UUID().uuidString,
                                    data: Data([0x25, 0x50, 0x44, 0x46, 0x2d]))
    }

    static func createR4ImageAttachmentElement(imageData: Data? = nil) -> ModelsR4.Attachment {
        return try! Attachment.with(title: UUID().uuidString,
                                    creationDate: Date(),
                                    contentType: UUID().uuidString,
                                    data: imageData ?? Data([0xFF, 0xD8, 0xFF, 0xDB, 0x01, 0x02]))
    }
}

// MARK: - AppData
extension FhirFactory {
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
