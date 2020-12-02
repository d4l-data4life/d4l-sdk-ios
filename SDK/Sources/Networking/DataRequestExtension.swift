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

import Alamofire
import Then

/// Make Alamofire compatible with custom completion handler
extension DataRequest {
    func responseDecodable<T: Decodable>(
        queue: DispatchQueue? = backgroundQueue) -> Async<T> {
        return Async<T> { resolve, reject in
            self.validate().responseDecodable(queue: queue) { (response: DataResponse<T>)  in
                switch response.result {
                case .success(let value):
                    resolve(value)
                case .failure(let error):
                    reject(error)
                }
            }
        }
    }

    @discardableResult
    func responseData(
        queue: DispatchQueue? = backgroundQueue) -> Async<Data> {
        return Async { resolve, reject in
            self.validate().responseData(queue: queue) { (response) in
                switch response.result {
                case .success(let value):
                    resolve(value)
                case .failure(let error):
                    reject(error)
                }
            }
        }
    }

    func responseEmpty(
        queue: DispatchQueue? = backgroundQueue) -> Async<Void> {
        return Async { (resolve : @escaping (() -> Void), reject: @escaping ((Error) -> Void)) in
            self.validate().responseData(queue: queue) { response in
                switch response.result {
                case .success:
                    resolve()
                case .failure(let error):
                    reject(error)
                }
            }
        }
    }

    func responseHeaders(
        queue: DispatchQueue? = backgroundQueue) -> Async<[AnyHashable: Any]> {
        return Async { resolve, reject in
            self.validate().responseData(queue: queue) { response in
                switch response.result {
                case .success:
                    resolve(response.response?.allHeaderFields ?? [:])
                case .failure(let error):
                    reject(error)
                }
            }
        }
    }
}
