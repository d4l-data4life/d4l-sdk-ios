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

import Foundation

/// Allows to download not only the original one attachment, but also medium or small attachment previews if they are available
///
/// - full: Downloads the original attachment
/// - medium: Medium size attachment
/// - small: Smallest size attachment
public enum DownloadType {
    case full, medium, small

    var isThumbnailType: Bool {
        return self == .medium || self == .small
    }

    var thumbnailHeight: ThumbnailHeight? {
        switch self {
        case .full:
            return nil
        case .medium:
            return .mediumHeight
        case .small:
            return .smallHeight
        }
    }
}
