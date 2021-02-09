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

    @IBOutlet private var leftBarButton: UIBarButtonItem!
    @IBOutlet private var searchButton: UIBarButtonItem!
    @IBOutlet private var headerView: UIView!
    @IBOutlet private var footerView: UIView!
    @IBOutlet private var countsLabel: UILabel!

    private var documentVersionToBeAdded: DocumentVersion?

    private lazy var interactor = DocumentListInteractor(view: self)

    // MARK: - View life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        configureSubviews()
        interactor.viewDidLoad()
    }

    private func configureSubviews() {
        tableView.tableFooterView = footerView
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 44
        tableView.sectionHeaderHeight = UITableView.automaticDimension
        tableView.estimatedSectionHeaderHeight = 44
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        interactor.viewDidAppear()
    }

    // MARK: - IBActions
    @IBAction func leftBarButtonTouched(_ sender: UIButton) {
        if leftBarButton.title == "Log out" {
            interactor.didTapLogout()
        } else {
            interactor.didTapLogin()
        }
    }

    @IBAction func refresh(_ sender: UIRefreshControl) {
        interactor.didPullToRefresh()
    }

    // MARK: Helpers
    func updateUI(state userSessionActive: Bool) {
        leftBarButton.title = userSessionActive ? "Log out" : "Login"
        searchButton.isEnabled = userSessionActive
        tableView.tableHeaderView = userSessionActive ? nil : headerView
        tableView.tableFooterView = userSessionActive ? footerView : nil
    }

    func updateTableView() {
        countsLabel.text = interactor.countDescription
        refreshControl?.endRefreshing()
        tableView.reloadData()
    }

    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let detailVC = segue.destination as? DocumentDetailViewController, let documentType = sender as? DocumentType {
            detailVC.document = documentType
        } else if let filePickerVC = segue.destination as? FilePickerViewController {
            filePickerVC.delegate = self
        } else if let filtersVC = segue.destination as? FiltersViewController {
            filtersVC.callback = { [weak self] dates in
                self?.interactor.didSelectDates(dates)
            }
            if let dates = interactor.dates {
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
            self?.interactor.didPickFiles(files, titled: title, version: documentVersion)
        })

        textInputAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(textInputAlert, animated: true, completion: nil)
    }
}

extension DocumentListTableViewController {
    // MARK: - TableViewDataSource
    override func numberOfSections(in tableView: UITableView) -> Int {
        return interactor.schema.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        interactor.schema[section].cellCount
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        switch interactor.schema[indexPath.section] {
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
            // swiftlint:disable force_cast
            let loadingCell = tableView.dequeueReusableCell(withIdentifier: "LoadingCell", for: indexPath) as! LoadingCell
            loadingCell.selectionStyle = .none
            loadingCell.startLoading()
            return loadingCell
        }
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let title: String
        let onAdd: (() -> Void)?
        switch interactor.schema[section] {
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
            onAdd = { [unowned self] in self.interactor.didTapAddAppData() }
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
        switch interactor.schema[indexPath.section] {
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

        interactor.didDeleteCell(at: indexPath)
    }

    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard case .loading = interactor.schema[indexPath.section] else { return }
        interactor.willDisplayLoadingCell()
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
