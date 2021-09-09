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

protocol SDKFileManagerType {
    func saveVersionConfiguration(data: Data) throws
    func readVersionConfiguration() throws -> Data
}

class SDKFileManager: SDKFileManagerType {

    enum Error: Swift.Error {
        case invalidDirectory
        case fileDoesntExist
    }

    private enum FileName {
       static let versionConfiguration = "VersionConfiguration.json"
    }

    private let fileManager: FileManager

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    func saveVersionConfiguration(data: Data) throws {
        try save(fileNamed: FileName.versionConfiguration, data: data)
    }

    func readVersionConfiguration() throws -> Data {
        try read(fileNamed: FileName.versionConfiguration)
    }

    private func save(fileNamed: String, data: Data) throws {
        guard let url = createURL(forFileNamed: fileNamed) else {
            throw Error.invalidDirectory
        }

        do {
            try data.write(to: url)
        } catch {
            throw Data4LifeSDKError.invalidOperationFile
        }
    }

    private func read(fileNamed: String) throws -> Data {
        guard let url = createURL(forFileNamed: fileNamed) else {
            throw Error.invalidDirectory
        }

        guard fileManager.fileExists(atPath: url.path) else {
            throw Error.fileDoesntExist
        }

        do {
            return try Data(contentsOf: url)
        } catch {
            throw Data4LifeSDKError.invalidOperationFile
        }
    }

    private func createURL(forFileNamed fileName: String) -> URL? {
        guard let url = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        return url.appendingPathComponent(fileName)
    }
}
