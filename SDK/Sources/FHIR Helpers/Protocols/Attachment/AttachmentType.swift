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

import Data4LifeFHIR
import ModelsR4
import ModelIO
import Data4LifeCrypto

protocol AttachmentType: AnyObject, NSCopying {
    var attachmentId: String? { get set }
    var attachmentContentType: String? { get set }
    var attachmentData: String? { get set }
    var attachmentHash: String? { get set }
    var attachmentSize: Int? { get set }
    var creationDate: Date? { get set }
}

extension AttachmentType {
    func getData() -> Data? {
        guard let base64String = attachmentData else { return nil }
        return Data(base64Encoded: base64String)
    }
}

extension AttachmentType {
    func matches(to attachment: AttachmentType) -> Bool {
        if let ownId = attachmentId, let attachmentId = attachment.attachmentId, ownId == attachmentId {
            return true
        } else if let hash = attachmentHash, hash == attachment.attachmentHash {
            return true
        } else if let hash = attachmentHash, let attachmentDataHash = attachment.getData()?.sha1Hash, hash == attachmentDataHash {
            return true
        }
        return false
    }

    func filled(with filled: AttachmentType) -> AttachmentType {
        let attachment = copy() as! AttachmentType // swiftlint:disable:this force_cast
        attachment.attachmentId = filled.attachmentId
        if let data = filled.getData() {
            attachment.attachmentData = filled.attachmentData
            attachment.attachmentSize = data.byteCount
            attachment.attachmentHash = data.sha1Hash
        }

        return attachment
    }
}

extension Data4LifeFHIR.Attachment: AttachmentType {
    var creationDate: Date? {
        get {
            creation?.nsDate
        }
        set {
            creation = newValue?.fhir_asDateTime()
        }
    }

    var attachmentId: String? {
        get { id }
        set { self.id = newValue }
    }

    var attachmentData: String? {
        get { data_fhir }
        set { self.data_fhir = newValue }
    }

    var attachmentContentType: String? {
        get { contentType }
        set { self.contentType = newValue }
    }

    var attachmentSize: Int? {
        get { size }
        set { self.size = newValue }
    }

    var attachmentHash: String? {
        get { hash }
        set { self.hash = newValue }
    }
}

extension ModelsR4.Attachment: AttachmentType {
    var attachmentContentType: String? {
        get {
            contentType?.value?.string
        }
        set {
            self.contentType = newValue?.asFHIRStringPrimitive()
        }
    }

    var attachmentHash: String? {
        get {
            hash?.value?.dataString
        }
        set {
            guard let newValue = newValue else {
                self.hash = nil
                return
            }

            let data = ModelsR4.Base64Binary(newValue)
            self.hash = data.asPrimitive()
        }
    }

    var attachmentSize: Int? {
        get {
            guard let size = size?.value?.integer else {
                return nil
            }
            return Int(size)
        }
        set {
            self.size = newValue?.asFHIRUnsignedIntegerPrimitive()
        }
    }

    var creationDate: Date? {
        get {
            var month: Int?
            if let monthInt8 = creation?.value?.date.month {
                month = Int(monthInt8)
            }
            var year: Int?
            if let yearInt8 = creation?.value?.date.year {
                year = Int(yearInt8)
            }
            var day: Int?
            if let dayInt8 = creation?.value?.date.day {
                day = Int(dayInt8)
            }

            return Calendar.current.date(from: DateComponents(year: year, month: month, day: day))
        }
        set {
            guard let newValue = newValue else {
                self.creation = nil
                return
            }

            let components = Calendar.current.dateComponents([.year, .month, .day], from: newValue)
            guard let year = components.year, let month = components.month, let day = components.day else {
                self.creation = nil
                return
            }

            let date = ModelsR4.FHIRDate(year: year, month: UInt8(month), day: UInt8(day))
            let dateTime = ModelsR4.DateTime(date: date)
            self.creation = dateTime.asPrimitive()
        }
    }

    var attachmentId: String? {
        get {
            id?.value?.string
        }
        set {
            id = newValue?.asFHIRStringPrimitive()
        }
    }

    var attachmentData: String? {
        get {
            data?.value?.dataString
        }
        set {
            guard let newValue = newValue else {
                return
            }
            let binary = ModelsR4.Base64Binary(newValue)
            data = binary.asPrimitive()
        }
    }

    public func copy(with zone: NSZone? = nil) -> Any {
        return ModelsR4.Attachment(contentType: contentType,
                                   creation: creation,
                                   data: data,
                                   extension: self.extension,
                                   hash: self.hash,
                                   id: id,
                                   language: language,
                                   size: size,
                                   title: title,
                                   url: url)
    }
}
