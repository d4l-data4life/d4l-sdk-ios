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

private var cancellableStorage: Set<AnyCancellable> = []
private let asyncCancellableStorageQueue: DispatchQueue = DispatchQueue(label: "combine.async.storageQueue")

extension Publisher {
    func complete(queue: DispatchQueue = DispatchQueue.main,
                  _ completion: @escaping ResultBlock<Output>,
                  finally: (() -> Void)? = nil) {
        let cancellable = sink { sinkResult in
            queue.async {
                switch sinkResult {
                case .failure(let error):
                    completion(.failure(error))
                case .finished:
                    break
                }
                finally?()
            }
        } receiveValue: { value in
            queue.async {
                completion(.success(value))
            }
        }
        asyncCancellableStorageQueue.async {
            cancellableStorage.insert(cancellable)
        }
    }
}
