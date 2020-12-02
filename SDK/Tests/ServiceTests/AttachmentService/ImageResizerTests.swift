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
    var imageResizer: ImageResizer!

    override func setUp() {
        imageResizer = ImageResizer()
    }

    func testResize() {
        let imageData = Bundle(for: type(of: self)).data(forResource: "sample-jfif", withExtension: "jpg")!
        let image = UIImage(data: imageData)!
        let givenSize = imageResizer.getSize(.smallHeight, for: image)

        let imageDataResult = try! imageResizer.resize(image, for: givenSize)!
        let imageResult = UIImage(data: imageDataResult)!

        XCTAssertTrue(imageResult.size.height == givenSize.height)
        XCTAssertTrue(imageResult.size.width != image.size.width)
    }

    func testResizeFailsImageSmallerThanThumbnails() {
        let imageData = Bundle(for: type(of: self)).data(forResource: "sample", withExtension: "jpg")!
        let image = UIImage(data: imageData)!
        let givenSize = imageResizer.getSize(.smallHeight, for: image)

        do {
            _ = try imageResizer.resize(image, for: givenSize)
            XCTFail("Should throw an error")
        } catch {
            guard let sdkError = error as? Data4LifeSDKError else { XCTFail("Expecting SDK error"); return }
            XCTAssertEqual(sdkError, Data4LifeSDKError.resizingImageSmallerThanOriginalOne)
        }
    }

    func testIsResizable() {
        let jpgImageData = Bundle(for: type(of: self)).data(forResource: "sample", withExtension: "jpg")!
        XCTAssertTrue(imageResizer.isResizable(jpgImageData))

        let pngImageData = Bundle(for: type(of: self)).data(forResource: "sample", withExtension: "png")!
        XCTAssertTrue(imageResizer.isResizable(pngImageData))

        let tiffImageData = Bundle(for: type(of: self)).data(forResource: "sample", withExtension: "tiff")!
        XCTAssertTrue(imageResizer.isResizable(tiffImageData))
    }

    func testIsResizableFails() {
        let dcmData = Bundle(for: type(of: self)).data(forResource: "sample", withExtension: "dcm")!
        XCTAssertFalse(imageResizer.isResizable(dcmData))

        let pdfData = Bundle(for: type(of: self)).data(forResource: "sample", withExtension: "pdf")!
        XCTAssertFalse(imageResizer.isResizable(pdfData))
    }

    func testIsResizableFailsInvalidDataFormat() {
        let noImageData = Data(repeating: 0, count: 8)
        XCTAssertFalse(imageResizer.isResizable(noImageData))
    }

    func testGetThumbnailSize() {
        let imageData = Bundle(for: type(of: self)).data(forResource: "sample", withExtension: "jpg")!
        let image = UIImage(data: imageData)!

        let imageSize = imageResizer.getSize(.smallHeight, for: image)

        XCTAssertTrue(imageSize.height == ImageSize.smallHeight.floatValue)
        //Here we just test that the width has changed. 
        XCTAssertTrue(imageSize.width != image.size.width)
    }
}
