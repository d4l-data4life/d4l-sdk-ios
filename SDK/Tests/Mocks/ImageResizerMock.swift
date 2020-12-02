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
@testable import Data4LifeSDK

class ImageResizerMock: Resizable {
    var isResizableCalledWith: (Data)?
    var isResizableResult = false
    func isResizable(_ data: Data) -> Bool {
        isResizableCalledWith = data
        return isResizableResult
    }

    var getSizeCalledWith: (ImageSize, UIImage)?
    var getSizeResult: CGSize?
    func getSize(_ imageSize: ImageSize, for image: UIImage) -> CGSize {
        getSizeCalledWith = (imageSize, image)
        return getSizeResult ?? CGSize(width: 0, height: 0)
    }

    var resizeCalledWith: (UIImage, CGSize)?
    var resizeResult: (Data?, Error?)?
    var resizeResults: [(Data?, Error?)]?
    func resize(_ image: UIImage, for size: CGSize) throws -> Data? {
        resizeCalledWith = (image, size)
        if let results = resizeResults, let first = results.first {
            resizeResults = Array(results.dropFirst())
            if let data = first.0 {
                return data
            } else {
                throw first.1!
            }
        }
        if let error = resizeResult?.1 {
            throw error
        }
        return resizeResult?.0
    }
}
