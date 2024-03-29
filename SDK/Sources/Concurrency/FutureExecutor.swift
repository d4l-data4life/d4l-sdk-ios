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

@discardableResult
func combineAsync<Value, E>(_ task: @escaping () throws -> Value) -> Future<Value, E> where E: Swift.Error {
    FutureExecutor.combineAsync(task)
}

@discardableResult
func combineAsync<Value>(_ task: @escaping () -> Value) -> Future<Value, Never> {
    FutureExecutor.combineAsync(task)
}

@discardableResult
func combineAwait<Value,Error>(_ future: Future<Value, Error>) throws -> Value {
    try FutureExecutor.combineAwait(future)
}

@discardableResult
func combineAwait<Value>(_ future: Future<Value, Never>) -> Value {
    do {
        return try FutureExecutor.combineAwait(future)
    } catch {
        fatalError("path is impossible to reach")
    }
}

func cancelTask(_ cancellable: AnyCancellable) {
    FutureExecutor.cancelTask(cancellable)
}

extension Publisher {
    func asyncFuture(queue: DispatchQueue = FutureExecutor.asyncQueue) -> Future<Output, Failure> {
        return Future<Output, Failure> { promise in
            queue.async {
                let cancellable = self.sink { completion in
                    if case .failure(let error) = completion {
                        promise(.failure(error))
                    }
                } receiveValue: { value in
                    promise(.success(value))
                }

                FutureExecutor.storeTaskHandler(cancellable)
            }
        }
    }
}

final class FutureExecutor {

    private static var asyncStorage: Set<AnyCancellable> = []
    private static let asyncStorageQueue: DispatchQueue = DispatchQueue(label: "combine.async.storageQueue")
    fileprivate static let asyncQueue: DispatchQueue = DispatchQueue(label: "combine.async.queue", attributes: .concurrent)

    @discardableResult fileprivate static func combineAwait<Value,Error>(_ future: Future<Value, Error>) throws -> Value {
        var result: Value!
        var error: Error?
        let group = DispatchGroup()

        group.enter()
        let cancellable = future
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

        storeTaskHandler(cancellable)

        if let error = error {
            throw error
        } else {
            return result
        }
    }

    @discardableResult fileprivate static func combineAsync<Value, E>(_ task: @escaping () throws -> Value, queue: DispatchQueue = asyncQueue) -> Future<Value, E> where E: Swift.Error {
        let future = Future<Value, E> { promise in
            queue.async {
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

    static func storeTaskHandler(_ cancellable: AnyCancellable) {
        asyncStorageQueue.async {
            asyncStorage.insert(cancellable)
        }
    }

    fileprivate static func cancelTask(_ cancellable: AnyCancellable) {
        cancellable.cancel()
        asyncStorageQueue.async {
            asyncStorage.remove(cancellable)
        }
    }
}
