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

class DocumentListTableViewController: UITableViewController {
    @IBOutlet var leftBarButton: UIBarButtonItem!
    @IBOutlet var addButton: UIBarButtonItem!
    @IBOutlet var searchButton: UIBarButtonItem!
    @IBOutlet var headerView: UIView!
    var documents: [DocumentReference] = []
    private var appData: [AppDataRecord] = []
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
                self?.reloadAllData()
            }
        }

        reloadAllData()
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
        resetData()
        reloadAllData()
    }

    // MARK: Helpers
    func updateUI(state userSessionActive: Bool) {
        if userSessionActive {
            leftBarButton.title = "Log out"
            searchButton.isEnabled = true
            addButton.isEnabled = true
            tableView.tableHeaderView = nil
        } else {
            leftBarButton.title = "Login"
            searchButton.isEnabled = false
            addButton.isEnabled = false
            tableView.tableHeaderView = headerView
        }
    }

    func resetData() {
        pageNumber = 1
        documents = []
        appData = []
        tableView.reloadData()
    }

    func reloadAllData() {
        loadAppData { [weak self] in
            self?.reloadDocuments()
        }
    }

    func reloadDocuments() {
        Data4LifeClient.default.fetchFhirStu3Records(of: DocumentReference.self, size: pageSize, page: pageNumber, from: fromDate, to: toDate) { [weak self] result in
            switch result {
            case .success(let records):
                guard let pageNumber = self?.pageNumber, let pageSize = self?.pageSize else {
                    return
                }

                let documents = records.map { $0.fhirResource }
                if pageNumber > 1 {
                    self?.documents.append(contentsOf: documents)
                } else {
                    self?.documents = documents
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

    @IBAction func addAppData(_ sender: Any) {
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

    func loadAppData(_ completion: @escaping () -> Void = {}) {
        Data4LifeClient.default.fetchAppDataRecords(annotations: ["annotest"]) { [weak self] result in
            switch result {
            case .success(let appData):
                self?.appData = appData
            case .failure(let error):
                self?.presentError(error)
            }
            completion()
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
                self?.reloadAllData()
            case .failure(let error):
                self?.presentError(error)
            }
        }
    }

    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let detailVC = segue.destination as? DocumentDetailViewController,
            let document = sender as? DocumentReference {
            detailVC.document = document
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

extension DocumentListTableViewController {
    // MARK: - TableViewDataSource
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            if documents.isEmpty { return 0 }
            return documents.count + 1
        case 1:
            return appData.count
        default:
            return 0
        }

    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            if (indexPath.row == documents.count) {
                let loadingCell = tableView.dequeueReusableCell(withIdentifier: "LoadingCell", for: indexPath)
                loadingCell.selectionStyle = .none
                return loadingCell
            }

            let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
            let document = documents[indexPath.row]
            cell.textLabel?.text = document.description_fhir
            return cell
        case 1:
            let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
            let document = appData[indexPath.row]
            let text = decodeAppData(from: document)
            cell.textLabel?.text = text
            return cell
        default:
            return UITableViewCell()
        }
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0:
            return "Records"
        case 1:
            return "App Data"
        default:
            return nil
        }
    }

    // MARK: - TableViewDelegate
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        switch indexPath.section {
        case 0:
            if indexPath.row <= documents.count - 1 {
                let document = documents[indexPath.row]
                performSegue(withIdentifier: "openDetail", sender: document)
            }
        default:
            break
        }

    }

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        switch indexPath.section {
        case 0:
            if editingStyle == .delete {
                let document = documents[indexPath.row]
                guard let id = document.id else { return }
                Data4LifeClient.default.deleteFhirStu3Record(withId: id) { result in
                    switch result {
                    case .success:
                        self.documents.remove(at: indexPath.row)
                        self.tableView.reloadData()
                    case .failure(let error):
                        self.presentError(error)
                    }
                }
            }
        default:
            if editingStyle == .delete {
                let appData = self.appData[indexPath.row]
                Data4LifeClient.default.deleteAppDataRecord(withId: appData.id) { result in
                    switch result {
                    case .success:
                        self.appData.remove(at: indexPath.row)
                        self.tableView.reloadData()
                    case .failure(let error):
                        self.presentError(error)
                    }
                }
            }
        }
    }

    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if  let loadingCell = cell as? LoadingCell {
            if shouldLoadNextPage {
                loadingCell.startLoading()
                shouldLoadNextPage = false
                reloadAllData()
            } else {
                loadingCell.stopLoading()
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
            let title = textInputAlert.textFields?.first?.text ?? "Unnamed"
            self?.upload(files: files, withTitle: title)
        })

        textInputAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))

        present(textInputAlert, animated: true, completion: nil)
    }

    func upload(files: [FileData], withTitle title: String) {
        do {
            let attachments = try files.compactMap { file -> Attachment? in
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
                    let current = self?.documents ?? []
                    self?.documents = [record.fhirResource] + current
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
