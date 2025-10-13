//
//  DesktopIconCollectionViewCell.swift
//  ManicEmu
//
//  Created by Daiuno on 2025/5/3.
//  Copyright © 2025 Manic EMU. All rights reserved.
//
// SPDX-License-Identifier: AGPL-3.0-or-later

class DesktopIconCollectionViewCell: UICollectionViewCell {
    
    class IconView: UIView {
        var imageView: UIImageView = {
            let view = UIImageView()
            view.contentMode = .scaleAspectFill
            return view
        }()
        
        var selectImageView: UIImageView = {
            let view = UIImageView()
            view.contentMode = .center
            view.layerCornerRadius = Constants.Size.IconSizeMin.height/2
            view.layer.shadowColor = Constants.Color.Shadow.cgColor
            view.layer.shadowOpacity = 0.5
            view.layer.shadowRadius = 2
            view.image = UIImage(symbol: .checkmarkCircleFill, weight: .bold, colors: [Constants.Color.LabelPrimary.forceStyle(.dark), Constants.Color.Main])
            view.isHidden = true
            return view
        }()
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            
            enableInteractive = true
            delayInteractiveTouchEnd = true
            
            addSubview(imageView)
            imageView.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
            
            addSubview(selectImageView)
            selectImageView.snp.makeConstraints { make in
                make.size.equalTo(Constants.Size.IconSizeMin)
                make.trailing.equalToSuperview().offset(Constants.Size.ContentSpaceTiny)
                make.top.equalToSuperview().offset(-Constants.Size.ContentSpaceTiny)
            }
        }
        
        override func layoutSubviews() {
            super.layoutSubviews()
            imageView.image = imageView.image?.withRoundedCorners(radius: Constants.Size.AppleIconCornerRadius(height: height)) 
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
            super.traitCollectionDidChange(previousTraitCollection)
            if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
                selectImageView.layer.shadowColor = Constants.Color.Shadow.cgColor
            }
        }
    }
    
    
    private var scrollView: UIScrollView = {
        let view = UIScrollView()
        view.backgroundColor = Constants.Color.BackgroundPrimary
        view.layerCornerRadius = Constants.Size.CornerRadiusMax
        view.showsVerticalScrollIndicator = false
        view.showsHorizontalScrollIndicator = false
        view.alwaysBounceHorizontal = true
        view.alwaysBounceVertical = false
        return view
    }()
    
    private var descLabel: UILabel = {
        let label = UILabel()
        label.font = Constants.Font.caption()
        label.textColor = Constants.Color.LabelSecondary
        label.text = R.string.localizable.themeDesktopIconDetail()
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        addSubview(scrollView)
        scrollView.snp.makeConstraints { make in
            make.leading.trailing.top.equalToSuperview()
            make.height.equalTo(100)
        }
        
        let icons = ["AppIcon", "AppIcon_Dark", "AppIcon_Retro", "AppIcon_Color"]
        let theme = Theme.defalut
        for (index, icon) in icons.enumerated() {
            let iconView = IconView()
            iconView.imageView.image = UIImage(named: icon.lowercased())?.scaled(toSize: Constants.Size.IconSizeHuge)
            if theme.icon == icon {
                iconView.selectImageView.isHidden = false
            } else {
                iconView.selectImageView.isHidden = true
            }
            scrollView.addSubview(iconView)
            iconView.snp.makeConstraints { make in
                make.centerY.equalToSuperview()
                make.top.bottom.equalToSuperview().inset(Constants.Size.ContentSpaceMid)
                make.height.equalTo(iconView.snp.width)
                if index == 0 {
                    make.leading.equalToSuperview().offset(Constants.Size.ContentSpaceMid)
                } else {
                    make.leading.equalTo(scrollView.subviews[index-1].snp.trailing).offset(Constants.Size.ContentSpaceMid)
                }
                if index == icons.count - 1 {
                    make.trailing.equalToSuperview().offset(-Constants.Size.ContentSpaceMid)
                }
            }
            
            iconView.addTapGesture { [weak self] gesture in
                guard let self = self else { return }
                if index < self.scrollView.subviews.count, let view = self.scrollView.subviews[index] as? IconView {
                    if !view.selectImageView.isHidden {
                        //当前已经选中
                        return
                    }
                }
                
                if let views = self.scrollView.subviews as? [IconView] {
                    for (innerIndex, view) in views.enumerated() {
                        if innerIndex == index {
                            view.selectImageView.isHidden = false
                            Theme.change { realm in
                                Theme.defalut.icon = icons[index]
                            }
                        } else {
                            view.selectImageView.isHidden = true
                        }
                    }
                }
            }
        }
        
        addSubview(descLabel)
        descLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(scrollView.snp.bottom).offset(Constants.Size.ContentSpaceTiny)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
