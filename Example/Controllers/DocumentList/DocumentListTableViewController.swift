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

import UIKit
import Data4LifeSDK
import Data4LifeSDKUtils
import ModelsR4

class DocumentListTableViewController: UITableViewController {

    private lazy var schema: DocumentTableSchema = .empty

    @IBOutlet private var leftBarButton: UIBarButtonItem!
    @IBOutlet private var searchButton: UIBarButtonItem!
    @IBOutlet var headerView: UIView!

    private var documentVersionToBeAdded: DocumentVersion?
    private var pageNumber = 1
    private let pageSize = 20
    private var shouldLoadNextPage = false
    private var dates: [Int: Date]?
    private var fromDate: Date? {
        return dates?[0] ?? nil
    }

    private var toDate: Date? {
        return dates?[1] ?? nil
    }

    // MARK: - View life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.tableFooterView = UIView()

        Data4LifeClient.default.sessionStateDidChange { [weak self] currentState in
            DispatchQueue.main.async {
                self?.updateUI(state: currentState)
            }
            if currentState {
                self?.loadAllData()
            }
        }

        loadAllData()
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 44
        tableView.sectionHeaderHeight = UITableView.automaticDimension
        tableView.estimatedSectionHeaderHeight = 44
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        Data4LifeClient.default.isUserLoggedIn { [weak self] result in
            let state = result.error == nil ? true : false
            self?.updateUI(state: state)
        }
    }

    // MARK: - IBActions
    @IBAction func leftBarButtonTouched(_ sender: UIButton) {
        if leftBarButton.title == "Log out" {
            performLogout()
        } else {
            presentLogin()
        }
    }

    @IBAction func refresh(_ sender: UIRefreshControl) {
        loadAllData()
    }

    // MARK: Helpers
    func updateUI(state userSessionActive: Bool) {
            leftBarButton.title = userSessionActive ? "Log out" : "Login"
            searchButton.isEnabled = userSessionActive
            tableView.tableHeaderView = userSessionActive ? nil : headerView
    }

    func resetData() {
        pageNumber = 1
        schema = .empty
        tableView.reloadData()
    }

    func loadAllData() {
        loadAppData { [weak self] in
            self?.loadR4Documents { [weak self] in
                self?.loadStu3Documents()
            }
        }
    }

    private func loadAppData(_ completion: @escaping () -> Void = {}) {
        Data4LifeClient.default.fetchAppDataRecords(annotations: ["annotest"]) { [weak self] result in
            switch result {
            case .success(let appData):
                self?.schema.set(.appData(records: appData))
            case .failure(let error):
                self?.presentError(error)
            }
            completion()
        }
    }

    private func loadR4Documents(_ completion: @escaping () -> Void = {}) {
        Data4LifeClient.default.fetchFhirR4Records(of: DocumentReference.self) { [weak self] result in
            switch result {
            case .success(let records):
                let documents = records.map { $0.fhirResource }
                self?.schema.set(.r4Record(documents: documents))
            case .failure(let error):
                self?.presentError(error)
            }
            completion()
        }
    }

    private func loadStu3Documents(_ completion: @escaping () -> Void = {}) {
        Data4LifeClient.default.fetchFhirStu3Records(of: DocumentReference.self, size: pageSize, page: pageNumber, from: fromDate, to: toDate) { [weak self] result in
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
                self?.presentError(error)
            }

            self?.refreshControl?.endRefreshing()
            self?.tableView.reloadData()
        }
    }

    // MARK: - User auth actions

    func performLogout() {
        Data4LifeClient.default.logout { [weak self] result in
            switch result {
            case .success:
                self?.resetData()
            case .failure(let error):
                self?.presentError(error)
            }
        }
    }

    func presentLogin() {
        Data4LifeClient.default.presentLogin(on: self, animated: true) { [weak self] result in
            switch result {
            case .success:
                self?.loadAllData()
            case .failure(let error):
                self?.presentError(error)
            }
        }
    }

    private func addAppData() {
        //let userKey = UserKey(t: "t", priv: "priv", pub: "pub", v: 5, scope: "scope")
        let hellosString = "{\"word\":\"hello\"}"
        let hello = Data(hellosString.utf8)
        Data4LifeClient.default.createAppDataRecord(hello, annotations: ["annotest"]) { [weak self] result in
            switch result {
            case .success:
                self?.loadAppData {
                    self?.tableView.reloadData()
                }
            case .failure(let error):
                self?.presentError(error)
            }
        }
    }

    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let detailVC = segue.destination as? DocumentDetailViewController, let documentType = sender as? DocumentType {
            detailVC.document = documentType
        } else if let filePickerVC = segue.destination as? FilePickerViewController {
            filePickerVC.delegate = self
        } else if let filtersVC = segue.destination as? FiltersViewController {
            filtersVC.callback = { [weak self] dates in
                self?.pageNumber = 1
                self?.dates = dates
            }
            if let dates = dates {
                filtersVC.dates = dates
            }
        }
    }
}

extension DocumentListTableViewController: FilePickerDelegate {
    // MARK: - FilePickerDelegate
    func filePickerDidSelect(files: [FileData]) {
        self.presentDocumentTitleForm(for: files)
    }

    // MARK: - Upload
    func presentDocumentTitleForm(for files: [FileData]) {
        let textInputAlert = UIAlertController(title: "Creating a new document",
                                               message: "Please choose a title",
                                               preferredStyle: .alert)

        textInputAlert.addTextField { (textField) in
            textField.placeholder = "Title"
        }

        textInputAlert.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            guard let documentVersion = self?.documentVersionToBeAdded else {
                return
            }
            let title = textInputAlert.textFields?.first?.text ?? "Unnamed"
            self?.upload(files: files, titled: title, version: documentVersion)
        })

        textInputAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(textInputAlert, animated: true, completion: nil)
    }

    private func upload(files: [FileData], titled title: String, version: DocumentVersion) {
        switch version {
        case .stu3:
                do {

                    let attachments = try files.compactMap { file -> Data4LifeFHIR.Attachment? in
                        let imageData = file.image.jpegData(compressionQuality: 0.5)!
                        guard let contentType = MIMEType.of(imageData)?.rawValue else {
                            fatalError("Invalid data MIME type")
                        }
                        return try Attachment.with(title: "\(file.name).jpg",
                            creationDate: .now,
                            contentType: contentType,
                            data: imageData)
                    }

                    let document = DocumentReference()
                    document.description_fhir = title
                    document.attachments = attachments
                    document.indexed = .now
                    document.status = .current
                    document.type = CodeableConcept(code: "18782-3", display: "Radiology Study observation (findings)", system: "http://loinc.org")

                    Data4LifeClient.default.createFhirStu3Record(document) { [weak self] result in
                        switch result {
                        case .success(let record):
                            self?.schema.append(.stu3Record(documents: [record.fhirResource]))
                            self?.tableView.reloadData()
                        case .failure(let error):
                            self?.presentError(error)
                        }
                    }
                } catch {
                    self.presentError(error)
                }
        case .r4:
            do {

                let attachments = try files.compactMap { file -> ModelsR4.Attachment? in
                    let imageData = file.image.jpegData(compressionQuality: 0.5)!
                    guard let contentType = MIMEType.of(imageData)?.rawValue else {
                        fatalError("Invalid data MIME type")
                    }
                    return try Attachment.with(title: "\(file.name).jpg",
                                               creationDate: Date(),
                                               contentType: contentType,
                                               data: imageData)
                }

                let document = ModelsR4.DocumentReference.init(content: [], status: DocumentReferenceStatus.current.asPrimitive())
                document.description_fhir = title.asFHIRStringPrimitive()
                document.content = attachments.map({ ModelsR4.DocumentReferenceContent(attachment: $0)})
                document.type = ModelsR4.CodeableConcept(coding: [ModelsR4.Coding(code: "18782-3".asFHIRStringPrimitive(),
                                                                                  display: "Radiology Study observation (findings)".asFHIRStringPrimitive())
                ])

                Data4LifeClient.default.createFhirR4Record(document) { [weak self] result in
                    switch result {
                    case .success(let record):
                        self?.schema.append(.r4Record(documents: [record.fhirResource]))
                        self?.tableView.reloadData()
                    case .failure(let error):
                        self?.presentError(error)
                    }
                }
            } catch {
                self.presentError(error)
            }
        }
    }
}

extension DocumentListTableViewController {
    // MARK: - TableViewDataSource
    override func numberOfSections(in tableView: UITableView) -> Int {
        return schema.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        schema[section].cellCount
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        switch schema[indexPath.section] {
        case .stu3Record(let records):
            let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
            let document = records[indexPath.row]
            cell.textLabel?.text = document.description_fhir
            return cell
        case .r4Record(let records):
            let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
            let document = records[indexPath.row]
            cell.textLabel?.text = document.description_fhir?.value?.string
            return cell
        case .appData(let records):
            let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
            let document = records[indexPath.row]
            let text = decodeAppData(from: document)
            cell.textLabel?.text = text
            return cell
        case .loading:
            let loadingCell = tableView.dequeueReusableCell(withIdentifier: "LoadingCell", for: indexPath) as! LoadingCell
            loadingCell.selectionStyle = .none
            loadingCell.startLoading()
            return loadingCell
        }
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let title: String
        let onAdd: (() -> Void)?
        switch schema[section] {
        case .stu3Record:
            title = "Stu3 Records"
            onAdd = { [unowned self] in
                self.documentVersionToBeAdded = .stu3
                self.performSegue(withIdentifier: "recordListToFilePicker", sender: nil)
            }
        case .r4Record:
            title = "R4 Records"
            onAdd = { [unowned self] in
                self.documentVersionToBeAdded = .r4
                self.performSegue(withIdentifier: "recordListToFilePicker", sender: nil)
            }
        case .appData:
            title = "App Data"
            onAdd = { [unowned self] in self.addAppData() }
        case .loading:
            title = ""
            onAdd = nil
        }

        let header = DocumentSectionHeader()
        header.configure(title: title, onAdd: onAdd)
        header.invalidateIntrinsicContentSize()
        return header
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        UITableView.automaticDimension
    }

    override func tableView(_ tableView: UITableView, estimatedHeightForHeaderInSection section: Int) -> CGFloat {
        44
    }

    // MARK: - TableViewDelegate
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        switch schema[indexPath.section] {
        case .stu3Record(let records):
            let document = records[indexPath.row]
            performSegue(withIdentifier: "openDetail", sender: DocumentType.stu3(document))
        case .r4Record(let records):
            let document = records[indexPath.row]
            performSegue(withIdentifier: "openDetail", sender: DocumentType.r4(document))
        default:
            break
        }
    }

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        guard editingStyle == .delete else {
            return
        }

        switch schema[indexPath.section] {
        case .stu3Record(var documents):
            let document = documents[indexPath.row]
            guard let id = document.id else { return }
            Data4LifeClient.default.deleteFhirStu3Record(withId: id) { result in
                switch result {
                case .success:
                    documents.remove(at: indexPath.row)
                    self.schema.set(.stu3Record(documents: documents))
                    self.tableView.reloadData()
                case .failure(let error):
                    self.presentError(error)
                }
            }
        case .r4Record(var documents):
            let document = documents[indexPath.row]
            guard let id = document.id?.value?.string else { return }
            Data4LifeClient.default.deleteFhirR4Record(withId: id) { result in
                switch result {
                case .success:
                    documents.remove(at: indexPath.row)
                    self.schema.set(.r4Record(documents: documents))
                    self.tableView.reloadData()
                case .failure(let error):
                    self.presentError(error)
                }
            }
        case .appData(var records):
            let appData = records[indexPath.row]
            Data4LifeClient.default.deleteAppDataRecord(withId: appData.id) { result in
                switch result {
                case .success:
                    records.remove(at: indexPath.row)
                    self.schema.set(.appData(records: records))
                    self.tableView.reloadData()
                case .failure(let error):
                    self.presentError(error)
                }
            }
        default:
            break
        }
    }

    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard case .loading = schema[indexPath.section] else { return }
        if shouldLoadNextPage {
            schema.set(.loading(isLoading: true))
            tableView.reloadData()
            shouldLoadNextPage = false
            loadAllData()
        } else {
            schema.set(.loading(isLoading: false))
            tableView.reloadData()
        }
    }
}

private extension DocumentListTableViewController {
    func decodeAppData(from record: AppDataRecord) -> String {
        if let word = try? record.getDecodableResource(of: Word.self) {
            return record.annotations.joined(separator: "+") + " --- " + word.word
        } else if let userKey = try? record.getDecodableResource(of: UserKey.self) {
            return record.annotations.joined(separator: "+") + " --- " + userKey.pub
        } else if let string = String(data: record.data, encoding: .utf8) {
            return record.annotations.joined(separator: "+") + " --- " + string
        } else {
            return record.data.base64EncodedString()
        }
    }
}

struct UserKey: Codable {
    var t: String // swiftlint:disable:this identifier_name
    var priv: String
    var pub: String
    var v: Int // swiftlint:disable:this identifier_name
    var scope: String
}

struct Word: Codable {
    var word: String
}
