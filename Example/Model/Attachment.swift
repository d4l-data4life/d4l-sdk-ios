//
//  Attachment.swift
//  Example
//
//  Created by Alessio Borraccino on 11.12.20.
//  Copyright © 2020 HPS Gesundheitscloud gGmbH. All rights reserved.
//

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
            return document.data?.value?.data()
        }
    }
}
