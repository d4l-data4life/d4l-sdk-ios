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
import Data4LifeFHIR
import ModelsR4

enum AttachmentType {
    case stu3(Data4LifeFHIR.Attachment)
    case r4(ModelsR4.Attachment)

    var title: String? {
        switch self {
        case .stu3(let document):
            return document.title
        case .r4(let document):
            return document.title?.value?.string
        }
    }

    var data: Data? {
        switch self {
        case .stu3(let document):
            return document.getData()
        case .r4(let document):
            guard let dataString = document.data?.value?.dataString else {
                return nil
            }
            return Data(base64Encoded: dataString)
        }
    }
}
