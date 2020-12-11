//
//  DocumentListSchema.swift
//  Example
//
//  Created by Alessio Borraccino on 08.12.20.
//  Copyright © 2020 HPS Gesundheitscloud gGmbH. All rights reserved.
//

import Foundation
import Data4LifeFHIR
import ModelsR4
import Data4LifeSDK

typealias DocumentTableSchema = [DocumentListSectionType]

extension DocumentTableSchema {

    static var empty: DocumentTableSchema {
        [
            .stu3Record(documents: []),
            .r4Record(documents: []),
            .appData(records: []),
            .loading(isLoading: false)
        ]
    }

    private func index(of section: DocumentListSectionType) -> Int {
        let sameCaseIndex = firstIndex { (element) -> Bool in
            return section.isSameCase(as: element)
        }

        guard let index =  sameCaseIndex else { fatalError("section should always be present") }
        return index
    }

    mutating func set(_ sectionType: DocumentListSectionType) {
        self[index(of: sectionType)] = sectionType
    }

    mutating func append(_ newSectionType: DocumentListSectionType) {
        let indexOfType = index(of: newSectionType)
        let currentType = self[indexOfType]
        switch (currentType, newSectionType) {
        case (.appData(let currentRecords), .appData(let newRecords)):
            set(.appData(records: currentRecords + newRecords))
        case (.stu3Record(let currentRecords), .stu3Record(let newRecords)):
            set(.stu3Record(documents: currentRecords + newRecords))
        case (.r4Record(let currentRecords), .r4Record(let newRecords)):
            set(.r4Record(documents: currentRecords + newRecords))
        default:
            break
        }
    }
}

enum DocumentListSectionType {
    case stu3Record(documents: [Data4LifeFHIR.DocumentReference])
    case r4Record(documents: [ModelsR4.DocumentReference])
    case appData(records: [AppDataRecord])
    case loading(isLoading: Bool)

    var cellCount: Int {
        switch self {
        case .stu3Record(let docs):
            return docs.count
        case .r4Record(let docs):
            return docs.count
        case .appData(let records):
            return records.count
        case .loading(let isLoading):
            return isLoading ? 1 : 0
        }
    }

    func isSameCase(as otherCase: DocumentListSectionType) -> Bool {
        switch (self, otherCase) {
        case (.stu3Record, .stu3Record), (.r4Record, .r4Record), (.appData, .appData), (.loading, .loading):
            return true
        default:
            return false
        }
    }
}
