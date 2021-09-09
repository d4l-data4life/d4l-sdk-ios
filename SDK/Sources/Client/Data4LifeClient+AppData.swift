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

extension Data4LifeClient {
    /**
     Creates an app data record with given data

     - parameter data: The data that shall be created
     - parameter annotations: Custom annotations added as tags to the record
     - parameter queue: Dispatch queue that will be used for returning the response
     - parameter completion: Completion that returns new record for a resource
     */
    public func createAppDataRecord(_ data: Data,
                                    annotations: [String] = [],
                                    queue: DispatchQueue = responseQueue,
                                    completion: @escaping ResultBlock<AppDataRecord>) {
        appDataService
            .createAppDataRecord(data, annotations: annotations)
            .complete(queue: queue, completion)
    }

    /**
     Updates an app data record with resource

     - parameter data: The data that shall be updated
     - parameter recordId: The identifier of the record to be updated
     - parameter annotations: Custom annotations added as tags to the updated record. If set to nil, existing annotations won't change, otherwise they will override existing ones.
     - parameter queue: Dispatch queue that will be used for returning the response
     - parameter completion: Completion that returns updated record for a resource
     */
    public func updateAppDataRecord(_ data: Data,
                                    recordId: String,
                                    annotations: [String]? = nil,
                                    queue: DispatchQueue = responseQueue,
                                    completion: @escaping ResultBlock<AppDataRecord>) {
        appDataService
            .updateAppDataRecord(data, recordId: recordId, annotations: annotations)
            .complete(queue: queue, completion)
    }

    /**
     Deletes an app data record for the provided ID.

     - parameter identifier: ID of existing record
     - parameter queue: Dispatch queue that will be used for returning the response
     - parameter completion: Completion that will be called after resource is deleted
     */

    public func deleteAppDataRecord(withId identifier: String,
                                    queue: DispatchQueue = responseQueue,
                                    completion: @escaping ResultBlock<Void>) {
        appDataService
            .deleteAppDataRecord(withId: identifier)
            .complete(queue: queue, completion)
    }

    /**
     Fetches an app data record for the provided ID.

     - parameter identifier: ID of existing record
     - parameter queue: Dispatch queue that will be used for returning the response
     - parameter completion: Completion that returns fetched record
     */
    public func fetchAppDataRecord(withId identifier: String,
                                   queue: DispatchQueue = responseQueue,
                                   completion: @escaping ResultBlock<AppDataRecord>) {
        appDataService
            .fetchAppDataRecord(withId: identifier)
            .complete(queue: queue, completion)
    }

    /**
     Fetches app data records  with provided optional filters.

     - parameter size: Number of resources in a page
     - parameter page: Number of a page
     - parameter from: Include resources from this date
     - parameter to: Include resources to this date
     - parameter annotations: Custom annotations used to filter data
     - parameter queue: Dispatch queue that will be used for returning the response
     - parameter completion: Completion that returns fetched records
     */
    public func fetchAppDataRecords(size: Int = 10,
                                    page: Int = 1,
                                    from: Date? = nil,
                                    to: Date? = nil,
                                    annotations: [String] = [],
                                    queue: DispatchQueue = responseQueue,
                                    completion: @escaping ResultBlock<[AppDataRecord]>) {
        let offset = (page - 1) * size
        appDataService.fetchAppDataRecords(from: from,
                                           to: to,
                                           pageSize: size,
                                           offset: offset,
                                           annotations: annotations)
            .complete(queue: queue, completion)
    }

    /**
     Fetches count of created app data records

     - parameter annotations: Custom annotations used to filter data
     - parameter queue: Dispatch queue that will be used for returning the response
     - parameter completion: Completion that returns count
     */
    public func countAppDataRecords(annotations: [String] = [],
                                    queue: DispatchQueue = responseQueue,
                                    completion: @escaping ResultBlock<Int>) {
        appDataService
            .countAppDataRecords(annotations: annotations)
            .complete(queue: queue, completion)
    }
}

// MARK: - Helpers for Codable
extension Data4LifeClient {
    /**
     Creates an app data record with given data

     - parameter codable: The codable resource that shall be updated
     - parameter annotations: Custom annotations added as tags to the record
     - parameter queue: Dispatch queue that will be used for returning the response
     - parameter completion: Completion that returns new record for a resource
     */
    public func createCodableAppDataRecord<D: Codable>(_ codable: D,
                                                       annotations: [String] = [],
                                                       queue: DispatchQueue = responseQueue,
                                                       completion: @escaping ResultBlock<AppDataRecord>) {
        guard let data = try? JSONEncoder().encode(codable) else {
            completion(.failure(Data4LifeSDKError.couldNotEncodeAppData))
            return
        }
        appDataService
            .createAppDataRecord(data, annotations: annotations)
            .complete(queue: queue, completion)
    }

    /**
     Updates an app data record with resource

     - parameter codable: The codable resource that shall be updated
     - parameter recordId: The identifier of the record to be updated
     - parameter annotations: Custom annotations added as tags to the record
     - parameter queue: Dispatch queue that will be used for returning the response
     - parameter completion: Completion that returns updated record for a resource
     */
    public func updateCodableAppDataRecord<D: Codable>(_ codable: D,
                                                       recordId: String,
                                                       annotations: [String]? = nil,
                                                       queue: DispatchQueue = responseQueue,
                                                       completion: @escaping ResultBlock<AppDataRecord>) {
        guard let data = try? JSONEncoder().encode(codable) else {
            completion(.failure(Data4LifeSDKError.couldNotEncodeAppData))
            return
        }
        appDataService
            .updateAppDataRecord(data, recordId: recordId, annotations: annotations)
            .complete(queue: queue, completion)
    }
}
