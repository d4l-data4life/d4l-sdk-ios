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

import Foundation

extension AsymmetricKey {
    /**
     Strip header from PKCS#8 RSA private key and convert to PKCS#1.
     Will return the same data without the header if it exists in the right format.
     Source: https://github.com/btnguyen2k/swiftutils/blob/master/SwiftUtils/RSAUtils.swift
     
     - parameter key: RSA private key (PKCS#8)
     */
    static func stripPKCS8Header(forKey key: Data) throws -> Data? {
        if ( key.isEmpty ) {
            return nil
        }

        var keyAsArray = [UInt8](repeating: 0, count: key.count / MemoryLayout<UInt8>.size)
        (key as NSData).getBytes(&keyAsArray, length: key.count)

        // PKCS#8: magic byte at offset 22, check if it's actually ASN.1
        var idx = 22
        if ( keyAsArray[idx] != 0x04 ) {
            return key
        }
        idx += 1

        // now we need to find out how long the key is, so we can extract the correct hunk
        // of bytes from the buffer.
        var len = Int(keyAsArray[idx])
        idx += 1
        let det = len & 0x80 // check if the high bit set
        if (det == 0) {
            // no? then the length of the key is a number that fits in one byte, (< 128)
            len = len & 0x7f
        } else {
            // otherwise, the length of the key is a number that doesn't fit in one byte (> 127)
            var byteCount = Int(len & 0x7f)
            if (byteCount + idx > key.count) {
                return nil
            }
            // so we need to snip off byteCount bytes from the front, and reverse their order
            var accum: UInt = 0
            var idx2 = idx
            idx += byteCount
            while (byteCount > 0) {
                // after each byte, we shove it over, accumulating the value into accum
                accum = (accum << 8) + UInt(keyAsArray[idx2])
                idx2 += 1
                byteCount -= 1
            }
            // now we have read all the bytes of the key length, and converted them to a number,
            // which is the number of bytes in the actual key.  we use this below to extract the
            // key bytes and operate on them
            len = Int(accum)
        }

        return key.subdata(in: idx..<idx+len)
    }
}
