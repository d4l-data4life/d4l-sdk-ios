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

@testable import Data4LifeSDK
import Then
import Data4LifeCrypto

class RecordServiceParameterBuilderMock: RecordServiceParameterBuilderProtocol {

    var searchParametersResult: Parameters?
    var searchParametersError: Data4LifeSDKError?
    func searchParameters(from startDate: Date?, to endDate: Date?, offset: Int?, pageSize: Int?, tagGroup: TagGroup, supportingLegacyTags: Bool) throws -> Parameters {
        if let error = searchParametersError {
            throw error
        } else {
            return searchParametersResult ?? [:]
        }
    }

    var uploadParametersResult: Parameters?
    var uploadParametersError: Data4LifeSDKError?
    func uploadParameters<R>(resource: R, uploadDate: Date, commonKey: Key, commonKeyIdentifier: String, dataKey: Key, attachmentKey: Key?, tagGroup: TagGroup) throws -> Parameters where R : SDKResource {
        if let error = uploadParametersError {
            throw error
        } else {
            return uploadParametersResult ?? [:]
        }
    }
}
