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

extension CustomIdentifiable {
    @inlinable public func addAdditionalId(_ id: String) {
        addAdditionalId(id, assignedTo: Resource.partnerId)
    }

    @inlinable public func setAdditionalIds(_ ids: [String]) {
        setAdditionalIds(ids, assignedTo: Resource.partnerId)
    }

    @inlinable public func getAdditionalIds() -> [String]? {
        getAdditionalIds(assignedTo: Resource.partnerId)
    }

    func cleanObsoleteAdditionalIdentifiers(resourceId: String?, attachmentIds: [String]) throws -> Self {
        guard let identifiers = customIdentifiers else {
            return self
        }

        let updatedIdentifiers = try identifiers.compactMap { identifier -> FhirIdentifierType? in
            guard identifier.valueString?.contains(ThumbnailsIdFactory.downscaledAttachmentIdsFormat) ?? false else {
                return identifier
            }
            guard
                let ids = identifier.valueString?.split(separator: ThumbnailsIdFactory.splitChar),
                ids.count == 4
            else {
                let resourceId = resourceId ?? "Not available"
                throw Data4LifeSDKError.invalidAttachmentAdditionalId("Resource Id: \(resourceId)")
            }

            let attachmentId = String(ids[1])
            let identifierIsInUse = attachmentIds.contains(attachmentId)

            return identifierIsInUse ? identifier : nil
        }
        customIdentifiers = updatedIdentifiers.isEmpty ? nil : updatedIdentifiers
        return self
    }
}
