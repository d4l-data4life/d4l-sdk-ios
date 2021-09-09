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
import XCTest
import Alamofire
@testable import Data4LifeSDK

private struct Route {
    let method: String
    let path: String

    init(_ method: String, _ path: String) {
        self.method = method
        self.path = path
    }
}

private struct Fixture {
    let headers: [String: String]
    let body: Any
    let code: Int
}

extension Route: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(method.hashValue ^ path.hashValue)
    }
}

private func == (lhs: Route, rhs: Route) -> Bool {
    return lhs.method == rhs.method && lhs.path == rhs.path
}

/// Global constant that holds response data
private var responseFixtures: [Route: Fixture] = [:]

/// Global constant that stores data that was send in request body
private var requestData: [Route: Any] = [:]

/// Global constant that stores headers that were attached to a request
private var requestHeaders: [Route: Any] = [:]

/// Make a certain route to return specific JSON data
func stub(_ method: String, _ path: String, with data: Any, code: Int = 200) {
    let route = Route(method, path)
    responseFixtures[route] = Fixture(headers: ["Content-Type": "application/json"], body: data, code: code)
}

/// Make a certain route return some binary data
func stub(_ method: String, _ path: String,
          with data: Data, headers: [String: String] = [:], code: Int = 200) {
    let route = Route(method, path)
    responseFixtures[route] = Fixture(headers: headers, body: data, code: code)
}

/// Remove all stubs
func clearStubs() {
    requestData.removeAll()
    responseFixtures.removeAll()
}

/// Assert that data that was send to some endpoint is equal to some data
func XCTAssertRequestDataEquals(_ method: String,
                                _ path: String,
                                with data: Any,
                                file: StaticString = #file, line: UInt = #line) {
    let route = Route(method, path)

    // Comparision of Any types doesn't work, so we just cast them ¯\_(ツ)_/¯
    if let data = data as? [Any], let storedData = requestData[route] as? [Any] {
        XCTAssertEqual(data, storedData, file: file, line: line)
    } else if let data = data as? [String: Any], let storedData = requestData[route] as? [String: Any] {
        XCTAssertEqual(data, storedData, file: file, line: line)
    } else if let data = data as? Data, let storedData = requestData[route] as? Data {
        XCTAssertEqual(data, storedData, file: file, line: line)
    } else {
        XCTFail(file: file, line: line)
    }
}

func XCTAssertRequestHeadersContain(_ method: String,
                                    _ path: String,
                                    headers: [String: String],
                                    file: StaticString = #file, line: UInt = #line) {
    let route = Route(method, path)
    if let storedHeaders = requestHeaders[route] as? [String: String] {
        headers.forEach { key, value in
            if let storedValue = storedHeaders[key] {
                XCTAssert(storedValue == value, file: file, line: line)
            } else {
                XCTFail(file: file, line: line)
            }
        }
    } else {
        XCTFail(file: file, line: line)
    }
}

func XCTAssertRouteCalled(_ method: String,
                          _ path: String,
                          file: StaticString = #file, line: UInt = #line) {
    let route = Route(method, path)
    let response = responseFixtures[route]
    XCTAssertNotNil(response, file: file, line: line)
}

class StubbedURLProtocol: URLProtocol {
    private var cannedResponse: Data?

    override class func canInit(with request: URLRequest) -> Bool { return true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { return request }

    override func startLoading() {
        let route = Route(request.httpMethod!, request.url!.path)
        if let query = request.url?.query {
            let queryRoute = Route(request.httpMethod!, request.url!.path + "?" + query)
            requestData[queryRoute] = ()
        }

        if request.allHTTPHeaderFields?.isEmpty == false {
            requestHeaders[route] = request.allHTTPHeaderFields!
        }

        requestData[route] = ()

        // Save request data
        let jsonOption = JSONSerialization.ReadingOptions.allowFragments
        if let httpBody = request.httpBody {
            let postData = try? JSONSerialization.jsonObject(with: httpBody,
                                                             options: jsonOption)
            requestData[route] = postData
        } else if let httpBodyStream = request.httpBodyStream {
            httpBodyStream.open()
            if request.allHTTPHeaderFields?["Content-Type"] == "application/json" {
                let postData = try? JSONSerialization.jsonObject(with: httpBodyStream,
                                                                 options: jsonOption)
                requestData[route] = postData
            } else {
                let size = Int(request.allHTTPHeaderFields?["Content-Length"] ?? "") ?? 0
                var rawData = [UInt8](repeating: 0, count: size)
                httpBodyStream.read(&rawData, maxLength: size)
                requestData[route] = Data.init(rawData)
            }
            httpBodyStream.close()

        }

        // Build response
        let response: HTTPURLResponse
        if let fixture = responseFixtures[route] {
            if JSONSerialization.isValidJSONObject(fixture.body) {
                cannedResponse = try? JSONSerialization.data(withJSONObject: fixture.body, options: [])
            } else {
                cannedResponse = fixture.body as? Data
            }
            response = HTTPURLResponse(url: request.url!,
                                       statusCode: fixture.code,
                                       httpVersion: "HTTP/1.1",
                                       headerFields: fixture.headers)!
        } else {
            cannedResponse = "{\"error\": \"Not found.\"}".data(using: String.Encoding.utf8)
            response = HTTPURLResponse(url: request.url!,
                                       statusCode: 404,
                                       httpVersion: "HTTP/1.1",
                                       headerFields: ["Content-Type": "application/json"])!
        }

        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: URLCache.StoragePolicy.notAllowed)
        client?.urlProtocol(self, didLoad: cannedResponse!)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}

extension SessionService {
    static func stubbedSessionService(versionValidator: SDKVersionValidatorType,
                                      networkManager: ReachabilityType = Reachability(NetworkReachabilityManager()),
                                      serverTrustManager: ServerTrustManager? = nil,
                                      interceptor: RequestInterceptorType? = nil)
    -> SessionService {
        let configuration = URLSessionConfiguration.default
        configuration.protocolClasses = [StubbedURLProtocol.self]

        return SessionService(configuration: configuration,
                              versionValidator: versionValidator,
                              serverTrustManager: serverTrustManager,
                              networkManager: networkManager,
                              interceptor: interceptor)
    }
}
