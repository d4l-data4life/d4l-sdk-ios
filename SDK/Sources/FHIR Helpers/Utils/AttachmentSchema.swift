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

import Data4LifeFHIR
import ModelsR4

enum AttachmentSchema {

    // Generic
    case single(AttachmentType?)
    case list([AttachmentType]?)

    // Specific Stu3
    case observation(value: AttachmentType?, components: [Data4LifeFHIR.ObservationComponent]?)
    case questionnaire(items: [Data4LifeFHIR.QuestionnaireItem]?)
    case questionnaireItem(initial: AttachmentType?, nestedItems: [Data4LifeFHIR.QuestionnaireItem]?)
    case questionnaireResponse(items: [Data4LifeFHIR.QuestionnaireResponseItem]?)
    case questionnaireResponseItem(answers: [Data4LifeFHIR.QuestionnaireResponseItemAnswer]?, nestedItems: [Data4LifeFHIR.QuestionnaireResponseItem]?)
    case questionnaireResponseItemAnswer(value: AttachmentType?, nestedItems: [Data4LifeFHIR.QuestionnaireResponseItem]?)

    // Specific R4
    case questionnaireR4(items: [ModelsR4.QuestionnaireItem]?)
    case questionnaireItemInitialR4(initial: AttachmentType?)
    case questionnaireItemR4(initial: [ModelsR4.QuestionnaireItemInitial]?, nestedItems: [ModelsR4.QuestionnaireItem]?)
    case questionnaireResponseR4(items: [ModelsR4.QuestionnaireResponseItem]?)
    case questionnaireResponseItemR4(answers: [ModelsR4.QuestionnaireResponseItemAnswer]?, nestedItems: [ModelsR4.QuestionnaireResponseItem]?)
    case questionnaireResponseItemAnswerR4(value: AttachmentType?, nestedItems: [ModelsR4.QuestionnaireResponseItem]?)

    var allAttachments: [AttachmentType]? {
        switch self {
        case .single(let attachment):
            return attachments(from: attachment)
        case .list(let attachments):
            return attachments
        case .observation(let valueAttachment, let components):
            return combineOrNil(
                attachments(from: valueAttachment),
                attachments(from: components)
            )
        case .questionnaire(let items):
            return attachments(from: items)
        case .questionnaireItem(let initial, let nestedItems):
            return combineOrNil(
                attachments(from: initial),
                attachments(from: nestedItems)
            )
        case .questionnaireResponse(let items):
            return attachments(from: items)
        case .questionnaireResponseItem(let answers, let nestedItems):
            return combineOrNil(
                attachments(from: answers),
                attachments(from: nestedItems)
            )
        case .questionnaireResponseItemAnswer(let value, let nestedItems):
            return combineOrNil(
                attachments(from: value),
                attachments(from: nestedItems)
            )
        case .questionnaireR4(items: let items):
            return attachments(from: items)
        case .questionnaireItemR4(initial: let initial, nestedItems: let nestedItems):
            return combineOrNil(
                attachments(from: initial),
                attachments(from: nestedItems)
            )
        case .questionnaireItemInitialR4(initial: let initial):
            return attachments(from: initial)
        case .questionnaireResponseR4(items: let items):
            return attachments(from: items)
        case .questionnaireResponseItemR4(answers: let answers, nestedItems: let nestedItems):
            return combineOrNil(
                attachments(from: answers),
                attachments(from: nestedItems)
            )
        case .questionnaireResponseItemAnswerR4(value: let value, nestedItems: let nestedItems):
            return combineOrNil(
                attachments(from: value),
                attachments(from: nestedItems)
            )
        }
    }
}

private extension AttachmentSchema {
    func attachments(from attachment: AttachmentType?) -> [AttachmentType]? {
        guard let attachment = attachment else {
            return nil
        }
        return [attachment]
    }

    func attachments(from resources: [HasAttachments]?) -> [AttachmentType]? {
        let attachments: [AttachmentType] = resources?
            .compactMap { $0.allAttachments }
            .flatMap { $0 } ?? []
        return attachments.isEmpty ? nil : attachments
    }

    func combineOrNil(_ listsOfAttachments: [AttachmentType]?...) -> [AttachmentType]? {
        let combined = listsOfAttachments
            .compactMap { $0 }
            .flatMap { $0 }
        return combined.isEmpty ? nil : combined
    }
}
