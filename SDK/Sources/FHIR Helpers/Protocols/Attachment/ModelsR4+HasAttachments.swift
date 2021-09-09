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

import ModelsR4

// MARK: DocumentReference
extension ModelsR4.DocumentReference: HasAttachments {
    var schema: AttachmentSchema {
        return .list(content.compactMap { $0.attachment })
    }

    func updateAttachments(from filledSchema: AttachmentSchema) {
        guard case let .list(filledAttachments) = filledSchema else {
            fatalError("Attachment Schema should be generic")
        }

        content = filledAttachments?.compactMap { attachment in
            guard let attachment = attachment as? ModelsR4.Attachment else {
                return nil
            }
            return DocumentReferenceContent(attachment: attachment)
        } ?? []
    }
}

// MARK: DiagnosticReport
extension ModelsR4.DiagnosticReport: HasAttachments {
    var schema: AttachmentSchema {
        return .list(presentedForm)
    }

    func updateAttachments(from filledSchema: AttachmentSchema) {
        guard case let .list(filledAttachments) = filledSchema else {
            fatalError("Attachment Schema should be generic")
        }
        presentedForm = filledAttachments as? [ModelsR4.Attachment]
    }
}

// MARK: Practitioner
extension ModelsR4.Practitioner: HasAttachments {
    var schema: AttachmentSchema {
        return .list(photo)
    }

    func updateAttachments(from filledSchema: AttachmentSchema) {
        guard case let .list(filledAttachments) = filledSchema else {
            fatalError("Attachment Schema should be generic")
        }
        photo = filledAttachments as? [ModelsR4.Attachment]
    }
}

// MARK: Patient
extension ModelsR4.Patient: HasAttachments {
    var schema: AttachmentSchema {
        return .list(photo)
    }

    func updateAttachments(from filledSchema: AttachmentSchema) {
        guard case let .list(filledAttachments) = filledSchema else {
            fatalError("Attachment Schema should be generic")
        }
        photo = filledAttachments as? [ModelsR4.Attachment]
    }
}

// MARK: ObservationComponent
extension ModelsR4.BodyStructure: HasAttachments {
    var schema: AttachmentSchema {
        .list(image)
    }

    func updateAttachments(from filledSchema: AttachmentSchema) {
        guard case let .list(filledAttachments) = filledSchema else {
            fatalError("Attachment Schema should be generic")
        }
        self.image = filledAttachments as? [ModelsR4.Attachment]
    }
}

extension ModelsR4.ClaimResponse: HasAttachments {
    var schema: AttachmentSchema {
        .single(form)
    }
    func updateAttachments(from filledSchema: AttachmentSchema) {
        guard case let .single(filledAttachment) = filledSchema else {
            fatalError("Attachment Schema should be generic")
        }
        self.form = filledAttachment as? ModelsR4.Attachment
    }
}

extension ModelsR4.ClaimSupportingInfo: HasAttachments {
    var schema: AttachmentSchema {
        switch value {
        case .attachment(let attachment):
            return .single(attachment)
        default:
            return .single(nil)
        }
    }

    func updateAttachments(from filledSchema: AttachmentSchema) {
        guard case let .single(filledAttachment) = filledSchema else {
            fatalError("Attachment Schema should be generic")
        }

        guard let castAttachment = filledAttachment as? ModelsR4.Attachment else {
            return
        }

        self.value = .attachment(castAttachment)
    }
}

extension ModelsR4.CommunicationPayload: HasAttachments {

    var schema: AttachmentSchema {
        switch content {
        case .attachment(let attachment):
            return .single(attachment)
        default:
            return .single(nil)
        }
    }

    func updateAttachments(from filledSchema: AttachmentSchema) {
        guard case let .single(filledAttachment) = filledSchema else {
            fatalError("Attachment Schema should be generic")
        }

        guard let castAttachment = filledAttachment as? ModelsR4.Attachment else {
            return
        }

        self.content = .attachment(castAttachment)
    }
}

extension ModelsR4.CommunicationRequestPayload: HasAttachments {

    var schema: AttachmentSchema {
        switch content {
        case .attachment(let attachment):
            return .single(attachment)
        default:
            return .single(nil)
        }
    }

    func updateAttachments(from filledSchema: AttachmentSchema) {
        guard case let .single(filledAttachment) = filledSchema else {
            fatalError("Attachment Schema should be generic")
        }

        guard let castAttachment = filledAttachment as? ModelsR4.Attachment else {
            return
        }

        self.content = .attachment(castAttachment)
    }
}

extension ModelsR4.Consent: HasAttachments {

    var schema: AttachmentSchema {
        switch source {
        case .attachment(let attachment):
            return .single(attachment)
        default:
            return .single(nil)
        }
    }

    func updateAttachments(from filledSchema: AttachmentSchema) {
        guard case let .single(filledAttachment) = filledSchema else {
            fatalError("Attachment Schema should be generic")
        }

        guard let castAttachment = filledAttachment as? ModelsR4.Attachment else {
            return
        }

        self.source = .attachment(castAttachment)
    }
}

// MARK: Questionnaire
extension ModelsR4.Questionnaire: HasAttachments {
    var schema: AttachmentSchema {
        return .questionnaireR4(items: item)
    }

    func updateAttachments(from filledSchema: AttachmentSchema) {
        guard case let .questionnaireR4(items) = filledSchema else {
            fatalError("Attachment Schema should be questionnaire")
        }

        self.item = items
    }

    func makeFilledSchema(byMatchingTo filledAttachments: inout [AttachmentType]) throws -> AttachmentSchema {

        guard case let .questionnaireR4(unfilledItems) = schema else {
            fatalError("Attachment Schema should be questionnaire")
        }

        let newItems = try makeFilledNestedResources(byMatchingUnfilledNestedResourcesWithAttachments: unfilledItems,
                                                     to: &filledAttachments)
        return .questionnaireR4(items: newItems)
    }
}

// MARK: QuestionnaireItemInitial
extension ModelsR4.QuestionnaireItemInitial: HasAttachments {
    var schema: AttachmentSchema {
        switch value {
        case .attachment(let attachment):
            return .single(attachment)
        default:
            return .single(nil)
        }
    }

    func updateAttachments(from filledSchema: AttachmentSchema) {
        guard case let .single(filledAttachment) = filledSchema else {
            fatalError("Attachment Schema should be generic")
        }

        guard let castAttachment = filledAttachment as? ModelsR4.Attachment else {
            return
        }

        self.value = .attachment(castAttachment)
    }
}

// MARK: QuestionnaireItem
extension ModelsR4.QuestionnaireItem: HasAttachments {
    var schema: AttachmentSchema {
        .questionnaireItemR4(initial: initial, nestedItems: item)
    }

    func updateAttachments(from filledSchema: AttachmentSchema) {
        guard case let .questionnaireItemR4(initial, nestedItems) = filledSchema else {
            fatalError("Attachment Schema should be questionnaire item")
        }
        self.initial = initial
        self.item = nestedItems
    }

    func makeFilledSchema(byMatchingTo filledAttachments: inout [AttachmentType]) throws -> AttachmentSchema {

        guard case let .questionnaireItemR4(unfilledInitialAttachments, unfilledNestedItems) = schema else {
            fatalError("Attachment Schema should be questionnaire response item answer")
        }

        let newInitialAttachments = try makeFilledNestedResources(byMatchingUnfilledNestedResourcesWithAttachments: unfilledInitialAttachments, to: &filledAttachments)
        let newNestedItems = try makeFilledNestedResources(byMatchingUnfilledNestedResourcesWithAttachments: unfilledNestedItems, to: &filledAttachments)

        return .questionnaireItemR4(initial: newInitialAttachments, nestedItems: newNestedItems)
    }
}

// MARK: QuestionnaireResponse
extension ModelsR4.QuestionnaireResponse: HasAttachments {
    var schema: AttachmentSchema {
        return .questionnaireResponseR4(items: item)
    }

    func updateAttachments(from filledSchema: AttachmentSchema) {
        guard case let .questionnaireResponseR4(items) = filledSchema else {
            fatalError("Attachment Schema should be questionnaire response")
        }

        self.item = items
    }

    func makeFilledSchema(byMatchingTo filledAttachments: inout [AttachmentType]) throws -> AttachmentSchema {

        guard case let .questionnaireResponseR4(unfilledItems) = schema else {
            fatalError("Attachment Schema should be questionnaire response")
        }

        let newItems = try makeFilledNestedResources(byMatchingUnfilledNestedResourcesWithAttachments: unfilledItems,
                                                     to: &filledAttachments)
        return .questionnaireResponseR4(items: newItems)
    }
}

// MARK: QuestionnaireResponseItem
extension ModelsR4.QuestionnaireResponseItem: HasAttachments {
    var schema: AttachmentSchema {
        .questionnaireResponseItemR4(answers: answer, nestedItems: item)
    }

    func updateAttachments(from filledSchema: AttachmentSchema) {
        guard case let .questionnaireResponseItemR4(answers, nestedItems) = filledSchema else {
            fatalError("Attachment Schema should be questionnaire response item")
        }
        self.answer = answers
        self.item = nestedItems
    }

    func makeFilledSchema(byMatchingTo filledAttachments: inout [AttachmentType]) throws -> AttachmentSchema {
        guard case let .questionnaireResponseItemR4(unfilledAnswers, unfilledNestedItems) = schema else {
            fatalError("Attachment Schema should be questionnaire response item")
        }

        let newAnswers = try makeFilledNestedResources(byMatchingUnfilledNestedResourcesWithAttachments: unfilledAnswers,
                                                       to: &filledAttachments)
        let newNestedItems = try makeFilledNestedResources(byMatchingUnfilledNestedResourcesWithAttachments: unfilledNestedItems,
                                                           to: &filledAttachments)
        return .questionnaireResponseItemR4(answers: newAnswers, nestedItems: newNestedItems)
    }
}

// MARK: QuestionnaireResponseItemAnswer
extension ModelsR4.QuestionnaireResponseItemAnswer: HasAttachments {
    var schema: AttachmentSchema {
        switch value {
        case .attachment(let attachment):
            return .questionnaireResponseItemAnswerR4(value: attachment, nestedItems: item)
        default:
            return .questionnaireResponseItemAnswerR4(value: nil, nestedItems: item)
        }
    }

    func updateAttachments(from filledSchema: AttachmentSchema) {
        guard case let .questionnaireResponseItemAnswerR4(value, nestedItems) = filledSchema else {
            fatalError("Attachment Schema should be questionnaire response item answer")
        }

        self.item = nestedItems
        if let castAttachment = value as? ModelsR4.Attachment {
            self.value = .attachment(castAttachment)
        }
    }

    func makeFilledSchema(byMatchingTo filledAttachments: inout [AttachmentType]) throws -> AttachmentSchema {

        guard case let .questionnaireResponseItemAnswerR4(unfilledValueAttachment, unfilledNestedItems) = schema else {
            fatalError("Attachment Schema should be questionnaire response item answer")
        }

        let newValueAttachment = try makeFilledAttachment(byMatchingUnfilledAttachment: unfilledValueAttachment,
                                                          to: &filledAttachments)
        let newItems = try makeFilledNestedResources(byMatchingUnfilledNestedResourcesWithAttachments: unfilledNestedItems,
                                                     to: &filledAttachments)

        return .questionnaireResponseItemAnswerR4(value: newValueAttachment, nestedItems: newItems)
    }
}
