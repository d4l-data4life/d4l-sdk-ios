//  BSD 3-Clause License
//  
//  Copyright (c) 2019, HPS Gesundheitscloud gGmbH
//  All rights reserved.
//  
//  Redistribution and use in source and binary forms, with or without
//  modification, are permitted provided that the following conditions are met:
//  
//  * Redistributions of source code must retain the above copyright notice, this
//  list of conditions and the following disclaimer.
//  
//  * Redistributions in binary form must reproduce the above copyright notice,
//  this list of conditions and the following disclaimer in the documentation
//  and/or other materials provided with the distribution.
//  
//  * Neither the name of the copyright holder nor the names of its
//  contributors may be used to endorse or promote products derived from
//  this software without specific prior written permission.
//  
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
//  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
//  IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
//  DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
//  FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
//  DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
//  SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
//  CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
//  OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
//  OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

import Data4LifeFHIR
import ModelsR4
import ModelIO
import Data4LifeCrypto

protocol AttachmentType: AnyObject, NSCopying {
    var attachmentId: String? { get set }
    var attachmentContentType: String? { get set }
    var attachmentDataString: String? { get set }
    var attachmentHash: String? { get set }
    var attachmentSize: Int? { get set }
    var creationDate: Date? { get set }
    var attachmentData: Data? { get }
}

extension AttachmentType {
    func matches(to attachment: AttachmentType) -> Bool {
        if let ownId = attachmentId, let attachmentId = attachment.attachmentId, ownId == attachmentId {
            return true
        } else if let hash = attachmentHash, hash == attachment.attachmentHash {
            return true
        } else if let hash = attachmentHash, let attachmentDataHash = attachment.attachmentData?.sha1Hash, hash == attachmentDataHash {
            return true
        }
        return false
    }

    func filled(with filled: AttachmentType) -> AttachmentType {
        let attachment = copy() as! AttachmentType // swiftlint:disable:this force_cast
        attachment.attachmentId = filled.attachmentId
        if let data = filled.attachmentData {
            attachment.attachmentDataString = filled.attachmentDataString
            attachment.attachmentSize = data.byteCount
            attachment.attachmentHash = data.sha1Hash
        }

        return attachment
    }
}

extension Data4LifeFHIR.Attachment: AttachmentType {
    public static func with(title: String, creationDate: Date, contentType: String, data: Data) throws -> Data4LifeFHIR.Attachment {
        try Attachment.with(title: title, creationDate: creationDate.fhir_asDateTime(), contentType: contentType, data: data)
    }

//    extension Attachment {
//        public static func with(title: String,
//                                creationDate: DateTime,
//                                contentType: String,
//                                data: Data) throws -> Data4LifeFHIR.Attachment {
//
//            let attachment = Attachment()
//            attachment.title = title
//            attachment.creation = creationDate
//            attachment.contentType = contentType
//            attachment.data_fhir = data.base64EncodedString()
//            attachment.size = data.count
//            attachment.hash = data.sha1Hash
//            return attachment
//        }
//    }

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

    var attachmentDataString: String? {
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

    var attachmentData: Data? {
        guard let base64String = attachmentDataString else { return nil }
        return Data(base64Encoded: base64String)
    }
}

extension ModelsR4.Attachment: AttachmentType {

    public static func with(title: String, creationDate: Date, contentType: String, data: Data) throws -> ModelsR4.Attachment {

        let attachment = ModelsR4.Attachment()
        attachment.attachmentDataString = data.base64EncodedString()
        attachment.contentType = contentType.asFHIRStringPrimitive()
        attachment.creationDate = creationDate
        attachment.attachmentHash = data.sha1Hash
        attachment.title = title.asFHIRStringPrimitive()
        attachment.attachmentSize = data.count
        return attachment
    }

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

            let creationDateComponents = Calendar.current.dateComponents([.year,.month,.day,.hour,.minute,.second,.timeZone], from: newValue)
            guard let year = creationDateComponents.year, let month = creationDateComponents.month, let day = creationDateComponents.day,
                  let hour = creationDateComponents.hour, let minute = creationDateComponents.minute, let second = creationDateComponents.second else {
                return
            }

            let creationDateTime = ModelsR4.DateTime(date: FHIRDate.init(year: year,
                                                                         month: UInt8(month),
                                                                         day: UInt8(day)),
                                                     time: FHIRTime.init(hour: UInt8(hour),
                                                                         minute: UInt8(minute),
                                                                         second: Decimal(second)),
                                                     timezone: creationDateComponents.timeZone)
            self.creation = creationDateTime.asPrimitive()
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

    var attachmentDataString: String? {
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

    var attachmentData: Data? {
        guard let base64String = attachmentDataString else { return nil }
        return Data(base64Encoded: base64String)
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
