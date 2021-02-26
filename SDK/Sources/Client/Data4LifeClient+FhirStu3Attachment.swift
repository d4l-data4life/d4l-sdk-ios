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
@_implementationOnly import Then
import Data4LifeFHIR
import ModelsR4

extension Data4LifeClient {
    /**
     Downloads record with FHIR resource and all of the attachments data if available
     
     - parameter identifier: ID of existing resource
     - parameter type: Type of FHIR Resource that is being downloaded
     - parameter queue: Dispatch queue that will be used for returning the response
     - parameter completion: Completion that returns downloaded record for a resource
     */
    public func downloadFhirStu3Record<R: FhirStu3Resource>(withId identifier: String,
                                                            of type: R.Type = R.self,
                                                            queue: DispatchQueue = responseQueue,
                                                            completion: @escaping ResultBlock<FhirRecord<R>>) {
        fhirService
            .downloadFhirRecordWithAttachments(withId: identifier, decryptedRecordType: DecryptedFhirStu3Record<R>.self)
            .complete(queue: queue, completion)
    }

    /**
     Downloads records with FHIR resources and all of the attachments data if available
     
     - parameter identifiers: IDs of existing resources
     - parameter type: Type of FHIR Resources that is being downloaded
     - parameter queue: Dispatch queue that will be used for returning the response
     - parameter completion: Completion that returns downloaded records for a resource
     */
    public func downloadFhirStu3Records<R: FhirStu3Resource>(withIds identifiers: [String],
                                                             of type: R.Type = R.self,
                                                             queue: DispatchQueue = responseQueue,
                                                             completion: @escaping ResultBlock<BatchResult<FhirRecord<R>, String>>) {
        let totalProgress = Progress(totalUnitCount: Int64(identifiers.count))
        fhirService
            .downloadFhirRecordsWithAttachments(withIds: identifiers, decryptedRecordType: DecryptedFhirStu3Record<R>.self, parentProgress: totalProgress)
            .complete(queue: queue, completion)
    }

    /**
     Downloads single attachment with data
     
     - parameter identifier: ID of existing attachment
     - parameter recordId: ID of existing record
     - parameter downloadType: type of the attachment if available
     - parameter queue: Dispatch queue that will be used for returning the response
     - parameter onProgressUpdated: Closure called when progress is updated
     - parameter completion: Completion that returns downloaded attachment
     
     - Returns: Discardable object to cancel the download request
     */
    @discardableResult
    public func downloadFhirStu3Attachment(withId identifier: String,
                                           recordId: String,
                                           downloadType: DownloadType = .full,
                                           queue: DispatchQueue = responseQueue,
                                           onProgressUpdated: ((Progress) -> Void)? = nil,
                                           completion: @escaping ResultBlock<Data4LifeFHIR.Attachment>) -> Cancellable {
        let task = makeProgressTask(fileCount: 1, onProgressUpdated)
        fhirService
            .downloadAttachment(of: Attachment.self,
                                decryptedRecordType: DecryptedFhirStu3Record<FhirStu3Resource>.self,
                                withId: identifier,
                                recordId: recordId,
                                downloadType: downloadType,
                                parentProgress: task.progress)
            .complete(queue: queue, completion)
        return task
    }

    /**
     Downloads multiple attachments with data
     
     - parameter identifiers: IDs of existing attachments
     - parameter recordId: ID of existing record
     - parameter downloadType: type of the attachment if available
     - parameter queue: Dispatch queue that will be used for returning the response
     - parameter onProgressUpdated: Closure called when progress is updated
     - parameter completion: Completion that returns downloaded attachments
     
     - Returns: Discardable object to cancel the download request
     */
    @discardableResult
    public func downloadFhirStu3Attachments(withIds identifiers: [String],
                                            recordId: String,
                                            downloadType: DownloadType = .full,
                                            queue: DispatchQueue = responseQueue,
                                            onProgressUpdated: ((Progress) -> Void)? = nil,
                                            completion: @escaping ResultBlock<[Data4LifeFHIR.Attachment]>) -> Cancellable {

        let task = makeProgressTask(fileCount: identifiers.count, onProgressUpdated)
        fhirService
            .downloadAttachments(of: Attachment.self,
                                 decryptedRecordType: DecryptedFhirStu3Record<FhirStu3Resource>.self,
                                 withIds: identifiers,
                                 recordId: recordId,
                                 downloadType: downloadType,
                                 parentProgress: task.progress)
            .complete(queue: queue, completion)
        return task
    }
}

extension Data4LifeClient {
    func makeProgressTask(fileCount: Int, _ onProgressUpdated: ((Progress) -> Void)? = nil) -> Task {
        let progress = Progress(totalUnitCount: Int64(fileCount))
        let task = Task(progress)
        if let onProgressUpdated = onProgressUpdated {
            task.observeFractionCompleted(onProgressUpdated)
        }
        return task
    }
}
