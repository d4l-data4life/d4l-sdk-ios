//
//  KeyOptionsObjC.swift
//  Data4LifeCryptoObjC
//
//  Created by Alessio Borraccino on 21.07.21.
//  Copyright © 2021 HPS Gesundheitscloud gGmbH. All rights reserved.
//

import Foundation
import Data4LifeCrypto

@objc(D4LKeyOptions) public class KeyOptionsObjC: NSObject {
    let keyOptions: KeyOptions
    init(_ keyOptions: KeyOptions) {
        self.keyOptions = keyOptions
        super.init()
    }
}
