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

@_implementationOnly import Alamofire
import Combine
import Foundation

/// Make Alamofire compatible with custom completion handler
extension DataRequest {
    func responseDecodable<T: Decodable>(
        queue: DispatchQueue = backgroundQueue) -> SDKFuture<T> {
        return SDKFuture { promise in
            self.validate().responseDecodable(queue: queue) { (response: AFDataResponse<T>)  in
                switch response.result {
                case .success(let value):
                    promise(.success(value))
                case .failure(let error):
                    promise(.failure(error))
                }
            }
        }
    }

    @discardableResult
    func responseData(
        queue: DispatchQueue = backgroundQueue) -> SDKFuture<Data> {
        return SDKFuture { promise in
            self.validate().responseData(queue: queue) { (response) in
                switch response.result {
                case .success(let value):
                    promise(.success(value))
                case .failure(let error):
                    promise(.failure(error))
                }
            }
        }
    }

    func responseEmpty(
        queue: DispatchQueue = backgroundQueue) -> SDKFuture<Void> {
        return SDKFuture { promise in
            self.validate().response(queue: queue) { response in
                switch response.result {
                case .success:                    promise(.success(()))
                case .failure(let error):
                    promise(.failure(error))
                }
            }
        }
    }

    func responseHeaders(
        queue: DispatchQueue = backgroundQueue) -> SDKFuture<[AnyHashable: Any]> {
        return SDKFuture { promise in
            self.validate().responseData(queue: queue) { response in
                switch response.result {
                case .success:
                    promise(.success(response.response?.allHeaderFields ?? [:]))
                case .failure(let error):
                    promise(.failure(error))
                }
            }
        }
    }
}
