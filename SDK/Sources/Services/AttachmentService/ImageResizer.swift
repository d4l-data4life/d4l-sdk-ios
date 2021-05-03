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

@_implementationOnly import Data4LifeSDKUtils
import Foundation
import UIKit

protocol Resizable {
    func isResizable(_ data: Data) -> Bool
    func getSize(_ imageSize: ImageSize, for image: UIImage) -> CGSize
    func resize(_ image: UIImage, for size: CGSize) throws -> Data?
}

enum ImageSize: CGFloat, CaseIterable {
    case mediumHeight
    case smallHeight

    var floatValue: CGFloat {
        switch self {
        case .mediumHeight: return 1000.0
        case .smallHeight: return 200.0
        }
    }
}

struct ImageResizer: Resizable {
    private let compressionQuality: CGFloat = 0.8

    func isResizable(_ data: Data) -> Bool {
        guard let mimeType = MIMEType.of(data) else {
            return false
        }

        return mimeType == .jpeg || mimeType == .png || mimeType == .tiff
    }

    func getSize(_ imageSize: ImageSize, for image: UIImage) -> CGSize {
        // Calculate the width of the image according to the selected height
        let width = (imageSize.floatValue * image.size.width) / image.size.height
        return CGSize(width: width, height: imageSize.floatValue)
    }

    func resize(_ image: UIImage, for size: CGSize) throws -> Data? {
        guard image.size.height > size.height, image.size.width > size.width else {
            throw Data4LifeSDKError.resizingImageSmallerThanOriginalOne
        }
        // Fix the scale for the renderer. Otherwise it might change the size of the thumbnails depending on the device
        let format = UIGraphicsImageRendererFormat(for: UITraitCollection.init())
        format.scale = 1.0
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        return renderer.jpegData(withCompressionQuality: compressionQuality) { (_) in
             image.draw(in: CGRect(origin: .zero, size: size))
        }
    }
}
