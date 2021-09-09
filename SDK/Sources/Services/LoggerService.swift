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

enum LoggerResult {
    case didLog
    case didNotLog
}

struct LoggerConfiguration {
    var destinations: [LoggerService.Destination]
}

extension LoggerConfiguration {
    static var console = LoggerConfiguration(destinations: [.console])
}

class LoggerService {

    enum Destination {
        case console
        case oslog
    }

    private let destinations: [LoggerService.Destination]
    private let currentBuildConfiguration: BuildConfiguration

    private static var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }()

    var isLoggingEnabled: Bool = false

    init(configuration: LoggerConfiguration,
         currentBuildConfiguration: BuildConfiguration = BuildConfiguration.current) {

        self.destinations = configuration.destinations
        self.currentBuildConfiguration = currentBuildConfiguration
    }

    @discardableResult
    func logDebug(_ message: String, date: Date = Date(), file: String = #file, line: Int = #line) -> LoggerResult {

        guard isLoggingEnabled else {
            return .didNotLog
        }

        if currentBuildConfiguration == .debug, destinations.contains(.console) {
            let formattedString = formattedStringForConsole(message, date: date, file: file, line: line)
            print(formattedString)
            return .didLog
        } else {
            return .didNotLog
        }
    }

    private func formattedStringForConsole(_ message: String, date: Date, file: String, line: Int) -> String {
        let dateString = LoggerService.dateFormatter.string(from: date)
        let fileString = file.components(separatedBy: "/").last
        return "[\(dateString)] [(\(fileString ?? ""):\(line)] \(message)"
    }
}

@discardableResult
func logDebug(_ message: String, date: Date = Date(),
              file: String = #file, line: Int = #line,
              using loggerContainer: DIContainer = LoggerContainer.shared) -> LoggerResult {
    do {
        let loggerService: LoggerService = try loggerContainer.resolve()
        return loggerService.logDebug(message, date: date, file: file, line: line)
    } catch {
        fatalError("Could not resolve loggerService")
    }
}