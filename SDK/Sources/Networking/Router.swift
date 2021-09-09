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
@_implementationOnly import Alamofire

typealias Headers = [(key: String , value: String)]

enum Router: URLRequestConvertible {
    static var baseUrl = ""

    // MARK: OAuth
    case authorize
    case fetchToken
    case revokeToken(parameters: Parameters, headers: Headers)

    // MARK: Records
    case createRecord(userId: String, parameters: Parameters)
    case fetchRecord(userId: String, recordId: String)
    case updateRecord(userId: String, recordId:String, parameters: Parameters)
    case searchRecords(userId: String, parameters: Parameters)
    case deleteRecord(userId: String, recordId: String)
    case countRecords(userId: String, parameters: Parameters)

    // MARK: Documents
    case createDocument(userId: String, headers: Headers)
    case fetchDocument(userId: String, documentId: String)
    case deleteDocument(userId: String, documentId: String)

    // MARK: Users
    case userInfo

    // MARK: Version
    case versionInfo(version: String)

    // MARK: Common Key
    case fetchCommonKey(userId: String, commonKeyId: String)

    var method: HTTPMethod {
        switch self {
        case .authorize,
             .createRecord,
             .createDocument,
             .fetchToken,
             .revokeToken:
            return .post
        case .fetchRecord,
             .searchRecords,
             .fetchDocument,
             .userInfo,
             .versionInfo,
             .fetchCommonKey:
            return .get
        case .deleteRecord,
             .deleteDocument:
            return .delete
        case .updateRecord:
            return .put
        case .countRecords:
            return .head
        }
    }

    var path: String {
        switch self {
        case .authorize:
            return "/oauth/authorize"
        case .fetchToken:
            return "/oauth/token"
        case .createRecord(let userId, _),
             .searchRecords(let userId, _):
            return "/users/\(userId)/records"
        case .fetchRecord(let userId, let recordId),
             .deleteRecord(let userId, let recordId):
            return "/users/\(userId)/records/\(recordId)"
        case .updateRecord(let userId, let recordId, _):
            return "/users/\(userId)/records/\(recordId)"
        case .createDocument(let userId, _):
            return "/users/\(userId)/documents"
        case .fetchDocument(let userId, let documentId):
            return "/users/\(userId)/documents/\(documentId)"
        case .deleteDocument(let userId, let documentId):
            return "/users/\(userId)/documents/\(documentId)"
        case .revokeToken:
            return "/oauth/revoke"
        case .countRecords(let userId, _):
            return "/users/\(userId)/records"
        case .userInfo:
            return "/userinfo"
        case .versionInfo(let version):
            return "/sdk/\(version)/ios/versions.json"
        case .fetchCommonKey(let userId, let commonKeyId):
            return "/users/\(userId)/commonkeys/\(commonKeyId)"
        }
    }

    var needsVersionValidation: Bool {
        switch self {
        case .versionInfo:
            return false
        default:
            return true
        }
    }

    func encode(urlRequest: URLRequest) throws -> URLRequest {
        switch self {
        case .createRecord(_, let parameters),
             .updateRecord(_, _, let parameters):
            return try JSONEncoding.default.encode(urlRequest, with: parameters)
        case .revokeToken(let parameters, _),
             .searchRecords(_, let parameters),
             .countRecords(_, let parameters):
            return try URLEncoding.default.encode(urlRequest, with: parameters)
        default:
            return urlRequest
        }
    }

    var headers: Headers? {
        switch self {
        case .createRecord,
             .fetchRecord,
             .deleteRecord,
             .updateRecord,
             .searchRecords,
             .countRecords,
             .fetchDocument,
             .fetchCommonKey,
             .userInfo:
            return [("Authorization", "")]
        case .createDocument(_, let headers):
            return [("Authorization", "")] + headers
        case .revokeToken(_, let headers):
            return headers
        default:
            return nil
        }
    }

    func makeURL() throws -> URL {
        let url = try Router.baseUrl
            .asURL()
            .appendingPathComponent(path)

        return url
    }

    // MARK: URLRequestConvertible
    func asURLRequest() throws -> URLRequest {
        let url = try makeURL()

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = method.rawValue

        urlRequest = try encode(urlRequest: urlRequest)
        headers?.forEach { urlRequest.setValue($1, forHTTPHeaderField: $0) }

        return urlRequest
    }
}

extension Router {

    static func configure(with configuration: ClientConfiguration) {
        baseUrl = configuration.apiBaseUrlString
    }

    static func authorizeUrl() throws -> URL {
        do {
            return try Router.authorize.makeURL()
        } catch {
            throw Data4LifeSDKError.ClientConfiguration.couldNotBuildOauthUrls
        }
    }

    static func fetchTokenUrl() throws -> URL {
        do {
            return try Router.fetchToken.makeURL()
        } catch {
            throw Data4LifeSDKError.ClientConfiguration.couldNotBuildOauthUrls
        }
    }
}