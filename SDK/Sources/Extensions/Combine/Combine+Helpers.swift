//
//  Combine+Then.swift
//  Data4LifeSDK
//
//  Created by Alessio Borraccino on 14.05.21.
//  Copyright © 2021 HPS Gesundheitscloud gGmbH. All rights reserved.
//

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
