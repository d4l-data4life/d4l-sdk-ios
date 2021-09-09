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
import Combine

typealias SDKFuture<T> = Future<T, Error>
typealias NoErrorFuture<T> = Future<T, Never>

extension Publisher {
    @discardableResult
    func complete(queue: DispatchQueue = DispatchQueue.main,
                  _ completion: @escaping ResultBlock<Output>,
                  finally: (() -> Void)? = nil) -> AnyCancellable {
        let cancellable =
            receive(on: queue)
            .sink { sinkResult in

                switch sinkResult {
                case .failure(let error):
                    completion(.failure(error))
                case .finished:
                    break
                }
                finally?()

            } receiveValue: { value in
                completion(.success(value))
            }

        FutureExecutor.storeTaskHandler(cancellable)
        return cancellable
    }
}
