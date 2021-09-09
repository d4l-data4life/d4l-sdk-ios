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

@_implementationOnly import Alamofire
import Combine
import Foundation

private var backgroundResponseQueue = DispatchQueue(label: "alamofire.response.queue", qos: .background, attributes: .concurrent)

extension DataRequest {

    private static var backgroundQueue: DispatchQueue {
        return backgroundResponseQueue
    }

    func responseDecodable<T: Decodable>(
        queue: DispatchQueue = backgroundQueue) -> SDKFuture<T> {
        let serializer = IsoDateTimeSerializer<T>()
        return DataResponsePublisher(self, queue: queue, serializer: serializer)
            .value()
            .mapError { error in Data4LifeSDKError.network(error)}
            .eraseToAnyPublisher()
            .asyncFuture()
    }

    @discardableResult
    func responseData(
        queue: DispatchQueue = backgroundQueue) -> SDKFuture<Data> {
        publishData(queue: queue)
            .value()
            .mapError { error in Data4LifeSDKError.network(error)}
            .eraseToAnyPublisher()
            .asyncFuture()
    }

    func responseEmpty(
        queue: DispatchQueue = backgroundQueue) -> SDKFuture<Void> {
        publishUnserialized(queue: queue)
            .value()
            .map({ _ in return ()})
            .mapError { error in Data4LifeSDKError.network(error) }
            .eraseToAnyPublisher()
            .asyncFuture()
    }

    func responseHeaders(
        queue: DispatchQueue = backgroundQueue) -> SDKFuture<[AnyHashable: Any]> {
        return publishData(queue: queue)
            .map({ response in response.response?.allHeaderFields ?? [:]})
            .mapError { error in Data4LifeSDKError.network(error) }
            .eraseToAnyPublisher()
            .asyncFuture()
    }
}
