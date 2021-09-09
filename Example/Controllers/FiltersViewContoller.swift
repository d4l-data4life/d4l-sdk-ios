//  Copyright (c) 2021 D4L data4life gGmbH
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

class FiltersViewController: UIViewController {
    @IBOutlet var tableView: UITableView!
    @IBOutlet var clearButton: UIBarButtonItem!
    var callback: (([Int: Date]) -> Void)?
    var datePickers: [Int: Bool] = [:] {
        didSet {
            let expandedPickers = datePickers.filter { return $0.value }
            navigationItem.backBarButtonItem?.isEnabled = expandedPickers.isEmpty
        }
    }
    var dates:[Int: Date] = [:] {
        didSet {
            clearButton.isEnabled = !self.dates.isEmpty
        }
    }

    var formatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tableView.tableFooterView = UIView()
        datePickers[0] = false
        datePickers[1] = false
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if let callback = callback {
            callback(dates)
        }
    }

    @IBAction func clearButtonTouched(_ sender: UIButton) {
        dates = [:]
        tableView.reloadData()
        sender.isEnabled = false
    }
}

extension FiltersViewController: UITableViewDelegate, UITableViewDataSource {
    // MARK: - TableViewDataSource
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.row == 1 {
            return datePickers[indexPath.section]! ? 240 : 0
        }

        return 40
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 2
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row == 1, let pickerCell = tableView.dequeueReusableCell(withIdentifier: "DatePickerCell", for: indexPath) as? DatePickerCell {
            pickerCell.datePicker.maximumDate = Date()

            if let pickedDate = dates[indexPath.section] {
                pickerCell.datePicker.date = pickedDate
            }

            if indexPath.section == 1, let fromDate = dates[0] {
                pickerCell.datePicker.minimumDate = fromDate
            }

            return pickerCell
        } else if let cell = tableView.dequeueReusableCell(withIdentifier: "DateCell", for: indexPath) as? DateCell {
            let title = indexPath.section == 0 ? "From" : "To"

            cell.titleLabel.text = title
            if let date = dates[indexPath.section] {
                cell.dateLabel.text = formatter.string(from: date)
            } else {
                cell.dateLabel.text = "None"
            }

            return cell
        }

        return UITableViewCell()
    }

    // MARK: - TableViewDelegate
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        datePickers[indexPath.section] = !(datePickers[indexPath.section]!)

        if datePickers[indexPath.section] == false {
            let pickerCell = tableView.cellForRow(at: IndexPath(row: 1, section: indexPath.section)) as? DatePickerCell
            let selectedDate = pickerCell?.datePicker.date
            let dateCell = tableView.cellForRow(at: indexPath) as? DateCell
            dateCell?.dateLabel.text = formatter.string(from: selectedDate ?? Date())
            dates[indexPath.section] = selectedDate
        }

        self.tableView.reloadSections([indexPath.section], with: .automatic)
    }
}