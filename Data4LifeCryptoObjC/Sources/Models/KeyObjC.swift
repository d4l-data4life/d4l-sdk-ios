//
//  KeyTypeObjC.swift
//  Data4LifeCryptoObjC
//
//  Created by Alessio Borraccino on 21.07.21.
//  Copyright © 2021 HPS Gesundheitscloud gGmbH. All rights reserved.
//

import Foundation
import Data4LifeCrypto

@objc(D4LKey) public class KeyObjC: NSObject {
    let key: Key

    init(_ key: Key) {
        self.key = key
        super.init()
    }

    @objc public convenience init(_ data: Data) {
        do {
            let key = try JSONDecoder().decode(Key.self, from: data)
            self.init(key)
        } catch {
            fatalError()
        }
    }
}

extension Key {
    var objC: KeyObjC { KeyObjC(self) }
}
