//
//  AddImportServiceCollectionViewCell.swift
//  ManicEmu
//
//  Created by Daiuno on 2025/2/25.
//  Copyright © 2025 Manic EMU. All rights reserved.
//
// SPDX-License-Identifier: AGPL-3.0-or-later

import UIKit

class AddImportServiceCollectionViewCell: UICollectionViewCell {
    private var iconView: ServiceIconView = {
        let view = ServiceIconView(roundCorner: .allCorners)
        return view
    }()
    
    private var titleLabel: UILabel = {
        let view = UILabel()
        view.font = Constants.Font.body(size: .l, weight: .semibold)
        view.textColor = Constants.Color.LabelPrimary
        return view
    }()
    
    var chevronIconView: UIImageView = {
        let view = UIImageView()
        view.image = UIImage(symbol: .chevronRight, font: Constants.Font.caption(size: .l, weight: .bold), color: Constants.Color.BackgroundSecondary)
        if Locale.isRTLLanguage {
            view.transform = CGAffineTransform(scaleX: -1, y: 1)
        }
        return view
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        enableInteractive = true
        delayInteractiveTouchEnd = true
        
        addSubviews([iconView, titleLabel, chevronIconView])
        
        iconView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(Constants.Size.ContentSpaceMid)
            make.size.equalTo(Constants.Size.ItemHeightUltraTiny)
            make.centerY.equalToSuperview()
        }
        
        titleLabel.snp.makeConstraints { make in
            make.centerY.equalTo(iconView)
            make.leading.equalTo(iconView.snp.trailing).offset(Constants.Size.ContentSpaceMin)
        }
        
        chevronIconView.snp.makeConstraints { make in
            make.centerY.equalTo(iconView)
            make.leading.greaterThanOrEqualTo(titleLabel.snp.trailing).offset(Constants.Size.ContentSpaceMin)
            make.trailing.equalToSuperview().offset(-Constants.Size.ContentSpaceMid)
            make.size.equalTo(CGSize(width: 10, height: 14))
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setData(service: ImportService) {
        iconView.imageView.image = service.iconImage
        iconView.backgroundColor = service.iconBackgroundColor
        iconView.borderColor = service.iconBorderColor
        iconView.radius = service.iconCornerRadius
        titleLabel.text = service.title
    }
    
}
