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

protocol HasAttachments {
    var schema: AttachmentSchema { get }
    func updateAttachments(from filledSchema: AttachmentSchema)
    func makeFilledSchema(byMatchingTo filledAttachments: inout [AttachmentType]) throws -> AttachmentSchema
}

extension HasAttachments {
    var allAttachments: [AttachmentType]? {
        return schema.allAttachments
    }

    @discardableResult
    func validateAttachments() throws  -> [AttachmentType]? {
        guard let attachments = allAttachments, !attachments.isEmpty else {
            return nil
        }

        try attachments.forEach { (attachment) in
            try attachment.validatePayload()
        }
        return attachments
    }
}

// MARK: - Default Implementation for resources with single or list of attachments
extension HasAttachments {
    func makeFilledSchema(byMatchingTo filledAttachments: inout [AttachmentType]) throws -> AttachmentSchema {
        switch schema {
        case .single(let unfilledAttachment):
            let newAttachment = try makeFilledAttachment(byMatchingUnfilledAttachment: unfilledAttachment, to: &filledAttachments)
            return .single(newAttachment)
        case .list(let unfilledAttachments):
            return try makeListSchema(byMatchingUnfilled: unfilledAttachments, toFilled: filledAttachments)
        default:
            fatalError("Attachment Schema is not generic, please write its own implementation")
        }
    }

    private func makeListSchema(byMatchingUnfilled unfilledAttachments: [AttachmentType]?,
                                toFilled filledAttachments: [AttachmentType]) throws -> AttachmentSchema {
        var availableFilledAttachments = filledAttachments
        let filledAttachments = try unfilledAttachments?.compactMap({ (unfilledAttachment) -> AttachmentType? in
            guard let matchedAttachmentIndex = availableFilledAttachments.firstIndex(where: { unfilledAttachment.matches(to: $0) }) else {
                throw Data4LifeSDKError.couldNotSynchronizeAttachments
            }
            let matchedAttachment = availableFilledAttachments[matchedAttachmentIndex]
            let newfilledAttachment = unfilledAttachment.filled(with: matchedAttachment)
            availableFilledAttachments.remove(at: matchedAttachmentIndex)
            return newfilledAttachment
        })
        return .list(filledAttachments)
    }
}

// MARK: Helpers
extension HasAttachments {

    func makeFilledAttachment(byMatchingUnfilledAttachment unfilledAttachment: AttachmentType?, to filledAttachments: inout [AttachmentType]) throws -> AttachmentType? {
        var availableFilledAttachments = filledAttachments
        var newAttachment: AttachmentType?

        if let unfilledAttachment = unfilledAttachment {
            guard let matchedAttachmentIndex = availableFilledAttachments.firstIndex(where: { unfilledAttachment.matches(to: $0)}) else {
                throw Data4LifeSDKError.couldNotSynchronizeAttachments
            }
            let matchedAttachment = availableFilledAttachments[matchedAttachmentIndex]
            newAttachment = unfilledAttachment.filled(with: matchedAttachment)
            availableFilledAttachments.remove(at: matchedAttachmentIndex)
        }
        filledAttachments = availableFilledAttachments
        return newAttachment
    }

    func makeFilledNestedResources<NestedResource: NSCopying & HasAttachments>(byMatchingUnfilledNestedResourcesWithAttachments unfilledNestedResources: [NestedResource]?,
                                                                               to filledAttachments: inout [AttachmentType]) throws -> [NestedResource]? {
        let newNestedResources: [NestedResource]? = try unfilledNestedResources?.compactMap ({ unfilledNestedResource in
            guard let newNestedResource = unfilledNestedResource.copy() as? NestedResource else {
                return nil
            }
            let newSchema = try newNestedResource.makeFilledSchema(byMatchingTo: &filledAttachments)
            newNestedResource.updateAttachments(from: newSchema)
            return newNestedResource
        })
        return newNestedResources
    }
}
