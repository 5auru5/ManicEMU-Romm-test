//
//  ImportFileCollectionViewCell.swift
//  ManicEmu
//
//  Created by Daiuno on 2025/2/23.
//  Copyright © 2025 Manic EMU. All rights reserved.
//
// SPDX-License-Identifier: AGPL-3.0-or-later

import UIKit

class ImportFileCollectionViewCell: UICollectionViewCell {
    private var iconView: ServiceIconView = {
        let view = ServiceIconView(roundCorner: .allCorners)
        return view
    }()
    
    private var titleLabel: UILabel = {
        let view = UILabel()
        view.numberOfLines = 0
        return view
    }()
    
    var infoContainerView: UIView = {
        let view = UIView()
        view.enableInteractive = true
        view.delayInteractiveTouchEnd = true
        view.backgroundColor = Constants.Color.BackgroundPrimary
        view.layerCornerRadius = Constants.Size.CornerRadiusMax
        return view
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        let topHintView = UIView()
        addSubview(topHintView)
        topHintView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().offset(Constants.Size.ContentSpaceMax)
            make.leading.greaterThanOrEqualToSuperview().offset(Constants.Size.ContentSpaceMax)
            make.trailing.lessThanOrEqualToSuperview().offset(-Constants.Size.ContentSpaceMax)
        }
        
        let hintIcon = UIImageView(image: UIImage(symbol: .moonStarsFill))
        topHintView.addSubview(hintIcon)
        hintIcon.snp.makeConstraints { make in
            make.leading.top.bottom.equalToSuperview()
            make.size.equalTo(Constants.Size.IconSizeMin)
        }
        
        let hintLabel = UILabel()
        hintLabel.textColor = Constants.Color.LabelPrimary
        hintLabel.font = Constants.Font.body()
        hintLabel.text = R.string.localizable.importTopHintTitle()
        hintLabel.numberOfLines = 0
        topHintView.addSubview(hintLabel)
        hintLabel.snp.makeConstraints { make in
            make.leading.equalTo(hintIcon.snp.trailing).offset(Constants.Size.ContentSpaceTiny)
            make.trailing.equalToSuperview().offset(-Constants.Size.ContentSpaceUltraTiny)
            make.centerY.equalToSuperview()
        }

        addSubview(infoContainerView)
        infoContainerView.snp.makeConstraints { make in
            make.leading.bottom.trailing.equalToSuperview()
            make.top.equalTo(topHintView.snp.bottom).offset(Constants.Size.ContentSpaceMax)
            make.height.equalTo(100)
        }
        
        infoContainerView.addSubviews([iconView, titleLabel])
        iconView.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(Constants.Size.ContentSpaceMax)
            make.centerY.equalToSuperview()
            make.size.equalTo(48)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.leading.equalTo(iconView.snp.trailing).offset(Constants.Size.ContentSpaceMin)
            make.trailing.equalToSuperview().inset(Constants.Size.ContentSpaceMax)
            make.centerY.equalToSuperview()
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //TODO: 需要处理图片的尺寸
    func setData(service: ImportService) {
        
        iconView.imageView.image = service.iconImage
        iconView.backgroundColor = service.iconBackgroundColor
        iconView.borderColor = service.iconBorderColor
        iconView.radius = service.iconCornerRadius
        titleLabel.text = service.title
        
        var matt = NSMutableAttributedString(string: service.title, attributes: [.font: Constants.Font.title(size: .s, weight: .semibold), .foregroundColor: Constants.Color.LabelPrimary])
        if let detail = service.detail {
            matt.append(NSAttributedString(string: "\n" + detail, attributes: [.font: Constants.Font.body(), .foregroundColor: Constants.Color.LabelSecondary]))
            let style = NSMutableParagraphStyle()
            style.lineSpacing = Constants.Size.ContentSpaceUltraTiny/2
            matt = matt.applying(attributes: [.paragraphStyle: style]) as! NSMutableAttributedString
        }
        let style = NSMutableParagraphStyle()
        style.lineBreakMode = .byTruncatingTail
        matt = matt.applying(attributes: [.paragraphStyle: style]) as! NSMutableAttributedString
        titleLabel.attributedText = matt
    }
    
}
