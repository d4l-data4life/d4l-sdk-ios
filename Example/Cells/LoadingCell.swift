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

import UIKit

class LoadingCell: UITableViewCell {
    @IBOutlet var spinner: UIActivityIndicatorView!
    override func awakeFromNib() {
        separatorInset = UIEdgeInsets(top: 0, left: self.bounds.size.width, bottom: 0, right: 0)
    }

    func startLoading() {
        if spinner.isAnimating == false {
            spinner.isHidden = false
            spinner.startAnimating()
        }
    }

    func stopLoading() {
        spinner.stopAnimating()
        spinner.isHidden = true
    }

    override func prepareForReuse() {
        spinner.isHidden = true
        spinner.stopAnimating()
    }
}