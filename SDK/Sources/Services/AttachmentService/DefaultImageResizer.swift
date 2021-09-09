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

@_implementationOnly import Data4LifeSDKUtils
import Foundation
import UIKit

protocol ImageResizer {
    func isImageData(_ data: Data) -> Bool
    func resizedData(_ image: UIImage, for thumbnailHeight: ThumbnailHeight) throws -> Data?
}

enum ThumbnailHeight: CGFloat, CaseIterable {
    case mediumHeight
    case smallHeight

    var floatValue: CGFloat {
        switch self {
        case .mediumHeight: return 1000.0
        case .smallHeight: return 200.0
        }
    }
}

struct DefaultImageResizer: ImageResizer {
    private let compressionQuality: CGFloat = 0.8

    func isImageData(_ data: Data) -> Bool {
        guard let mimeType = MIMEType.of(data) else {
            return false
        }

        return mimeType == .jpeg || mimeType == .png || mimeType == .tiff
    }

    func resizedData(_ image: UIImage, for thumbnailHeight: ThumbnailHeight) throws -> Data? {
        let scaledSize = size(of: image, scaledTo: thumbnailHeight)
        guard image.size.height > scaledSize.height, image.size.width > scaledSize.width else {
            throw Data4LifeSDKError.resizingImageSmallerThanOriginalOne
        }
        // Fix the scale for the renderer. Otherwise it might change the size of the thumbnails depending on the device
        let format = UIGraphicsImageRendererFormat(for: UITraitCollection.init())
        format.scale = 1.0
        let renderer = UIGraphicsImageRenderer(size: scaledSize, format: format)
        return renderer.jpegData(withCompressionQuality: compressionQuality) { (_) in
             image.draw(in: CGRect(origin: .zero, size: scaledSize))
        }
    }
}

extension DefaultImageResizer {
    private func size(of image: UIImage, scaledTo height: ThumbnailHeight) -> CGSize {
        let width = (height.floatValue * image.size.width) / image.size.height
        return CGSize(width: width, height: height.floatValue)
    }
}