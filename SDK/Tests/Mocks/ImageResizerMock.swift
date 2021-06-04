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
import UIKit

@testable import Data4LifeSDK

class ImageResizerMock: DataResizer {

    var isResizableCalledWith: (Data)?
    var isResizableResult = false
    func isImageData(_ data: Data) -> Bool {
        isResizableCalledWith = data
        return isResizableResult
    }

    var resizedDataCalledWith: (UIImage, ThumbnailHeight)?
    var resizedDataResult: (Data?, Error?)?
    var resizedDataResultBuilder: (() -> (Data?, Error?))?

    func resizedData(of image: UIImage, with thumbnailHeight: ThumbnailHeight) throws -> Data {
        resizedDataCalledWith = (image, thumbnailHeight)
        if let resizedDataResultBuilder = resizedDataResultBuilder {
            let response = resizedDataResultBuilder()
            if let data = response.0 {
                return data
            } else {
                throw response.1!
            }
        }

        if let error = resizedDataResult?.1 {
            throw error
        }

        return resizedDataResult!.0!
    }
}
