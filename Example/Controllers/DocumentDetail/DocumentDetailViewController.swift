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

class DocumentDetailViewController: UIViewController {

    @IBOutlet private var collectionView: UICollectionView!
    @IBOutlet private var spinner: UIActivityIndicatorView!
    @IBOutlet private weak var progressView: UIProgressView!

    var document: DocumentType?
    private var attachments: [AttachmentType] = []
    private var cancellableRequest: Cancellable?

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = document?.fhirDescription
        loadAttachments()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        progressView.setProgress(0.0, animated: false)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        cancellableRequest?.cancel()
    }

    @IBAction func updateRecord(_ sender: Any) {
        guard let document = self.document else {
            fatalError("Impossible to create an attachment for updating record")
        }

        switch document {
        case .stu3(let document):
            let newAttachment = createSampleStu3Attachment()!
            document.content?.append(DocumentReferenceContent(attachment: newAttachment))
            Data4LifeClient.default.updateFhirStu3Record(document) { [weak self] result in
                switch result {
                case .success:
                    self?.loadAttachments()
                case .failure(let error):
                    self?.presentError(error)
                }
            }
        case .r4(let document):
            let newAttachment = createSampleR4Attachment()!
            document.content.append(DocumentReferenceContent(attachment: newAttachment))
            Data4LifeClient.default.updateFhirR4Record(document) { [weak self] result in
                switch result {
                case .success:
                    self?.loadAttachments()
                case .failure(let error):
                    self?.presentError(error)
                }
            }
        }
    }

    func loadAttachments() {
        spinner.isHidden = false
        progressView.isHidden = false
        spinner.startAnimating()

        guard let document = document, let documentId = document.fhirIdentifier else {
            return
        }

        let uiCompletion = {  [weak self] in
            self?.cancellableRequest = nil
            self?.spinner.stopAnimating()
            self?.spinner.isHidden = true
            self?.collectionView.reloadData()
            self?.progressView.isHidden = true
        }
        switch document {
        case .stu3:
            cancellableRequest = Data4LifeClient.default.downloadStu3Attachments(withIds: document.attachmentIdentifiers, recordId: documentId, onProgressUpdated: { [weak self] progress in
                DispatchQueue.main.async {
                    self?.progressView.setProgress(Float(progress.fractionCompleted), animated: true)
                }
            }, completion: { [weak self] result in
                switch result {
                case .success(let attachments):
                    self?.attachments = attachments.map { AttachmentType.stu3($0)}
                case .failure(let error):
                    self?.presentError(error)
                }

                uiCompletion()
            })
        case .r4:
            cancellableRequest = Data4LifeClient.default.downloadR4Attachments(withIds: document.attachmentIdentifiers, recordId: documentId, onProgressUpdated: { [weak self] progress in
                DispatchQueue.main.async {
                    self?.progressView.setProgress(Float(progress.fractionCompleted), animated: true)
                }
            }, completion: { [weak self] result in
                switch result {
                case .success(let attachments):
                    self?.attachments = attachments.map { AttachmentType.r4($0)}
                case .failure(let error):
                    self?.presentError(error)
                }
                uiCompletion()
            })
        }
    }
}

extension DocumentDetailViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {

        let width = floor(view.frame.size.width / 2)
        let height = floor(view.frame.size.height / 4)
        return CGSize(width: width, height: height)
    }

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        attachments.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FileCell", for: indexPath) as? FileCell else {
            fatalError("its the only cell")
        }

        let file = attachments[indexPath.row]
        cell.nameLabel.text = file.title
        guard  let data = file.data, let image = UIImage(data: data) else {
            cell.errorLabel.text = "Could not read data"
            return cell
        }

        cell.fileImageView.image = image
        return cell
    }
}

// MARK: - Utils
extension DocumentDetailViewController {
    private func createSampleStu3Attachment() -> Data4LifeFHIR.Attachment? {
        guard
            let url = Bundle.main.url(forResource: "sample", withExtension: "jpg"),
            let createdSampleData = try? Data(contentsOf: url),
            let contentType = MIMEType.of(createdSampleData)?.rawValue
            else {
                return nil
        }

        return try? Attachment.with(title: "Stu3 Attachment created after update", creationDate: DateTime.now, contentType: contentType, data: createdSampleData)
    }
    private func createSampleR4Attachment() -> ModelsR4.Attachment? {
        guard
            let url = Bundle.main.url(forResource: "sample", withExtension: "jpg"),
            let createdSampleData = try? Data(contentsOf: url),
            let contentType = MIMEType.of(createdSampleData)?.rawValue
        else {
            return nil
        }

        return try? Attachment.with(title: "R4 Attachment created after update", creationDate: Date(), contentType: contentType, data: createdSampleData)
    }
}
