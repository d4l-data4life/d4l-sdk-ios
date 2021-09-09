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
import Alamofire
import Data4LifeSDK

protocol InteractiveURLProtocolDelegate: AnyObject {
    func shouldRespond(to request: URLRequest) -> Data?
}

class InteractiveURLProtocol: URLProtocol {
    static weak var delegate: InteractiveURLProtocolDelegate?
    static var storeResponses = false

    // MARK: URLProtocol method
    override public class func canInit(with request: URLRequest) -> Bool { return true }
    override public class func canonicalRequest(for request: URLRequest) -> URLRequest { return request }
    override public func stopLoading() { }
    override public func startLoading() {
        guard let delegate = InteractiveURLProtocol.delegate else { fatalError("Missing delegate") }

        // Ask delegate for response data
        if let responseData = delegate.shouldRespond(to: request) {
            client?.urlProtocol(self, didLoad: responseData)
            client?.urlProtocolDidFinishLoading(self)
        } else {
            // delegate returned nil, try to load remote resource
            print("Request: \(request.url?.absoluteString ?? "nothing...")")
            load(request: request) { [weak self] (data, error) in
                guard let weakSelf = self else { fatalError() }
                if let error = error {
                    print("Error: \(error.localizedDescription)")
                    weakSelf.client?.urlProtocol(weakSelf, didFailWithError: error)
                } else if let response = data {

                    if InteractiveURLProtocol.storeResponses == true {
                        let documentsUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
                        let name = weakSelf.request.url!.pathComponents.filter({ $0 != "/" }).joined(separator: "-")
                        let filename = name + "-" + String(describing: Date().timeIntervalSince1970) + ".json"
                        let responseUrl = documentsUrl.appendingPathComponent(filename)
                        do {
                            try response.write(to: responseUrl)
                            print("Response: \(responseUrl.absoluteString)")
                        } catch {
                            print(error.localizedDescription)
                        }
                    } else {
                        print("Response: \(String(data: response, encoding: .utf8) ?? "nil")")
                    }

                    weakSelf.client?.urlProtocol(weakSelf, didLoad: response)
                }
                weakSelf.client?.urlProtocolDidFinishLoading(weakSelf)
            }
        }
    }

    // MARK: Helpers
    private func load(request: URLRequest, callback: @escaping (Data?, Error?) -> Void) {
        func complete(data: Data?, error: Error?) {
            guard Thread.isMainThread == false else {
                callback(data, error)
                return
            }
            DispatchQueue.main.async {
                callback(data, error)
            }
        }
        DispatchQueue.global(qos: .background).async {
            let task = URLSession.shared.dataTask(with: request, completionHandler: { (data, response, _) in
                guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 401 else {
                    complete(data: nil, error: Data4LifeSDKError.notLoggedIn)
                    return
                }
                complete(data: data, error: nil)
            })
            task.resume()
        }
    }
}
