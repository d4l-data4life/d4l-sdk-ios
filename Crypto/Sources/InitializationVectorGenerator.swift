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

public protocol InitializationVectorGeneratorProtocol {
    func randomIVData(of size: Int) -> Data
}

public final class InitializationVectorGenerator: InitializationVectorGeneratorProtocol {
    public init() {}

    public func randomIVData(of size: Int) -> Data {
        return randomIV(of: size).asData
    }
}

extension InitializationVectorGenerator {
    private func randomIV(of size: Int) -> [UInt8] {
        (0..<size).map({ _ in UInt8.random(in: 0...UInt8.max) })
    }
}
