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

protocol FilePickerDelegate: AnyObject {
    func filePickerDidSelect(files: [FileData])
}

class FilePickerViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    @IBOutlet private var collectionView: UICollectionView!
    @IBOutlet private var doneButton: UIBarButtonItem!
    weak var delegate: FilePickerDelegate?
    var files: [FileData] = []

    @IBAction func openImagePickerButtonTapped(_ sender: UIButton) {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = .photoLibrary
        imagePicker.allowsEditing = false
        present(imagePicker, animated: true)
    }

    @IBAction func doneButtonTouched(_ sender: UIButton) {
        self.navigationController?.popViewController(animated: true)
        delegate?.filePickerDidSelect(files: files)
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true) { [weak self] in
            guard let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage else {
                return
            }
            self?.pickFileName(for: image)
        }
    }

    func pickFileName(for image: UIImage) {
        let filenameAlertController = UIAlertController(title: "Adding a new file",
                                               message: "Please choose name",
                                               preferredStyle: .alert)

        filenameAlertController.addTextField { (textField) in textField.placeholder = "Filename" }
        filenameAlertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        filenameAlertController.addAction(UIAlertAction(title: "OK", style: .default, handler: { [weak self] _ in
            let filename = filenameAlertController.textFields?.first?.text ?? UUID().uuidString
            self?.files.append(FileData(name: filename, image: image))
            self?.collectionView.reloadData()
            self?.doneButton.isEnabled = true
        }))

        present(filenameAlertController, animated: true, completion: nil)
    }
}

extension FilePickerViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
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
        return files.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FileCell", for: indexPath) as? FileCell else {
            fatalError("It is the only cell")
        }
        let file = files[indexPath.row]
        cell.nameLabel.text = file.name
        cell.fileImageView.image = file.image
        return cell
    }
}
