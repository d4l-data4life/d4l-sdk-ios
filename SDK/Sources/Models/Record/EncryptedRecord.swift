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

struct EncryptedRecord: Decodable {

    var id: String
    var encryptedTags: [String]
    var encryptedBody: String
    var createdAt: Date
    var date: Date
    var encryptedDataKey: String
    var encryptedAttachmentKey: String?
    var modelVersion: Int
    var commonKeyId: String?

    enum CodingKeys: String, CodingKey {
        case id = "record_id"
        case encryptedTags = "encrypted_tags"
        case encryptedBody = "encrypted_body"
        case createdAt = "createdAt"
        case date
        case encryptedDataKey = "encrypted_key"
        case encryptedAttachmentKey = "attachment_key"
        case modelVersion = "model_version"
        case commonKeyId = "common_key_id"
    }
}

extension EncryptedRecord {
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy:  CodingKeys.self)
        try id = container.decode(String.self, forKey: .id)
        try encryptedTags = container.decode([String].self, forKey: .encryptedTags)
        try encryptedBody = container.decode(String.self, forKey: .encryptedBody)
        try createdAt = container.decode(Date.self, forKey: .createdAt)
        try encryptedDataKey = container.decode(String.self, forKey: .encryptedDataKey)
        try encryptedAttachmentKey = container.decodeIfPresent(String.self, forKey: .encryptedAttachmentKey)
        try modelVersion = container.decode(Int.self, forKey: .modelVersion)
        try commonKeyId = container.decodeIfPresent(String.self, forKey: .commonKeyId)

        let dateString = try container.decode(String.self, forKey: .date)
        let formatter = DateFormatter.with(format: .iso8601Date)
        formatter.timeZone = TimeZone(abbreviation: "UTC")

        guard let parsedDate = formatter.date(from: dateString) else {
            throw Data4LifeSDKError.invalidRecordDateFormat
        }

        self.date = parsedDate
    }
}
