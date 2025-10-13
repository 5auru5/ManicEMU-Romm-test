//
//  AddSkinCollectionViewCell.swift
//  ManicEmu
//
//  Created by Daiuno on 2025/2/20.
//  Copyright © 2025 Manic EMU. All rights reserved.
//
// SPDX-License-Identifier: AGPL-3.0-or-later

import UIKit

class AddSkinCollectionViewCell: UICollectionViewCell {
    var iconView: SymbolButton = {
        let view = SymbolButton(image: UIImage(symbol: .plusCircleFill, color: Constants.Color.LabelSecondary),
                                title: R.string.localizable.skinAddTitle(),
                                titleFont: Constants.Font.caption(size: .l),
                                titleColor: Constants.Color.LabelSecondary,
                                edgeInsets: .zero,
                                titlePosition: .down,
                                imageAndTitlePadding: Constants.Size.ContentSpaceTiny)
        view.layerCornerRadius = 0
        view.backgroundColor = .clear
        view.enableInteractive = false
        view.delayInteractiveTouchEnd = true
        return view
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        enableInteractive = true
        delayInteractiveTouchEnd = true
        layerCornerRadius = Constants.Size.CornerRadiusMid
        backgroundColor = Constants.Color.Background
        addSubview(iconView)
        iconView.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
