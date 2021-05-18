//
//  Combine+Then.swift
//  Data4LifeSDK
//
//  Created by Alessio Borraccino on 14.05.21.
//  Copyright © 2021 HPS Gesundheitscloud gGmbH. All rights reserved.
//

import Foundation
import Combine

private var asyncStorage: Set<AnyCancellable> = []
private let asyncStorageQueue: DispatchQueue = DispatchQueue(label: "combine.async.storageQueue")
private let asyncQueue: DispatchQueue = DispatchQueue(label: "combine.async.queue", attributes: .concurrent)

@discardableResult func combineAwait<Value,Error>(_ promise: Future<Value, Error>) throws -> Value {
    var result: Value!
    var error: Error?
    let group = DispatchGroup()

    group.enter()
    let cancellable = promise
        .sink(receiveCompletion: { errorCompletion in
            switch errorCompletion {
            case .failure(let failureError):
                error = failureError
            case .finished:
                break
            }
            group.leave()
        }, receiveValue: { value in
            result = value
        })
    group.wait()

    asyncStorageQueue.async {
        asyncStorage.insert(cancellable)
    }

    if let error = error {
        throw error
    } else {
        return result
    }
}

@discardableResult func combineAsync<Value, E>(_ task: @escaping () throws -> Value) -> Future<Value, E> where E: Swift.Error {
    let future = Future<Value, E> { promise in
        asyncQueue.async {
            do {
                let value = try task()
                promise(.success(value))
            } catch { // swiftlint:disable force_cast
                promise(.failure(error as! E))
            }
        }
    }

    return future
}

extension Publisher {
    var asyncFuture: Future<Output, Failure> {
        return Future<Output, Failure> { promise in
            asyncQueue.async {
                let cancellable = self.sink { completion in
                    if case .failure(let error) = completion {
                        promise(.failure(error))
                    }
                } receiveValue: { value in
                    promise(.success(value))
                }
                asyncStorageQueue.async {
                    asyncStorage.insert(cancellable)
                }
            }
        }
    }
}
