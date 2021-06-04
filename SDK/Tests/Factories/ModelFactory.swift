//
//  ModelFactory.swift
//  Data4LifeSDKTests
//
//  Created by Alessio Borraccino on 04.06.21.
//  Copyright © 2021 HPS Gesundheitscloud gGmbH. All rights reserved.
//

import Foundation
@testable import Data4LifeSDK

extension AttachmentDocumentInfo {
    static func make(_ attachment: AttachmentType, ids: [ThumbnailHeight: String] = [:]) -> AttachmentDocumentInfo {
        AttachmentDocumentInfo(document: AttachmentDocument(id: attachment.attachmentId, data: Data()),
                               attachment: attachment,
                               thumbnailsIDs: ids)
    }
}
