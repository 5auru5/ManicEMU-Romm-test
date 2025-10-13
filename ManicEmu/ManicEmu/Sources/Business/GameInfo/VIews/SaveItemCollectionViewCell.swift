//
//  SaveItemCollectionViewCell.swift
//  ManicEmu
//
//  Created by Daiuno on 2025/2/14.
//  Copyright © 2025 Manic EMU. All rights reserved.
//
// SPDX-License-Identifier: AGPL-3.0-or-later

import UIKit
import SwipeCellKit

class SaveItemCollectionViewCell: SwipeCollectionViewCell {
    private var iconView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFill
        view.layerCornerRadius = Constants.Size.CornerRadiusMin
        return view
    }()
    
    private var titleLabel: UILabel = {
        let view = UILabel()
        view.font = Constants.Font.body(size: .l)
        view.textColor = Constants.Color.LabelPrimary
        return view
    }()
    
    private var deviceContainer = UIView()
    
    private var deviceInfo: UILabel = {
        let view = UILabel()
        view.font = Constants.Font.caption(size: .l)
        view.textColor = Constants.Color.Yellow
        return view
    }()
    
    private var deviceWarning: UIImageView = {
        let view = UIImageView(image: UIImage(symbol: .exclamationmarkCircleFill, font: Constants.Font.caption(size: .l), color: Constants.Color.Yellow))
        return view
    }()
    
    private var subTitleLabel: UILabel = {
        let view = UILabel()
        view.font = Constants.Font.caption(size: .l)
        view.textColor = Constants.Color.LabelSecondary
        return view
    }()
    
    var continueButton: SymbolButton = {
        let view = SymbolButton(image: UIImage(symbol: .playFill, size: 10), 
                                title: R.string.localizable.gameSaveContinue(),
                                titleFont: Constants.Font.caption(size: .l, weight: .medium),
                                edgeInsets: UIEdgeInsets(top: 0, left: Constants.Size.ContentSpaceMin, bottom: 0, right: Constants.Size.ContentSpaceMin),
                                titlePosition: .left,
                                imageAndTitlePadding: Constants.Size.ContentSpaceUltraTiny,
                                enableGlass: true)
        view.layerCornerRadius = 15
        return view
    }()
    
    private var selectImageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFit
        view.layerCornerRadius = Constants.Size.IconSizeMin.height/2
        view.layer.shadowColor = Constants.Color.Shadow.cgColor
        view.layer.shadowOpacity = 0.5
        view.layer.shadowRadius = 2
        view.image = UIImage(symbol: .circle, size: Constants.Size.IconSizeMin.height, color: Constants.Color.LabelSecondary)
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
            if newValue {
                self.selectImageView.image = UIImage(symbol: .checkmarkCircleFill,
                                                     size: Constants.Size.IconSizeMin.height,
                                                     weight: .bold,
                                                     colors: [Constants.Color.LabelPrimary, Constants.Color.Main])
            } else {
                self.selectImageView.image = UIImage(symbol: .circle,
                                                     size: Constants.Size.IconSizeMin.height,
                                                     color: Constants.Color.LabelPrimary.forceStyle(.dark))
            }
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = Constants.Color.Background
        
        contentView.addSubview(selectImageView)
        selectImageView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(Constants.Size.ContentSpaceUltraTiny)
            make.size.equalTo(Constants.Size.IconSizeMin)
            make.centerY.equalToSuperview()
        }

        contentView.addSubview(iconView)
        iconView.snp.makeConstraints { make in
            make.leading.equalTo(selectImageView.snp.trailing).offset(Constants.Size.ContentSpaceMin)
            make.centerY.equalToSuperview()
            make.size.equalTo(50)
        }
        
        let titleContainerView = UIView()
        contentView.addSubview(titleContainerView)
        titleContainerView.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.leading.equalTo(iconView.snp.trailing).offset(Constants.Size.ContentSpaceMin)
        }
        
        titleContainerView.addSubviews([titleLabel, deviceContainer, subTitleLabel])
        titleLabel.snp.makeConstraints { make in
            make.leading.top.equalToSuperview()
        }
        
        deviceContainer.snp.makeConstraints { make in
            make.leading.equalTo(titleLabel.snp.trailing).offset(Constants.Size.ContentSpaceUltraTiny)
            make.trailing.lessThanOrEqualToSuperview()
            make.centerY.equalTo(titleLabel)
        }
        
        deviceContainer.addSubviews([deviceInfo, deviceWarning])
        deviceInfo.snp.makeConstraints { make in
            make.leading.top.bottom.equalToSuperview()
        }
        
        deviceWarning.snp.makeConstraints { make in
            make.leading.equalTo(deviceInfo.snp.trailing).offset(Constants.Size.ContentSpaceUltraTiny)
            make.centerY.equalTo(deviceInfo)
            make.trailing.equalToSuperview()
        }
        
        subTitleLabel.snp.makeConstraints { make in
            make.leading.bottom.trailing.equalToSuperview()
            make.top.equalTo(titleLabel.snp.bottom).offset(Constants.Size.ContentSpaceUltraTiny)
        }
        
        contentView.addSubview(continueButton)
        continueButton.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.leading.greaterThanOrEqualTo(titleContainerView.snp.trailing).offset(Constants.Size.ContentSpaceMin)
            make.trailing.equalToSuperview().offset(-Constants.Size.ContentSpaceUltraTiny)
            make.height.equalTo(Constants.Size.ItemHeightUltraTiny)
            make.width.greaterThanOrEqualTo(64)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //TODO: 需要处理图片的尺寸
    func setData(item: GameSaveState, index: Int) {
        iconView.image = .tryDataImageOrPlaceholder(tryData: item.stateCover?.storedData(), preferenceSize: iconView.size)
        titleLabel.text = R.string.localizable.gameSaveTitle(index)
        subTitleLabel.text = item.date.dateTimeString(ofStyle: .short)
        if item.isCompatible {
            deviceInfo.text = nil
            deviceContainer.isHidden = true
            deviceContainer.addTapGesture { gesture in }
        } else {
            let info = item.gameSaveStateDeviceInfo
            deviceInfo.text = info
            deviceContainer.isHidden = false
            deviceContainer.addTapGesture { gesture in
                UIView.makeAlert(title: R.string.localizable.gameSaveUnCompatibleTitle(),
                                 detail: R.string.localizable.gameSaveUnCompatibleDetail(info, item.currentDeviceInfo),
                                 cancelTitle: R.string.localizable.confirmTitle())
            }
        }
    }
}
