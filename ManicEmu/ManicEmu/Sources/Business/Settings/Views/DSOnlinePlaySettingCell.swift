//
//  DSOnlinePlaySettingCell.swift
//  ManicEmu
//
//  Created by Daiuno on 2025/7/16.
//  Copyright © 2025 Manic EMU. All rights reserved.
//
// SPDX-License-Identifier: AGPL-3.0-or-later

import ManicEmuCore

class DSOnlinePlaySettingCell: UICollectionViewCell {
    
    class ItemView: UIView {
        var titleLabel: UILabel = {
            let view = UILabel()
            view.font = Constants.Font.body(size: .l)
            view.textColor = Constants.Color.LabelPrimary
            view.isUserInteractionEnabled = true
            return view
        }()
        
        var infoButton: SymbolButton = {
            let view = SymbolButton(image: UIImage(symbol: .exclamationmarkCircle, font: Constants.Font.body(weight: .bold)))
            view.enableRoundCorner = true
            view.backgroundColor = Constants.Color.BackgroundPrimary
            return view
        }()
        
        var detailLabel: UILabel = {
            let view = UILabel()
            view.font = Constants.Font.caption(size: .l)
            view.textColor = Constants.Color.LabelSecondary
            view.numberOfLines = 0
            return view
        }()
        
        var selectImageView: UIImageView = {
            let view = UIImageView()
            view.contentMode = .scaleAspectFit
            view.layerCornerRadius = Constants.Size.IconSizeMin.height/2
            view.layer.shadowColor = Constants.Color.Shadow.cgColor
            view.layer.shadowOpacity = 0.5
            view.layer.shadowRadius = 2
            view.image = UIImage(symbol: .checkmarkCircleFill,
                                 size: Constants.Size.IconSizeMin.height,
                                 weight: .bold,
                                 colors: [Constants.Color.LabelPrimary.forceStyle(.dark), Constants.Color.Main])
            view.isHidden = true
            return view
        }()
        
        override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
            super.traitCollectionDidChange(previousTraitCollection)
            if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
                selectImageView.layer.shadowColor = Constants.Color.Shadow.cgColor
            }
        }
        
        init() {
            super.init(frame: .zero)
            layerCornerRadius = Constants.Size.CornerRadiusMid
            backgroundColor = Constants.Color.Background
            enableInteractive = true
            delayInteractiveTouchEnd = true
            
            addSubview(selectImageView)
            selectImageView.snp.makeConstraints { make in
                make.centerY.equalToSuperview()
                make.trailing.equalToSuperview().offset(-Constants.Size.ContentSpaceMid)
                make.size.equalTo(Constants.Size.IconSizeMin)
            }
            
            let titleContainer = UIView()
            addSubview(titleContainer)
            titleContainer.snp.makeConstraints { make in
                make.centerY.equalToSuperview()
                make.leading.equalToSuperview().offset(Constants.Size.ContentSpaceMid)
                make.trailing.equalTo(selectImageView.snp.leading).offset(-Constants.Size.ContentSpaceMid)
            }
            
            titleContainer.addSubview(titleLabel)
            titleLabel.snp.makeConstraints { make in
                make.leading.top.equalToSuperview()
            }
            
            titleContainer.addSubview(infoButton)
            infoButton.snp.makeConstraints { make in
                make.centerY.equalTo(titleLabel)
                make.leading.equalTo(titleLabel.snp.trailing).offset(Constants.Size.ContentSpaceMin)
            }
            
            titleContainer.addSubview(detailLabel)
            detailLabel.snp.makeConstraints { make in
                make.top.equalTo(titleLabel.snp.bottom).offset(Constants.Size.ContentSpaceUltraTiny)
                make.leading.bottom.equalToSuperview()
                make.trailing.lessThanOrEqualToSuperview()
            }
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
    }
    
    private lazy var resetButton: SymbolButton = {
        let view = SymbolButton(image: nil, title: R.string.localizable.dsWfcReset(), titleFont: Constants.Font.body(size: .l, weight: .medium), titleColor: Constants.Color.LabelPrimary.forceStyle(.dark), horizontalContian: true, titlePosition: .right)
        view.enableRoundCorner = true
        view.backgroundColor = Constants.Color.Main
        view.addTapGesture { [weak self] gesture in
            guard let self else { return }
            UIView.makeAlert(title: R.string.localizable.dsWfcReset(), detail: R.string.localizable.dsWfcResetAlert(), confirmTitle: R.string.localizable.confirmTitle(), confirmAction: { [weak self] in
                guard let self else { return }
                WFC.resetWFC()
                UIView.makeToast(message: R.string.localizable.toastSuccess())
            })
        }
        return view
    }()
    
    private var itemViews = [ItemView]()
            
    override init(frame: CGRect) {
        super.init(frame: frame)
        layerCornerRadius = Constants.Size.CornerRadiusMax
        backgroundColor = Constants.Color.BackgroundPrimary
        
        addSubview(resetButton)
        resetButton.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview().inset(Constants.Size.ContentSpaceMid)
            make.height.equalTo(Constants.Size.ItemHeightMid)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setData(wfcs: [WFC], selection: ((Int)->Void)? = nil) {
        itemViews.forEach({ $0.removeFromSuperview() })
        itemViews.removeAll()
        
        for (index, wfc) in wfcs.enumerated() {
            let view = ItemView()
            view.titleLabel.text = wfc.name
            view.titleLabel.addTapGesture { gesture in
                if let url = URL(string: wfc.url) {
                    topViewController()?.present(WebViewController(url: url), animated: true)
                }
            }
            view.detailLabel.text = wfc.dns
            view.infoButton.addTapGesture { gesture in
                if let url = URL(string: wfc.url) {
                    topViewController()?.present(WebViewController(url: url), animated: true)
                }
            }
            view.selectImageView.isHidden = !wfc.isSelect
            view.addTapGesture { gesture in
                selection?(index)
            }
            itemViews.append(view)
        }

        addSubviews(itemViews)
        
        for (index, view) in itemViews.enumerated() {
            view.snp.makeConstraints { make in
                make.leading.trailing.equalToSuperview().inset(Constants.Size.ContentSpaceMid)
                make.height.equalTo(Constants.Size.ItemHeightMax)
                if index == 0 {
                    make.top.equalToSuperview().offset(Constants.Size.ContentSpaceMid)
                } else {
                    make.top.equalTo(itemViews[index-1].snp.bottom).offset(Constants.Size.ContentSpaceMid)
                }
            }
        }
    }
    
    static func CellHeight(wfcCount: Int) -> Double {
        return Double(wfcCount) * Constants.Size.ItemHeightMax + Constants.Size.ItemHeightMid + Double(wfcCount + 2) * Constants.Size.ContentSpaceMid
    }
}
