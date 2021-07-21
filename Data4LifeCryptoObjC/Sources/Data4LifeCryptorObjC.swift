//
//  Data4LifeCryptorObjectiveC.swift
//  Data4LifeCryptoObjC
//
//  Created by Alessio Borraccino on 20.07.21.
//  Copyright © 2021 HPS Gesundheitscloud gGmbH. All rights reserved.
//

import Foundation
import Data4LifeCrypto

@objc public class Data4LifeCryptorObjC: NSObject {

    @objc public static func symEncrypt(key: KeyObjC, data: Data, iv: Data) throws -> Data {
        try Data4LifeCryptor.symEncrypt(key: key.key, data: data, iv: data)
    }

    @objc public static func symDecrypt(key: KeyObjC, data: Data, iv: Data) throws -> Data {
        try Data4LifeCryptor.symDecrypt(key: key.key, data: data, iv: iv)
    }

    @objc public static func asymEncrypt(key: KeyPairObjC, data: Data) throws -> Data {
        try Data4LifeCryptor.asymEncrypt(key: key.keyPair, data: data)
    }

    @objc public static func asymDecrypt(key: KeyPairObjC, data: Data) throws -> Data {
        try Data4LifeCryptor.asymDecrypt(key: key.keyPair, data: data)
    }

    @objc public static func generateAsymKeyPair(algorithm: AlgorithmTypeObjC, options: KeyOptionsObjC) throws -> KeyPairObjC {
        try Data4LifeCryptor.generateAsymKeyPair(algorithm: algorithm.algorithmType, options: options.keyOptions).objC
    }

    @objc public static func generateSymKey(algorithm: AlgorithmTypeObjC, options: KeyOptionsObjC, type: KeyTypeObjC) throws -> KeyObjC {
        try Data4LifeCryptor.generateSymKey(algorithm: algorithm.algorithmType, options: options.keyOptions, type: type.keyType).objC
    }
}
