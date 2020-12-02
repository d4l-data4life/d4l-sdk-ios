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
import Alamofire

extension DataRequest {
    @discardableResult
    func responseDecodable<T: Decodable>(
        queue: DispatchQueue? = backgroundQueue,
        completionHandler: @escaping (DataResponse<T>) -> Void)
        -> Self {
            let responseSerializer = DataResponseSerializer<T> { _, _, data, error in
                guard error == nil, let data = data else {
                    return .failure(Data4LifeSDKError.network(error!))
                }

                do {
                    let decoder = JSONDecoder()
                    decoder.dateDecodingStrategy = .formatted(DateFormatter.with(format: .iso8601DateTime))

                    let codable: T = try decoder.decode(T.self, from: data)
                    return .success(codable)
                } catch let error {
                    return .failure(Data4LifeSDKError.jsonSerialization(error))
                }
            }

            return response(queue: queue,
                            responseSerializer: responseSerializer,
                            completionHandler: completionHandler)
    }
}
