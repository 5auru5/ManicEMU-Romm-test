//
//  SettingsMembershipGiftView.swift
//  ManicEmu
//
//  Created by Daiuno on 2025/3/17.
//  Copyright © 2025 Manic EMU. All rights reserved.
//
// SPDX-License-Identifier: AGPL-3.0-or-later

class SettingsMembershipGiftView: UIView {
    
    init(symbol: SFSymbol, title: String) {
        super.init(frame: .zero)
        backgroundColor = Constants.Color.Background.forceStyle(.dark)
        
        let gift = GradientImageView(image: UIImage(symbol: symbol))
        addSubview(gift)
        gift.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(Constants.Size.ContentSpaceMin)
            make.centerY.equalToSuperview()
        }
        
        let label = GradientLabelView()
        label.font = Constants.Font.caption(size: .l, weight: .semibold)
        label.text = title
        label.textColor = Constants.Color.LabelPrimary
        addSubview(label)
        label.snp.makeConstraints { make in
            make.leading.equalTo(gift.snp.trailing).offset(Constants.Size.ContentSpaceUltraTiny)
            make.centerY.equalToSuperview()
            make.trailing.equalToSuperview().offset(-Constants.Size.ContentSpaceMin)
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        layerCornerRadius = height/2
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
