//
//  DocumentSectionHeader.swift
//  Example
//
//  Created by Alessio Borraccino on 07.12.20.
//  Copyright © 2020 HPS Gesundheitscloud gGmbH. All rights reserved.
//

import Foundation
import UIKit

final class DocumentSectionHeader: UITableViewHeaderFooterView {

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = .black
        return label
    }()

    private lazy var button: UIButton = {
        let button = UIButton(type: .contactAdd)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private lazy var stackView = UIStackView(arrangedSubviews: [titleLabel, button])

    private var onAdd: (() -> Void)?

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        addSubviews()
        configureBehavior()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        addSubviews()
        configureBehavior()
    }

    private func addSubviews() {
        stackView.axis = .horizontal
        stackView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            stackView.topAnchor.constraint(equalTo: contentView.topAnchor),
            stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            stackView.heightAnchor.constraint(greaterThanOrEqualToConstant: 44),
            button.widthAnchor.constraint(equalToConstant: 66)
        ])
    }

    private func configureBehavior() {
        let action = UIAction(handler: { [unowned self] _ in
            self.onAdd?()
        })
        button.addAction(action, for: .touchUpInside)
    }

    func configure(title: String, onAdd: (() -> Void)?) {
        titleLabel.text = title
        if let onAdd = onAdd {
            self.onAdd = onAdd
            button.isHidden = false
        } else {
            button.isHidden = true 
        }
    }

    override var intrinsicContentSize: CGSize {
        CGSize(width: super.intrinsicContentSize.width, height: max(titleLabel.intrinsicContentSize.height, 44))
    }
}
