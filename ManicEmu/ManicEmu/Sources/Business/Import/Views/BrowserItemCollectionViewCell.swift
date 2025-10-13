//
//  BrowserItemCollectionViewCell.swift
//  ManicEmu
//
//  Created by Max on 2025/1/22.
//  Copyright © 2025 Manic EMU. All rights reserved.
//
// SPDX-License-Identifier: AGPL-3.0-or-later

import UIKit

class BrowserItemCollectionViewCell: UICollectionViewCell {
    private var checkboxImageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .center
        view.image = UIImage(symbol: .circle,
                             size: Constants.Size.IconSizeTiny.height,
                             color: Constants.Color.LabelSecondary)
        return view
    }()
    
    private var iconImageView: UIImageView = {
        let view = UIImageView(image: R.image.file_browser_folder())
        view.contentMode = .center
        return view
    }()
    
    private var titleLabel: UILabel = {
        let view = UILabel()
        view.font = Constants.Font.body()
        view.textColor = Constants.Color.LabelPrimary
        view.lineBreakMode = .byTruncatingMiddle
        return view
    }()
    
    private lazy var detailLabel: UILabel = {
        let view = UILabel()
        view.font = Constants.Font.caption()
        view.textColor = Constants.Color.LabelSecondary
        return view
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        selectedBackgroundView = UIView()
        selectedBackgroundView?.backgroundColor = .clear
        
        addSubviews([checkboxImageView, iconImageView])
        checkboxImageView.snp.makeConstraints { make in
            make.size.equalTo(Constants.Size.IconSizeTiny)
            make.centerY.equalToSuperview()
            make.leading.equalToSuperview().offset(Constants.Size.ContentSpaceMid)
        }
        
        iconImageView.snp.makeConstraints { make in
            make.size.equalTo(44)
            make.centerY.equalToSuperview()
            make.leading.equalTo(checkboxImageView.snp.trailing).offset(Constants.Size.ContentSpaceTiny)
        }
        
        let labelContainer = UIView()
        addSubview(labelContainer)
        labelContainer.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.leading.equalTo(iconImageView.snp.trailing).offset(Constants.Size.ContentSpaceTiny)
            make.trailing.equalToSuperview().offset(-Constants.Size.ContentSpaceMid)
        }
        labelContainer.addSubviews([titleLabel, detailLabel])
        titleLabel.snp.makeConstraints { make in
            make.leading.top.trailing.equalToSuperview()
        }
        
        detailLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(Constants.Size.ContentSpaceUltraTiny)
            make.leading.bottom.trailing.equalToSuperview()
        }
        
        let seperatorLine = UIView()
        seperatorLine.backgroundColor = .systemGray4
        addSubview(seperatorLine)
        seperatorLine.snp.makeConstraints { make in
            make.bottom.equalToSuperview()
            make.height.equalTo(0.5)
            make.leading.trailing.equalTo(labelContainer)
        }
    }
    
    override var isSelected: Bool {
        didSet {
            if isSelected {
                checkboxImageView.image = UIImage(symbol: .checkmarkCircleFill,
                                                  size: Constants.Size.IconSizeTiny.height,
                                                  colors: [Constants.Color.LabelPrimary.forceStyle(.dark), UIWindow.applicationWindow?.tintColor ?? Constants.Color.Main])
                selectedBackgroundView?.backgroundColor = Constants.Color.BackgroundPrimary
            } else {
                checkboxImageView.image = UIImage(symbol: .circle,
                                                  size: Constants.Size.IconSizeTiny.height,
                                                  color: Constants.Color.LabelSecondary)
                selectedBackgroundView?.backgroundColor = .clear
            }
        }
    }
    
    func setData(selectable: Bool, isFolder: Bool, title: String, detail: String) {
        if selectable {
            titleLabel.textColor = Constants.Color.LabelPrimary
            detailLabel.textColor = Constants.Color.LabelSecondary
            iconImageView.image = (isFolder ? R.image.file_browser_folder() : R.image.file_browser_document())
            iconImageView.tintColor = nil
        } else {
            titleLabel.textColor = Constants.Color.LabelSecondary
            detailLabel.textColor = Constants.Color.LabelTertiary
            iconImageView.image = (isFolder ? R.image.file_browser_folder() : R.image.file_browser_document())?.withRenderingMode(.alwaysTemplate)
            iconImageView.tintColor = Constants.Color.LabelTertiary
        }
        if isFolder {
            checkboxImageView.alpha = 0
        } else {
            checkboxImageView.alpha = selectable ? 1 : 0
        }
        titleLabel.text = title
        detailLabel.text = detail
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
