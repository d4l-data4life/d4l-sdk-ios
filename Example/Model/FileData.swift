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

import UIKit
import Data4LifeFHIR
import ModelsR4
import Data4LifeSDKUtils

struct FileData {
    var name: String
    var image: UIImage
}

extension FileData {
    var toStu3Attachment: Data4LifeFHIR.Attachment {
        let imageData = image.jpegData(compressionQuality: 0.5)!
        guard let contentType = MIMEType.of(imageData)?.rawValue else {
            fatalError("Invalid data MIME type")
        }
        return try! Attachment.with(title: "\(self.name).jpg",
                                    creationDate: .now,
                                    contentType: contentType,
                                    data: imageData)
    }

    var toR4Attachment: ModelsR4.Attachment {
        let imageData = image.jpegData(compressionQuality: 0.5)!
        guard let contentType = MIMEType.of(imageData)?.rawValue else {
            fatalError("Invalid data MIME type")
        }
        return try! Attachment.with(title: "\(name).jpg",
                                    creationDate: Date(),
                                    contentType: contentType,
                                    data: imageData)
    }
}
