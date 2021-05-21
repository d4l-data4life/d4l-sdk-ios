//
//  Combine+Test.swift
//  Data4LifeSDKTests
//
//  Created by Alessio Borraccino on 17.05.21.
//  Copyright © 2021 HPS Gesundheitscloud gGmbH. All rights reserved.
//

import Foundation
import Combine
import XCTest

private var testStorage: Set<AnyCancellable> = []

extension Publisher {

    func then(_ onValue: @escaping (Output) -> Void = { _ in XCTFail("Got value but expected an error instead")},
              onError: @escaping (Failure) -> Void = { _ in XCTFail("Got error but expected a value instead")},
              finally: @escaping () -> Void = {}) {
        sink { sinkResult in
            switch sinkResult {
            case .finished:
                break
            case .failure(let error):
                onError(error)
            }
            finally()
        } receiveValue: { value in
            onValue(value)
        }.store(in: &testStorage)
    }
}
