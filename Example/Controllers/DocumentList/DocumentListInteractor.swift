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
import Data4LifeSDK
import ModelsR4
import Data4LifeFHIR
import Data4LifeSDKUtils

final class DocumentListInteractor {

    private(set) lazy var schema: DocumentTableSchema = .empty
    private var pageNumber = 1
    private let pageSize = 20
    private var shouldLoadNextPage = false
    private(set) var dates: [Int: Date]?
    private var fromDate: Date? {
        return dates?[0] ?? nil
    }

    private var toDate: Date? {
        return dates?[1] ?? nil
    }

    weak var view: DocumentListTableViewController?
    private let d4lClient: Data4LifeClient
    init(view: DocumentListTableViewController, d4lClient: Data4LifeClient = Data4LifeClient.default) {
        self.view = view
        self.d4lClient = d4lClient
    }
}

extension DocumentListInteractor {
    func viewDidLoad() {
        d4lClient.sessionStateDidChange { [weak self] currentState in
            DispatchQueue.main.async { [weak self] in
                self?.view?.updateUI(state: currentState)
            }
            if currentState {
                self?.loadAllData()
            }
        }

        loadAllData()
    }

    func viewDidAppear() {
        d4lClient.isUserLoggedIn { [weak self] result in
            let state = result.error == nil ? true : false
            self?.view?.updateUI(state: state)
        }
    }

    func didPullToRefresh() {
        loadAllData()
    }

    private func resetData() {
        pageNumber = 1
        schema = .empty
        view?.updateTableView()
    }

    // MARK: - User auth actions

    func didTapLogout() {
        d4lClient.logout { [weak self] result in
            switch result {
            case .success:
                self?.resetData()
            case .failure(let error):
                self?.view?.presentError(error)
            }
        }
    }

    func didTapLogin() {
        guard let view = view else {
            return
        }
        d4lClient.presentLogin(on: view, animated: true) { [weak self] result in
            switch result {
            case .success:
                self?.loadAllData()
            case .failure(let error):
                self?.view?.presentError(error)
            }
        }
    }

    func didTapAddAppData() {
        //let userKey = UserKey(t: "t", priv: "priv", pub: "pub", v: 5, scope: "scope")
        let hellosString = "{\"word\":\"hello\"}"
        let hello = Data(hellosString.utf8)
        d4lClient.createAppDataRecord(hello, annotations: ["annotest"]) { [weak self] result in
            switch result {
            case .success:
                self?.loadAppData {
                    self?.view?.updateTableView()
                }
            case .failure(let error):
                self?.view?.presentError(error)
            }
        }
    }

    func willDisplayLoadingCell() {
        if shouldLoadNextPage {
            schema.set(.loading(isLoading: true))
            view?.updateTableView()
            shouldLoadNextPage = false
            loadAllData()
        } else {
            schema.set(.loading(isLoading: false))
            view?.updateTableView()
        }
    }

    func didSelectDates(_ dates: [Int: Date]?) {
        pageNumber = 1
        self.dates = dates
    }

    func didPickFiles(_ files: [FileData], titled title: String, version: DocumentVersion) {
        switch version {
        case .stu3:
            let attachments = files.compactMap { $0.toStu3Attachment }
            let document = Data4LifeFHIR.DocumentReference.make(titled: title, attachments: attachments)
            d4lClient.createFhirStu3Record(document) { [weak self] result in
                switch result {
                case .success(let record):
                    self?.schema.append(.stu3Record(documents: [record.fhirResource]))
                    self?.view?.updateTableView()
                case .failure(let error):
                    self?.view?.presentError(error)
                }
            }

        case .r4:
            let attachments = files.compactMap { $0.toR4Attachment }
            let document = ModelsR4.DocumentReference.make(titled: title, attachments: attachments)

            d4lClient.createFhirR4Record(document) { [weak self] result in
                switch result {
                case .success(let record):
                    self?.schema.append(.r4Record(documents: [record.fhirResource]))
                    self?.view?.updateTableView()
                case .failure(let error):
                    self?.view?.presentError(error)
                }
            }
        }
    }

    // swiftlint:disable cyclomatic_complexity
    func didDeleteCell(at indexPath: IndexPath) {
        switch schema[indexPath.section] {
        case .stu3Record(var documents):
            let document = documents[indexPath.row]
            guard let id = document.id else { return }
            d4lClient.deleteFhirStu3Record(withId: id) { result in
                switch result {
                case .success:
                    documents.remove(at: indexPath.row)
                    self.schema.set(.stu3Record(documents: documents))
                    self.view?.updateTableView()
                case .failure(let error):
                    self.view?.presentError(error)
                }
            }
        case .r4Record(var documents):
            let document = documents[indexPath.row]
            guard let id = document.id?.value?.string else { return }
            d4lClient.deleteFhirR4Record(withId: id) { result in
                switch result {
                case .success:
                    documents.remove(at: indexPath.row)
                    self.schema.set(.r4Record(documents: documents))
                    self.view?.updateTableView()
                case .failure(let error):
                    self.view?.presentError(error)
                }
            }
        case .appData(var records):
            let appData = records[indexPath.row]
            d4lClient.deleteAppDataRecord(withId: appData.id) { result in
                switch result {
                case .success:
                    records.remove(at: indexPath.row)
                    self.schema.set(.appData(records: records))
                    self.view?.updateTableView()
                case .failure(let error):
                    self.view?.presentError(error)
                }
            }
        default:
            break
        }
    }
}

private extension DocumentListInteractor {
    private func loadAllData() {
        loadAppData { [weak self] in
            self?.loadR4Documents { [weak self] in
                self?.loadStu3Documents()
            }
        }
    }

    private func loadAppData(_ completion: @escaping () -> Void = {}) {
        d4lClient.fetchAppDataRecords(annotations: ["annotest"]) { [weak self] result in
            switch result {
            case .success(let appData):
                self?.schema.set(.appData(records: appData))
            case .failure(let error):
                self?.view?.presentError(error)
            }
            completion()
        }
    }

    private func loadR4Documents(_ completion: @escaping () -> Void = {}) {
        d4lClient.fetchFhirR4Records(of: DocumentReference.self) { [weak self] result in
            switch result {
            case .success(let records):
                let documents = records.map { $0.fhirResource }
                self?.schema.set(.r4Record(documents: documents))
            case .failure(let error):
                self?.view?.presentError(error)
            }
            completion()
        }
    }

    private func loadStu3Documents(_ completion: @escaping () -> Void = {}) {
        d4lClient.fetchFhirStu3Records(of: DocumentReference.self, size: pageSize, page: pageNumber, from: fromDate, to: toDate) { [weak self] result in
            switch result {
            case .success(let records):
                guard let pageNumber = self?.pageNumber, let pageSize = self?.pageSize else {
                    return
                }

                let documents = records.map { $0.fhirResource }
                if pageNumber > 1 {
                    self?.schema.append(.stu3Record(documents: documents))
                } else {
                    self?.schema.set(.stu3Record(documents: documents))
                }

                if pageSize == documents.count {
                    self?.shouldLoadNextPage = true
                    self?.pageNumber = pageNumber + 1
                } else {
                    self?.shouldLoadNextPage = false
                }
            case .failure(let error):
                self?.view?.presentError(error)
            }

            self?.view?.updateTableView()
        }
    }
}
