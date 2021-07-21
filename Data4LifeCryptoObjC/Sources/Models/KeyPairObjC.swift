//
//  KeyPairObjC.swift
//  Data4LifeCryptoObjC
//
//  Created by Alessio Borraccino on 21.07.21.
//  Copyright © 2021 HPS Gesundheitscloud gGmbH. All rights reserved.
//

import Foundation
import Data4LifeCrypto

@objc(D4LKeyPair) public class KeyPairObjC: NSObject {
    let keyPair: KeyPair
    
    init(_ keyPair: KeyPair) {
        self.keyPair = keyPair
        super.init()
    }
}

extension KeyPair {
    var objC: KeyPairObjC {
        KeyPairObjC(self)
    }
}
