//
//  FilterNameOnlyCollectionCell.swift
//  ManicEmu
//
//  Created by Daiuno on 2025/5/24.
//  Copyright © 2025 Manic EMU. All rights reserved.
//
// SPDX-License-Identifier: AGPL-3.0-or-later

class FilterNameOnlyCollectionCell: UICollectionViewCell {
    private var titleLabel: UILabel = {
        let view = UILabel()
        view.font = Constants.Font.body(size: .l)
        view.textColor = Constants.Color.LabelPrimary
        view.textAlignment = .center
        return view
    }()
    
    private var selectImageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .center
        view.layerCornerRadius = Constants.Size.CornerRadiusMin
        view.layer.shadowColor = Constants.Color.Shadow.cgColor
        view.layer.shadowOpacity = 0.5
        view.layer.shadowRadius = 2
        view.image = UIImage(symbol: .checkmarkCircleFill, weight: .bold, colors: [Constants.Color.LabelPrimary.forceStyle(.dark), Constants.Color.Main])
        view.alpha = 0
        return view
    }()
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            selectImageView.layer.shadowColor = Constants.Color.Shadow.cgColor
        }
    }
    
    override var isSelected: Bool {
        willSet {
            UIView.springAnimate {
                self.selectImageView.alpha = newValue ? 1 : 0
            }
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        enableInteractive = true
        delayInteractiveTouchEnd = true
        layerCornerRadius = Constants.Size.CornerRadiusMid
        backgroundColor = Constants.Color.Background
        
        addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(Constants.Size.ContentSpaceMid)
            make.centerY.equalToSuperview()
        }
        
        addSubview(selectImageView)
        selectImageView.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(Constants.Size.ContentSpaceMid)
            make.size.equalTo(Constants.Size.IconSizeMin)
            make.centerY.equalToSuperview()
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setData(title: String) {
        titleLabel.text = title
    }
}
