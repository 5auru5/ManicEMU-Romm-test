//
//  SkinCollectionViewCell.swift
//  ManicEmu
//
//  Created by Daiuno on 2025/2/20.
//  Copyright © 2025 Manic EMU. All rights reserved.
//
// SPDX-License-Identifier: AGPL-3.0-or-later

import UIKit
import ManicEmuCore

class SkinCollectionViewCell: UICollectionViewCell {
    
    class SubscriptView: UIView {
        var titleLabel: UILabel = {
            let view = UILabel()
            view.textColor = Constants.Color.LabelPrimary
            view.font = Constants.Font.caption(weight: .semibold)
            view.layer.shadowColor = Constants.Color.Background.cgColor
            view.layer.shadowOpacity = 0.5
            view.layer.shadowOffset = .init(width: 0, height: 2)
            view.layer.shadowRadius = 2
            return view
        }()
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            backgroundColor = Constants.Color.BackgroundPrimary.withAlphaComponent(0.4)
            addSubview(titleLabel)
            titleLabel.snp.makeConstraints { make in
                make.center.equalToSuperview()
            }
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
    
    var controllerView: ControllerView = {
        let view = ControllerView()
        view.backgroundColor = .black
        view.layerCornerRadius = Constants.Size.CornerRadiusMid
        view.isUserInteractionEnabled = false
        return view
    }()
    
    private var selectImageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .center
        view.layerCornerRadius = Constants.Size.IconSizeMin.height/2
        view.layer.shadowColor = Constants.Color.Shadow.cgColor
        view.layer.shadowOpacity = 0.5
        view.layer.shadowRadius = 2
        view.image = UIImage(symbol: .checkmarkCircleFill, weight: .bold, colors: [Constants.Color.LabelPrimary.forceStyle(.dark), Constants.Color.Main])
        view.alpha = 0
        return view
    }()
    
    private var subscriptView: SubscriptView = {
        let view = SubscriptView()
        view.isHidden = true
        return view
    }()
    
    var previewButton: SymbolButton = {
        let view = SymbolButton(image: R.image.customArrowDownLeftAndArrowUpRight()?.applySymbolConfig(),
                                title: R.string.localizable.skinPreviewTitle(),
                                titleFont: Constants.Font.body(),
                                edgeInsets: UIEdgeInsets(top: Constants.Size.ContentSpaceTiny, left: Constants.Size.ContentSpaceMin, bottom: Constants.Size.ContentSpaceTiny, right: Constants.Size.ContentSpaceMin),
                                titlePosition: .right,
                                enableGlass: true)
        view.enableRoundCorner = true
        return view
    }()
    
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
        addSubview(controllerView)
        controllerView.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
            make.height.equalToSuperview()
        }
        
        addSubview(selectImageView)
        selectImageView.snp.makeConstraints { make in
            make.top.trailing.equalToSuperview().inset(Constants.Size.ContentSpaceTiny)
            make.size.equalTo(Constants.Size.IconSizeMin)
        }
        
        addSubview(subscriptView)
        subscriptView.snp.makeConstraints { make in
            make.leading.bottom.trailing.equalToSuperview()
            make.height.equalTo(Constants.Size.ItemHeightUltraTiny)
        }
        
        addSubview(previewButton)
        previewButton.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            selectImageView.layer.shadowColor = Constants.Color.Shadow.cgColor
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setData(controllerSkin: ControllerSkin, traits: ControllerSkin.Traits, subscriptTitle: String? = nil) {
        let screenAspectRatio: CGFloat
        if traits.orientation == .portrait {
            screenAspectRatio = Constants.Size.WindowSize.aspectRatio
        } else {
            screenAspectRatio = Constants.Size.WindowSize.height/Constants.Size.WindowSize.width
        }
        if let aspectRatio = controllerSkin.aspectRatio(for: traits), abs(aspectRatio.aspectRatio - screenAspectRatio) > 0.1 {
            controllerView.snp.updateConstraints { make in
                make.height.equalToSuperview().offset(-(height - (width/aspectRatio.aspectRatio)))
            }
        } else {
            controllerView.snp.updateConstraints { make in
                make.height.equalToSuperview()
            }
        }
        controllerView.customControllerSkinTraits = traits
        controllerView.controllerSkin = controllerSkin
        if let subscriptTitle {
            subscriptView.isHidden = false
            subscriptView.titleLabel.text = R.string.localizable.designedFor(subscriptTitle)
        } else {
            subscriptView.isHidden = true
        }
    }
}
