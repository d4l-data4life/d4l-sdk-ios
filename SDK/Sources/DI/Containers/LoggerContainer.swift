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

final class LoggerContainer: DIContainer {

    /// Used for the global logDebug function
    static var shared: LoggerContainer = {
        let loggerContainer = LoggerContainer()
        loggerContainer.registerDependencies(with: .console)
        return loggerContainer
    }()

    func registerDependencies(with loggerConfiguration: LoggerConfiguration) {
        do {
            register(scope: .containerInstance, { (_) -> LoggerService in
                let service = LoggerService(configuration: loggerConfiguration)
                service.isLoggingEnabled = true
                return service
            })
        }
    }
}
