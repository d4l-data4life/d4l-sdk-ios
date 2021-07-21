//
//  KeyTypeObjC.swift
//  Data4LifeCryptoObjC
//
//  Created by Alessio Borraccino on 21.07.21.
//  Copyright © 2021 HPS Gesundheitscloud gGmbH. All rights reserved.
//

import Foundation
import Data4LifeCrypto

@objc(D4LKeyType) public class KeyTypeObjC: NSObject {
    let keyType: KeyType

    init(_ keyType: KeyType) {
        self.keyType = keyType
        super.init()
    }
}
