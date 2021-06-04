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

import XCTest
@testable import Data4LifeSDK

class ImageResizerTest: XCTestCase {

    private var bundle = Foundation.Bundle.current

    var imageResizer: DefaultImageResizer!

    override func setUp() {
        imageResizer = DefaultImageResizer()
    }

    func testResizeThumbnail() throws {
        let imageData = bundle.data(forResource: "sample", withExtension: "jpg")!
        let image = UIImage(data: imageData)!
        let resizedImageData = try imageResizer.resizedData(image, for: .smallHeight)!
        let resizedImage = UIImage(data: resizedImageData)!
        XCTAssertEqual(resizedImage.size.height, ThumbnailHeight.smallHeight.floatValue, accuracy: .ulpOfOne)
        XCTAssertTrue(resizedImage.size.width != image.size.width)
    }

    func testResizePreview() throws {
        let imageData = bundle.data(forResource: "sample-jfif", withExtension: "jpg")!
        let image = UIImage(data: imageData)!
        let resizedImageData = try imageResizer.resizedData(image, for: .mediumHeight)!
        let resizedImage = UIImage(data: resizedImageData)!
        XCTAssertEqual(resizedImage.size.height, ThumbnailHeight.mediumHeight.floatValue, accuracy: .ulpOfOne)
        XCTAssertTrue(resizedImage.size.width != image.size.width)
    }

    func testResizeFailsImageSmallerThanThumbnails() {
        let imageData = bundle.data(forResource: "sample", withExtension: "jpg")!
        let image = UIImage(data: imageData)!

        do {
            _ = try imageResizer.resizedData(image, for: .smallHeight)
            XCTFail("Should throw an error")
        } catch {
            guard let sdkError = error as? Data4LifeSDKError else { XCTFail("Expecting SDK error"); return }
            XCTAssertEqual(sdkError, Data4LifeSDKError.resizingImageSmallerThanOriginalOne)
        }
    }

    func testIsResizable() {
        let jpgImageData = bundle.data(forResource: "sample", withExtension: "jpg")!
        XCTAssertTrue(imageResizer.isImageData(jpgImageData))

        let pngImageData = bundle.data(forResource: "sample", withExtension: "png")!
        XCTAssertTrue(imageResizer.isImageData(pngImageData))

        let tiffImageData = bundle.data(forResource: "sample", withExtension: "tiff")!
        XCTAssertTrue(imageResizer.isImageData(tiffImageData))
    }

    func testIsResizableFails() {
        let dcmData = bundle.data(forResource: "sample", withExtension: "dcm")!
        XCTAssertFalse(imageResizer.isImageData(dcmData))

        let pdfData = bundle.data(forResource: "sample", withExtension: "pdf")!
        XCTAssertFalse(imageResizer.isImageData(pdfData))
    }

    func testIsResizableFailsInvalidDataFormat() {
        let noImageData = Data(repeating: 0, count: 8)
        XCTAssertFalse(imageResizer.isImageData(noImageData))
    }
}
