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

protocol FhirIdentifierType {
    var assignerString: String? { get }
    var valueString: String? { get }
}

extension Data4LifeFHIR.Identifier: FhirIdentifierType {
    var assignerString: String? {
        assigner?.reference
    }

    var valueString: String? {
        value
    }
}

extension ModelsR4.Identifier: FhirIdentifierType {
    var assignerString: String? {
        assigner?.reference?.value?.string
    }

    var valueString: String? {
        value?.value?.string
    }
}

public protocol CustomIdentifierMutable: class {
    func addAdditionalId(_ id: String)
    func setAdditionalIds(_ ids: [String])
    func getAdditionalIds() -> [String]?
}

protocol CustomIdentifierProtocol: CustomIdentifierMutable {
    var customIdentifiers: [FhirIdentifierType]? { get set }
}

extension CustomIdentifierProtocol {
    public func addAdditionalId(_ id: String) {
        let newIdentifier = Identifier(identifier: id, partnerId: Resource.partnerId)
        if var currentIdentifiers = customIdentifiers {
            currentIdentifiers.append(newIdentifier)
            customIdentifiers = currentIdentifiers
        } else {
            customIdentifiers = [newIdentifier]
        }
    }

    public func setAdditionalIds(_ ids: [String]) {
        let newIds = ids.map { Identifier(identifier: $0, partnerId: Resource.partnerId) }
        if let otherIds = customIdentifiers?.filter({ $0.assignerString != Resource.partnerId }) {
            customIdentifiers = otherIds + newIds
        } else {
            customIdentifiers = newIds
        }
    }

    public func getAdditionalIds() -> [String]? {
        guard let identifiers = customIdentifiers?.filter({ $0.assignerString == Resource.partnerId }) else { return nil }
        let values = identifiers.compactMap({ $0.valueString })
        guard values.isEmpty == false else { return nil }
        return values
    }

    func cleanObsoleteAdditionalIdentifiers(resourceId: String?, attachmentIds: [String]) throws -> Self {
        guard let identifiers = customIdentifiers else {
            return self
        }

        let updatedIdentifiers = try identifiers.compactMap { identifier -> FhirIdentifierType? in
            guard identifier.valueString?.contains(ThumbnailsIdFactory.downscaledAttachmentIdsFormat) ?? false else {
                return identifier
            }
            guard
                let ids = identifier.valueString?.split(separator: ThumbnailsIdFactory.splitChar),
                ids.count == 4
            else {
                let resourceId = resourceId ?? "Not available"
                throw Data4LifeSDKError.invalidAttachmentAdditionalId("Resource Id: \(resourceId)")
            }

            let attachmentId = String(ids[1])
            let identifierIsInUse = attachmentIds.contains(attachmentId)

            return identifierIsInUse ? identifier : nil
        }
        customIdentifiers = updatedIdentifiers.isEmpty ? nil : updatedIdentifiers
        return self
    }
}

extension Data4LifeFHIR.DocumentReference: CustomIdentifierProtocol {
    var customIdentifiers: [FhirIdentifierType]? {
        get {
            identifier
        }
        set {
            self.identifier = newValue as? [Data4LifeFHIR.Identifier]
        }
    }
}

extension Data4LifeFHIR.Questionnaire: CustomIdentifierProtocol {
    var customIdentifiers: [FhirIdentifierType]? {
        get {
            identifier
        }
        set {
            self.identifier = newValue as? [Data4LifeFHIR.Identifier]
        }
    }
}

extension Data4LifeFHIR.Observation: CustomIdentifierProtocol {
    var customIdentifiers: [FhirIdentifierType]? {
        get {
            identifier
        }
        set {
            self.identifier = newValue as? [Data4LifeFHIR.Identifier]
        }
    }
}

extension Data4LifeFHIR.DiagnosticReport: CustomIdentifierProtocol {
    var customIdentifiers: [FhirIdentifierType]? {
        get {
            identifier
        }
        set {
            self.identifier = newValue as? [Data4LifeFHIR.Identifier]
        }
    }
}

extension Data4LifeFHIR.CarePlan: CustomIdentifierProtocol {
    var customIdentifiers: [FhirIdentifierType]? {
        get {
            identifier
        }
        set {
            self.identifier = newValue as? [Data4LifeFHIR.Identifier]
        }
    }
}

extension Data4LifeFHIR.Organization: CustomIdentifierProtocol {
    var customIdentifiers: [FhirIdentifierType]? {
        get {
            identifier
        }
        set {
            self.identifier = newValue as? [Data4LifeFHIR.Identifier]
        }
    }
}

extension Data4LifeFHIR.Practitioner: CustomIdentifierProtocol {
    var customIdentifiers: [FhirIdentifierType]? {
        get {
            identifier
        }
        set {
            self.identifier = newValue as? [Data4LifeFHIR.Identifier]
        }
    }
}

extension Data4LifeFHIR.Patient: CustomIdentifierProtocol {
    var customIdentifiers: [FhirIdentifierType]? {
        get {
            identifier
        }
        set {
            self.identifier = newValue as? [Data4LifeFHIR.Identifier]
        }
    }
}

extension ModelsR4.DocumentReference: CustomIdentifierProtocol {
    var customIdentifiers: [FhirIdentifierType]? {
        get {
            identifier
        }
        set {
            self.identifier = newValue as? [ModelsR4.Identifier]
        }
    }
}

extension ModelsR4.Questionnaire: CustomIdentifierProtocol {
    var customIdentifiers: [FhirIdentifierType]? {
        get {
            identifier
        }
        set {
            self.identifier = newValue as? [ModelsR4.Identifier]
        }
    }
}

extension ModelsR4.Observation: CustomIdentifierProtocol {
    var customIdentifiers: [FhirIdentifierType]? {
        get {
            identifier
        }
        set {
            self.identifier = newValue as? [ModelsR4.Identifier]
        }
    }
}

extension ModelsR4.DiagnosticReport: CustomIdentifierProtocol {
    var customIdentifiers: [FhirIdentifierType]? {
        get {
            identifier
        }
        set {
            self.identifier = newValue as? [ModelsR4.Identifier]
        }
    }
}

extension ModelsR4.CarePlan: CustomIdentifierProtocol {
    var customIdentifiers: [FhirIdentifierType]? {
        get {
            identifier
        }
        set {
            self.identifier = newValue as? [ModelsR4.Identifier]
        }
    }
}

extension ModelsR4.Organization: CustomIdentifierProtocol {
    var customIdentifiers: [FhirIdentifierType]? {
        get {
            identifier
        }
        set {
            self.identifier = newValue as? [ModelsR4.Identifier]
        }
    }
}

extension ModelsR4.Practitioner: CustomIdentifierProtocol {
    var customIdentifiers: [FhirIdentifierType]? {
        get {
            identifier
        }
        set {
            self.identifier = newValue as? [ModelsR4.Identifier]
        }
    }
}

extension ModelsR4.Patient: CustomIdentifierProtocol {
    var customIdentifiers: [FhirIdentifierType]? {
        get {
            identifier
        }
        set {
            self.identifier = newValue as? [ModelsR4.Identifier]
        }
    }
}
