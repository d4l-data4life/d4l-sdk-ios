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
import Data4LifeFHIR

extension Data4LifeClient {
    /**
     Creates a record with a resource
     
     - parameter resource: The resource that shall be created
     - parameter annotations: Custom annotations added as tags to the record
     - parameter queue: Dispatch queue that will be used for returning the response
     - parameter completion: Completion that returns new record for a resource
     */

    public func createFhirStu3Record<R: FhirStu3Resource>(_ resource: R,
                                                          annotations: [String] = [],
                                                          queue: DispatchQueue = responseQueue,
                                                          completion: @escaping ResultBlock<FhirRecord<R>>) {
        fhirService
            .createFhirRecord(resource, annotations: annotations, decryptedRecordType: DecryptedFhirStu3Record<R>.self)
            .complete(queue: queue, completion)
    }

    /**
     Creates a number of records
     
     - parameter resources: The resources that will be created
     - parameter annotations: Custom annotations added as tags to all created records
     - parameter queue: Dispatch queue that will be used for returning the response
     - parameter completion: Completion that returns new record for a resource
     */

    public func createFhirStu3Records<R: FhirStu3Resource>(_ resources: [R],
                                                           annotations: [String] = [],
                                                           queue: DispatchQueue = responseQueue,
                                                           completion: @escaping ResultBlock<BatchResult<FhirRecord<R>, R>>) {
        fhirService
            .createFhirRecords(resources, annotations: annotations, decryptedRecordType: DecryptedFhirStu3Record<R>.self)
            .complete(queue: queue, completion)
    }

    /**
     Updates a record with resource
     
     - parameter resource: The resource that shall be updated
     - parameter annotations: Custom annotations added as tags to the updated record. If set to nil, existing annotations won't change, otherwise they will override existing ones.
     - parameter queue: Dispatch queue that will be used for returning the response
     - parameter completion: Completion that returns updated record for a resource
     */

    public func updateFhirStu3Record<R: FhirStu3Resource>(_ resource: R,
                                                          annotations: [String]? = nil,
                                                          queue: DispatchQueue = responseQueue,
                                                          completion: @escaping ResultBlock<FhirRecord<R>>) {
        fhirService
            .updateFhirRecord(resource, annotations: annotations, decryptedRecordType: DecryptedFhirStu3Record<R>.self)
            .complete(queue: queue, completion)
    }

    /**
     Updates a number of records with resources
     
     - parameter resources: The resources that will be updated
     - parameter annotations: Custom annotations added as tags to all updated records. If set to nil, existing annotations won't change, otherwise they will override existing ones.
     - parameter queue: Dispatch queue that will be used for returning the response
     - parameter completion: Completion that returns updated records for resources
     */

    public func updateFhirStu3Records<R: FhirStu3Resource>(_ resources: [R],
                                                           annotations: [String]? = nil,
                                                           queue: DispatchQueue = responseQueue,
                                                           completion: @escaping ResultBlock<BatchResult<FhirRecord<R>, R>>) {
        fhirService
            .updateFhirRecords(resources, annotations: annotations, decryptedRecordType: DecryptedFhirStu3Record<R>.self)
            .complete(queue: queue, completion)
    }

    /**
     Deletes a record for the provided ID.
     
     - parameter identifier: ID of existing record
     - parameter queue: Dispatch queue that will be used for returning the response
     - parameter completion: Completion that will be called after resource is deleted
     */

    public func deleteFhirStu3Record(withId identifier: String,
                                     queue: DispatchQueue = responseQueue,
                                     completion: @escaping ResultBlock<Void>) {
        fhirService
            .deleteFhirRecord(withId: identifier)
            .complete(queue: queue, completion)
    }

    /**
     Deletes a number of records for the provided IDs.
     
     - parameter identifiers: IDs of existing record
     - parameter queue: Dispatch queue that will be used for returning the response
     - parameter completion: Completion that will be called after resources are deleted
     */

    public func deleteFhirStu3Records(withIds identifiers: [String],
                                      queue: DispatchQueue = responseQueue,
                                      completion: @escaping ResultBlock<BatchResult<String, String>>) {
        fhirService
            .deleteFhirRecords(withIds: identifiers)
            .complete(queue: queue, completion)
    }

    /**
     Fetches a record for the provided ID.
     
     - parameter identifier: ID of existing record
     - parameter type: Type of FHIR Resources that is being downloaded
     - parameter queue: Dispatch queue that will be used for returning the response
     - parameter completion: Completion that returns fetched record
     */

    public func fetchFhirStu3Record<R: FhirStu3Resource>(withId identifier: String,
                                                         of type: R.Type = R.self,
                                                         queue: DispatchQueue = responseQueue,
                                                         completion: @escaping ResultBlock<FhirRecord<R>>) {
        fhirService
            .fetchFhirRecord(withId: identifier, decryptedRecordType: DecryptedFhirStu3Record<R>.self)
            .complete(queue: queue, completion)
    }

    /**
     Fetches a number of record for the provided IDs.
     
     - parameter identifiers: IDs of existing records
     - parameter type: Type of FHIR Resources that is being downloaded     
     - parameter queue: Dispatch queue that will be used for returning the response
     - parameter completion: Completion that returns fetched records
     */

    public func fetchFhirStu3Records<R: FhirStu3Resource>(withIds identifiers: [String],
                                                          of type: R.Type = R.self,
                                                          queue: DispatchQueue = responseQueue,
                                                          completion: @escaping ResultBlock<BatchResult<FhirRecord<R>, String>>) {
        fhirService
            .fetchFhirRecords(withIds: identifiers, decryptedRecordType: DecryptedFhirStu3Record<R>.self)
            .complete(queue: queue, completion)
    }

    /**
     Fetches records per type with provided optional filters, and if no type is provided all types will be returned.

     - parameter type: Type of a resource
     - parameter size: Number of resources in a page
     - parameter page: Number of a page
     - parameter from: Include resources from this date
     - parameter to: Include resources to this date
     - parameter annotations: Custom annotations used as filter for the records
     - parameter queue: Dispatch queue that will be used for returning the response
     - parameter completion: Completion that returns fetched records
     */

    public func fetchFhirStu3Records<R: FhirStu3Resource>(of type: R.Type = R.self,
                                                          size: Int = 10,
                                                          page: Int = 1,
                                                          from: Date? = nil,
                                                          to: Date? = nil,
                                                          updatedFrom: Date? = nil,
                                                          updatedTo: Date? = nil,
                                                          includingDeleted: Bool = false,
                                                          annotations: [String] = [],
                                                          queue: DispatchQueue = responseQueue,
                                                          completion: @escaping ResultBlock<[FhirRecord<R>]>) {
        let offset = (page - 1) * size
        let searchQuery = RecordServiceParameterBuilder.SearchQuery(limit: size,
                                                                    offset: offset,
                                                                    startDate: from,
                                                                    endDate: to,
                                                                    startUpdatedDate: updatedFrom,
                                                                    endUpdatedDate: updatedTo,
                                                                    includingDeleted: includingDeleted,
                                                                    tagGroup: TagGroup(tags: [:], annotations: annotations))
        fhirService.fetchFhirRecords(query: searchQuery,
                                     decryptedRecordType: DecryptedFhirStu3Record<R>.self)
            .complete(queue: queue, completion)
    }

    /**
     Fetches count of created records with specified type, if no type is provided all types will be counted together.

     - parameter type: Type of resource to count
     - parameter annotations: Custom annotations used as filter for the records
     - parameter queue: Dispatch queue that will be used for returning the response
     - parameter completion: Completion that returns count
     */
    public func countFhirStu3Records<R: FhirStu3Resource>(of type: R.Type = R.self,
                                                          annotations: [String] = [],
                                                          queue: DispatchQueue = responseQueue,
                                                          completion: @escaping ResultBlock<Int>) {
        fhirService
            .countFhirRecords(of: type, annotations: annotations)
            .complete(queue: queue, completion)
    }
}

// MARK: - Deprecated
extension Data4LifeClient {

    @available(iOS, deprecated: 1.9.0, message: "Renamed to createFhirRecord", renamed: "createFhirRecord")
    public func createRecord<R: FhirStu3Resource>(_ resource: R,
                                                  queue: DispatchQueue = responseQueue,
                                                  completion: @escaping ResultBlock<FhirRecord<R>>) {
        createFhirStu3Record(resource, queue: queue, completion: completion)
    }

    @available(iOS, deprecated: 1.9.0, message: "Renamed to createFhirRecords", renamed: "createFhirRecords")
    public func createRecords<R: FhirStu3Resource>(_ resources: [R],
                                                   queue: DispatchQueue = responseQueue,
                                                   completion: @escaping ResultBlock<BatchResult<FhirRecord<R>, R>>) {
        createFhirStu3Records(resources, queue: queue, completion: completion)
    }

    @available(iOS, deprecated: 1.9.0, message: "Renamed to updateFhirRecord", renamed: "updateFhirRecord")
    public func updateRecord<R: FhirStu3Resource>(_ resource: R,
                                                  queue: DispatchQueue = responseQueue,
                                                  completion: @escaping ResultBlock<FhirRecord<R>>) {
        updateFhirStu3Record(resource, queue: queue, completion: completion)
    }

    @available(iOS, deprecated: 1.9.0, message: "Renamed to updateFhirRecords", renamed: "updateFhirRecords")
    public func updateRecords<R: FhirStu3Resource>(_ resources: [R],
                                                   queue: DispatchQueue = responseQueue,
                                                   completion: @escaping ResultBlock<BatchResult<FhirRecord<R>, R>>) {
        updateFhirStu3Records(resources, queue: queue, completion: completion)
    }

    @available(iOS, deprecated: 1.9.0, message: "Renamed to deleteFhirRecord", renamed: "deleteFhirRecord")
    public func deleteRecord(withId identifier: String,
                             queue: DispatchQueue = responseQueue,
                             completion: @escaping ResultBlock<Void>) {
        deleteFhirStu3Record(withId: identifier, queue: queue, completion: completion)
    }

    @available(iOS, deprecated: 1.9.0, message: "Renamed to deleteFhirRecords", renamed: "deleteFhirRecords")
    public func deleteRecords(withIds identifiers: [String],
                              queue: DispatchQueue = responseQueue,
                              completion: @escaping ResultBlock<BatchResult<String, String>>) {
        deleteFhirStu3Records(withIds: identifiers, queue: queue, completion: completion)
    }

    @available(iOS, deprecated: 1.9.0, message: "Renamed to fetchFhirRecord", renamed: "fetchFhirRecord")
    public func fetchRecord<R: FhirStu3Resource>(withId identifier: String,
                                                 of type: R.Type = R.self,
                                                 queue: DispatchQueue = responseQueue,
                                                 completion: @escaping ResultBlock<FhirRecord<R>>) {
        fetchFhirStu3Record(withId: identifier, of: type, queue: queue, completion: completion)
    }

    @available(iOS, deprecated: 1.9.0, message: "Renamed to fetchFhirRecords", renamed: "fetchFhirRecords")
    public func fetchRecords<R: FhirStu3Resource>(withIds identifiers: [String],
                                                  of type: R.Type = R.self,
                                                  queue: DispatchQueue = responseQueue,
                                                  completion: @escaping ResultBlock<BatchResult<FhirRecord<R>, String>>) {
        fetchFhirStu3Records(withIds: identifiers, of: type, queue: queue, completion: completion)
    }

    @available(iOS, deprecated: 1.9.0, message: "Renamed to countFhirRecords", renamed: "countFhirRecords")
    public func countRecords<R: FhirStu3Resource>(of type: R.Type = R.self,
                                                  queue: DispatchQueue = responseQueue,
                                                  completion: @escaping ResultBlock<Int>) {
        countFhirStu3Records(of: type, queue: queue, completion: completion)
    }

    @available(iOS, deprecated: 1.8.0, message: "Renamed to fetchFhirRecords", renamed: "fetchFhirRecords")
    public func fetchRecords<R: FhirStu3Resource>(of type: R.Type,
                                                  size: Int = 10,
                                                  page: Int = 1,
                                                  from: Date? = nil,
                                                  to: Date? = nil,
                                                  queue: DispatchQueue = responseQueue,
                                                  completion: @escaping ResultBlock<[FhirRecord<R>]>) {
        fetchFhirStu3Records(of: type, size: size, page: page, from: from, to: to, queue: queue, completion: completion)
    }
}
