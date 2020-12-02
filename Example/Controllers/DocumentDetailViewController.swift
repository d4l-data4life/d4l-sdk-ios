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

class DocumentDetailViewController: UIViewController {
    @IBOutlet private var collectionView: UICollectionView!
    @IBOutlet private var spinner: UIActivityIndicatorView!
    @IBOutlet private weak var progressView: UIProgressView!

    var document: DocumentReference?
    private var files: [Attachment] = []
    private var cancellableRequest: Cancellable?

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = document?.description_fhir
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
        guard
            let newAttachment = createSampleAttachment(),
            let document = self.document
            else {
                fatalError("Impossible to create an attachment for updating record")
        }
        document.content?.append(DocumentReferenceContent(attachment: newAttachment))

        Data4LifeClient.default.updateFhirStu3Record(document) { [weak self] result in
            switch result {
            case .success:
                self?.loadAttachments()
            case .failure(let error):
                self?.presentError(error)
            }
        }
    }

    func loadAttachments() {
        spinner.isHidden = false
        progressView.isHidden = false
        spinner.startAnimating()
        guard let documentId = document?.id else {
            return
        }

        guard let identifiers = document?.attachments?.compactMap({ $0.id }) else {
            return
        }

        cancellableRequest = Data4LifeClient.default.downloadStu3Attachments(withIds: identifiers, recordId: documentId, onProgressUpdated: { [weak self] progress in
            DispatchQueue.main.async {
                self?.progressView.setProgress(Float(progress.fractionCompleted), animated: true)
            }
        }, completion: { [weak self] result in
            switch result {
            case .success(let attachments):
                self?.files = attachments
            case .failure(let error):
                self?.presentError(error)
            }

            self?.cancellableRequest = nil
            self?.spinner.stopAnimating()
            self?.spinner.isHidden = true
            self?.collectionView.reloadData()
            self?.progressView.isHidden = true
        })
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
        files.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FileCell", for: indexPath) as? FileCell else {
            fatalError("its the only cell")
        }

        let file = files[indexPath.row]
        cell.nameLabel.text = file.title
        guard  let data = file.getData(), let image = UIImage(data: data) else {
            cell.errorLabel.text = "Could not read data"
            return cell
        }

        cell.fileImageView.image = image
        return cell
    }
}

// MARK: - Utils
extension DocumentDetailViewController {
    private func createSampleAttachment() -> Attachment? {
        guard
            let url = Bundle.main.url(forResource: "sample", withExtension: "jpg"),
            let createdSampleData = try? Data(contentsOf: url),
            let contentType = MIMEType.of(createdSampleData)?.rawValue
            else {
                return nil
        }

        return try? Attachment.with(title: "Attachment created after update", creationDate: DateTime.now, contentType: contentType, data: createdSampleData)
    }
}
