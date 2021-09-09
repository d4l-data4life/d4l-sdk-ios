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
@_implementationOnly import Data4LifeCrypto

// MARK: DocumentReference
extension Data4LifeFHIR.DocumentReference: HasAttachments {

    var schema: AttachmentSchema {
        return .list(content?.compactMap { $0.attachment })
    }

    func updateAttachments(from filledSchema: AttachmentSchema) {
        guard case let .list(filledAttachments) = filledSchema else {
            fatalError("Attachment Schema should be generic")
        }

        content = filledAttachments?.compactMap { attachment in
            guard let attachment = attachment as? Data4LifeFHIR.Attachment else {
                return nil
            }
            return DocumentReferenceContent(attachment: attachment)
        }
    }
}

// MARK: DiagnosticReport
extension Data4LifeFHIR.DiagnosticReport: HasAttachments {
    var schema: AttachmentSchema {
        return .list(presentedForm)
    }

    func updateAttachments(from filledSchema: AttachmentSchema) {
        guard case let .list(filledAttachments) = filledSchema else {
            fatalError("Attachment Schema should be generic")
        }
        presentedForm = filledAttachments as? [Data4LifeFHIR.Attachment]
    }
}

// MARK: Medication
extension Data4LifeFHIR.Medication: HasAttachments {
    var schema: AttachmentSchema {
        return .list(image)
    }

    func updateAttachments(from filledSchema: AttachmentSchema) {
        guard case let .list(filledAttachments) = filledSchema else {
            fatalError("Attachment Schema should be generic")
        }
        image = filledAttachments as? [Data4LifeFHIR.Attachment]
    }
}

// MARK: Practitioner
extension Data4LifeFHIR.Practitioner: HasAttachments {
    var schema: AttachmentSchema {
        return .list(photo)
    }

    func updateAttachments(from filledSchema: AttachmentSchema) {
        guard case let .list(filledAttachments) = filledSchema else {
            fatalError("Attachment Schema should be generic")
        }
        photo = filledAttachments as? [Data4LifeFHIR.Attachment]
    }
}

// MARK: Patient
extension Data4LifeFHIR.Patient: HasAttachments {
    var schema: AttachmentSchema {
        return .list(photo)
    }

    func updateAttachments(from filledSchema: AttachmentSchema) {
        guard case let .list(filledAttachments) = filledSchema else {
            fatalError("Attachment Schema should be generic")
        }
        photo = filledAttachments as? [Data4LifeFHIR.Attachment]
    }
}

// MARK: ObservationComponent
extension Data4LifeFHIR.ObservationComponent: HasAttachments {
    var schema: AttachmentSchema {
        .single(valueAttachment)
    }

    func updateAttachments(from filledSchema: AttachmentSchema) {
        guard case let .single(attachment) = filledSchema else {
            fatalError("Attachment Schema should be generic")
        }
        self.valueAttachment = attachment as? Data4LifeFHIR.Attachment
    }
}

// MARK: - Implementation for resources with nested resources with attachments
// MARK: Observation
extension Data4LifeFHIR.Observation: HasAttachments {
    var schema: AttachmentSchema {
        return .observation(value: valueAttachment, components: component)
    }

    func updateAttachments(from filledSchema: AttachmentSchema) {
        guard case let .observation(valueAttachment, components) = filledSchema else {
            fatalError("Attachment Schema should be generic")
        }

        self.valueAttachment = valueAttachment as? Data4LifeFHIR.Attachment
        self.component = components
    }

    func makeFilledSchema(byMatchingTo filledAttachments: inout [AttachmentType]) throws -> AttachmentSchema {

        guard case let .observation(unfilledValueAttachment, unfilledComponents) = schema else {
            fatalError("Attachment Schema should be .observation")
        }

        let newValueAttachment = try makeFilledAttachment(byMatchingUnfilledAttachment: unfilledValueAttachment, to: &filledAttachments)
        let newComponents = try makeFilledNestedResources(byMatchingUnfilledNestedResourcesWithAttachments: unfilledComponents,
                                                          to: &filledAttachments)
        return .observation(value: newValueAttachment, components: newComponents)
    }
}

// MARK: Questionnaire
extension Data4LifeFHIR.Questionnaire: HasAttachments {
    var schema: AttachmentSchema {
        return .questionnaire(items: item)
    }

    func updateAttachments(from filledSchema: AttachmentSchema) {
        guard case let .questionnaire(items) = filledSchema else {
            fatalError("Attachment Schema should be questionnaire")
        }

        self.item = items
    }

    func makeFilledSchema(byMatchingTo filledAttachments: inout [AttachmentType]) throws -> AttachmentSchema {

        guard case let .questionnaire(unfilledItems) = schema else {
            fatalError("Attachment Schema should be questionnaire")
        }

        let newItems = try makeFilledNestedResources(byMatchingUnfilledNestedResourcesWithAttachments: unfilledItems,
                                                     to: &filledAttachments)
        return .questionnaire(items: newItems)
    }
}

// MARK: QuestionnaireItem
extension Data4LifeFHIR.QuestionnaireItem: HasAttachments {
    var schema: AttachmentSchema {
        .questionnaireItem(initial: initialAttachment, nestedItems: item)
    }

    func updateAttachments(from filledSchema: AttachmentSchema) {
        guard case let .questionnaireItem(initial, nestedItems) = filledSchema else {
            fatalError("Attachment Schema should be questionnaire item")
        }
        self.initialAttachment = initial as? Data4LifeFHIR.Attachment
        self.item = nestedItems
    }

    func makeFilledSchema(byMatchingTo filledAttachments: inout [AttachmentType]) throws -> AttachmentSchema {

        guard case let .questionnaireItem(unfilledInitialAttachment, unfilledNestedItems) = schema else {
            fatalError("Attachment Schema should be questionnaire response item answer")
        }

        let newInitialAttachment = try makeFilledAttachment(byMatchingUnfilledAttachment: unfilledInitialAttachment, to: &filledAttachments)
        let newNestedItems = try makeFilledNestedResources(byMatchingUnfilledNestedResourcesWithAttachments: unfilledNestedItems, to: &filledAttachments)

        return .questionnaireItem(initial: newInitialAttachment, nestedItems: newNestedItems)
    }
}

// MARK: QuestionnaireResponse
extension Data4LifeFHIR.QuestionnaireResponse: HasAttachments {
    var schema: AttachmentSchema {
        return .questionnaireResponse(items: item)
    }

    func updateAttachments(from filledSchema: AttachmentSchema) {
        guard case let .questionnaireResponse(items) = filledSchema else {
            fatalError("Attachment Schema should be questionnaire response")
        }

        self.item = items
    }

    func makeFilledSchema(byMatchingTo filledAttachments: inout [AttachmentType]) throws -> AttachmentSchema {

        guard case let .questionnaireResponse(unfilledItems) = schema else {
            fatalError("Attachment Schema should be questionnaire response")
        }

        let newItems = try makeFilledNestedResources(byMatchingUnfilledNestedResourcesWithAttachments: unfilledItems,
                                                     to: &filledAttachments)
        return .questionnaireResponse(items: newItems)
    }
}

// MARK: QuestionnaireResponseItem
extension Data4LifeFHIR.QuestionnaireResponseItem: HasAttachments {
    var schema: AttachmentSchema {
        .questionnaireResponseItem(answers: answer, nestedItems: item)
    }

    func updateAttachments(from filledSchema: AttachmentSchema) {
        guard case let .questionnaireResponseItem(answers, nestedItems) = filledSchema else {
            fatalError("Attachment Schema should be questionnaire response item")
        }
        self.answer = answers
        self.item = nestedItems
    }

    func makeFilledSchema(byMatchingTo filledAttachments: inout [AttachmentType]) throws -> AttachmentSchema {
        guard case let .questionnaireResponseItem(unfilledAnswers, unfilledNestedItems) = schema else {
            fatalError("Attachment Schema should be questionnaire response item")
        }

        let newAnswers = try makeFilledNestedResources(byMatchingUnfilledNestedResourcesWithAttachments: unfilledAnswers,
                                                       to: &filledAttachments)
        let newNestedItems = try makeFilledNestedResources(byMatchingUnfilledNestedResourcesWithAttachments: unfilledNestedItems,
                                                           to: &filledAttachments)
        return .questionnaireResponseItem(answers: newAnswers, nestedItems: newNestedItems)
    }
}

// MARK: QuestionnaireResponseItemAnswer
extension Data4LifeFHIR.QuestionnaireResponseItemAnswer: HasAttachments {
    var schema: AttachmentSchema {
        .questionnaireResponseItemAnswer(value: valueAttachment, nestedItems: item)
    }

    func updateAttachments(from filledSchema: AttachmentSchema) {
        guard case let .questionnaireResponseItemAnswer(value, nestedItems) = filledSchema else {
            fatalError("Attachment Schema should be questionnaire response item answer")
        }
        self.valueAttachment = value as? Data4LifeFHIR.Attachment
        self.item = nestedItems
    }

    func makeFilledSchema(byMatchingTo filledAttachments: inout [AttachmentType]) throws -> AttachmentSchema {

        guard case let .questionnaireResponseItemAnswer(unfilledValueAttachment, unfilledNestedItems) = schema else {
            fatalError("Attachment Schema should be questionnaire response item answer")
        }

        let newValueAttachment = try makeFilledAttachment(byMatchingUnfilledAttachment: unfilledValueAttachment,
                                                          to: &filledAttachments)
        let newItems = try makeFilledNestedResources(byMatchingUnfilledNestedResourcesWithAttachments: unfilledNestedItems,
                                                     to: &filledAttachments)

        return .questionnaireResponseItemAnswer(value: newValueAttachment, nestedItems: newItems)
    }
}