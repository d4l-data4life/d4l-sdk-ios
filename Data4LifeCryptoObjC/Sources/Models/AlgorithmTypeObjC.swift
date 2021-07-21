//
//  AlgorithmTypeObjC.swift
//  Data4LifeCryptoObjC
//
//  Created by Alessio Borraccino on 21.07.21.
//  Copyright © 2021 HPS Gesundheitscloud gGmbH. All rights reserved.
//

import Foundation
import Data4LifeCrypto

@objc(D4LAlgorithmType) public class AlgorithmTypeObjC: NSObject, AlgorithmType {
    let algorithmType: AlgorithmType

    init(_ algorithmType: AlgorithmType) {
        self.algorithmType = algorithmType
        super.init()
    }

    public var cipher: CipherType { algorithmType.cipher }
    public var padding: Padding { algorithmType.padding }
    public var blockMode: BlockMode? { algorithmType.blockMode }
    public var hashType: HashType? { algorithmType.hashType }
}
