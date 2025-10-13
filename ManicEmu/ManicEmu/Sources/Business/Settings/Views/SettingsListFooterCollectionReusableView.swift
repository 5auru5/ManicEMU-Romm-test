//
//  SettingsListFooterCollectionReusableView.swift
//  ManicEmu
//
//  Created by Daiuno on 2025/2/28.
//  Copyright © 2025 Manic EMU. All rights reserved.
//
// SPDX-License-Identifier: AGPL-3.0-or-later

import StoreKit

class SettingsListFooterCollectionReusableView: UICollectionReusableView {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        #if SIDE_LOAD
        //donate
        let donateContainerView = UIView()
        donateContainerView.addTapGesture { gesture in
            UIApplication.shared.open(Constants.URLs.Donate)
        }
        
        donateContainerView.backgroundColor = Constants.Color.BackgroundPrimary
        donateContainerView.layerCornerRadius = Constants.Size.ContentSpaceMax
        addSubview(donateContainerView)
        donateContainerView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(Constants.Size.ContentSpaceMin)
            make.leading.trailing.equalToSuperview().inset(Constants.Size.ContentSpaceMid)
            make.height.equalTo(Constants.Size.ItemHeightMax)
        }
        
        let donateIconView: UIImageView = {
            let view = UIImageView()
            view.contentMode = .center
            view.layerCornerRadius = 6
            view.backgroundColor = Constants.Color.Red
            view.image = UIImage(symbol: .boltHeartFill, font: Constants.Font.body(size: .s, weight: .medium), color: Constants.Color.LabelPrimary.forceStyle(.dark))
            return view
        }()
        
        let donateTitleLabel: UILabel = {
            let view = UILabel()
            view.numberOfLines = 3
            var matt = NSMutableAttributedString(string: R.string.localizable.donateTitle(), attributes: [.font: Constants.Font.body(size: .l, weight: .semibold), .foregroundColor: Constants.Color.LabelPrimary])
            matt.append(NSAttributedString(string: "\n" + R.string.localizable.donateDesc(), attributes: [.font: Constants.Font.caption(size: .l), .foregroundColor: Constants.Color.LabelSecondary]))
            let style1 = NSMutableParagraphStyle()
            style1.lineSpacing = Constants.Size.ContentSpaceUltraTiny/2
            matt = matt.applying(attributes: [.paragraphStyle: style1]) as! NSMutableAttributedString
            let style2 = NSMutableParagraphStyle()
            style2.lineBreakMode = .byTruncatingTail
            matt = matt.applying(attributes: [.paragraphStyle: style2]) as! NSMutableAttributedString
            view.attributedText = matt
            return view
        }()
        
        let donateChevronIconView: UIImageView = {
            let view = UIImageView(image: UIImage(symbol: .chevronRight, font: Constants.Font.caption(size: .l, weight: .bold), color: Constants.Color.BackgroundSecondary))
            view.contentMode = .center
            return view
        }()
        
        donateContainerView.addSubview(donateIconView)
        donateIconView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(Constants.Size.ContentSpaceMid)
            make.size.equalTo(Constants.Size.IconSizeMin)
            make.centerY.equalToSuperview()
        }
        
        donateContainerView.addSubview(donateTitleLabel)
        donateTitleLabel.snp.makeConstraints { make in
            make.centerY.equalTo(donateIconView)
            make.leading.equalTo(donateIconView.snp.trailing).offset(Constants.Size.ContentSpaceMin)
            make.trailing.equalToSuperview().offset(-46-Constants.Size.ContentSpaceMid-Constants.Size.ContentSpaceMin)
        }
        
        donateContainerView.addSubview(donateChevronIconView)
        donateChevronIconView.snp.makeConstraints { make in
            make.centerY.equalTo(donateIconView)
            make.trailing.equalToSuperview().offset(-Constants.Size.ContentSpaceMid)
            make.size.equalTo(16)
        }
        #endif
        
        //review
        let containerView = UIView()
        containerView.addTapGesture { gesture in
            UIApplication.shared.open(Constants.URLs.AppReview)
        }
        
        containerView.backgroundColor = Constants.Color.BackgroundPrimary
        containerView.layerCornerRadius = Constants.Size.ContentSpaceMax
        addSubview(containerView)
        containerView.snp.makeConstraints { make in
            #if SIDE_LOAD
            make.top.equalTo(donateContainerView.snp.bottom).offset(Constants.Size.ContentSpaceHuge)
            #else
            make.top.equalToSuperview().offset(Constants.Size.ContentSpaceHuge)
            #endif
            make.leading.trailing.equalToSuperview().inset(Constants.Size.ContentSpaceMid)
        }
        
        let backgroundImageView = RadialGradientView()
        containerView.addSubview(backgroundImageView)
        backgroundImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        let descLabelLeft = UILabel()
        descLabelLeft.textColor = Constants.Color.LabelPrimary
        descLabelLeft.font = Constants.Font.body(size: .l, weight: .semibold)
        descLabelLeft.text = R.string.localizable.ratingTitleLeft()
        containerView.addSubview(descLabelLeft)
        descLabelLeft.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(Constants.Size.ContentSpaceMid)
            make.top.equalToSuperview().offset(Constants.Size.ContentSpaceMin)
        }
        
        let appNameImage = GradientImageView(image: R.image.app_title()?.scaled(toSize: CGSize(width: 100, height: 8.2)))
        containerView.addSubview(appNameImage)
        appNameImage.snp.makeConstraints { make in
            make.leading.equalTo(descLabelLeft.snp.trailing).offset(Constants.Size.ContentSpaceUltraTiny)
            make.centerY.equalTo(descLabelLeft)
        }
        
        let descLabelRight = UILabel()
        descLabelRight.textColor = Constants.Color.LabelPrimary
        descLabelRight.font = Constants.Font.body(size: .l, weight: .semibold)
        descLabelRight.text = R.string.localizable.ratingTitleRight()
        containerView.addSubview(descLabelRight)
        descLabelRight.snp.makeConstraints { make in
            make.leading.equalTo(appNameImage.snp.trailing).offset(Constants.Size.ContentSpaceUltraTiny)
            make.centerY.equalTo(appNameImage)
        }
        
        let detalLabel = UILabel()
        detalLabel.numberOfLines = 0
        detalLabel.textColor = Constants.Color.LabelSecondary
        detalLabel.font = Constants.Font.caption(size: .l)
        detalLabel.text = R.string.localizable.ratingDetail()
        containerView.addSubview(detalLabel)
        detalLabel.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(Constants.Size.ContentSpaceMid)
            make.top.equalTo(appNameImage.snp.bottom).offset(Constants.Size.ContentSpaceUltraTiny)
        }
        
        let starContainer = UIView()
        (0..<5).forEach { index in
            let starView = UIImageView(image: R.image.settings_star())
            starView.contentMode = .center
            starContainer.addSubview(starView)
            starView.snp.makeConstraints { make in
                make.size.equalTo(Constants.Size.IconSizeMin)
                make.top.bottom.equalToSuperview()
                if index == 0 {
                    make.leading.equalToSuperview()
                } else {
                    
                    make.leading.equalTo(starContainer.subviews[index-1].snp.trailing).offset(Constants.Size.ContentSpaceUltraTiny)
                }
                if index == 4 {
                    make.trailing.equalToSuperview()
                }
                make.bottom.equalToSuperview()
            }
        }
        containerView.addSubview(starContainer)
        starContainer.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(Constants.Size.ContentSpaceMid)
            make.top.equalTo(detalLabel.snp.bottom).offset(6)
            make.bottom.equalToSuperview().offset(-Constants.Size.ContentSpaceMin)
        }
        
        let seperator = SparkleSeperatorView(isGradient: true)
        addSubview(seperator)
        seperator.snp.makeConstraints { make in
            make.leading.trailing.equalTo(containerView).inset(Constants.Size.ContentSpaceMax)
            make.height.equalTo(24)
            make.top.equalTo(containerView.snp.bottom).offset(40)
        }
        
        let bottomAppNameImage = UIImageView(image: R.image.app_title()?.withRenderingMode(.alwaysTemplate))
        bottomAppNameImage.tintColor = Constants.Color.LabelTertiary
        addSubview(bottomAppNameImage)
        bottomAppNameImage.snp.makeConstraints { make in
            make.top.equalTo(seperator.snp.bottom).offset(40)
            make.centerX.equalToSuperview()
        }
        
        let versionLabel = UILabel()
        versionLabel.textColor = Constants.Color.LabelTertiary
        versionLabel.font = Constants.Font.caption(size: .m)
        versionLabel.text = "Version \(Constants.Config.AppVersion)"
        addSubview(versionLabel)
        versionLabel.snp.makeConstraints { make in
            make.top.equalTo(bottomAppNameImage.snp.bottom).offset(7)
            make.centerX.equalToSuperview()
        }
        
        let starView = UIImageView(image: UIImage(symbol: .sparkle, color: Constants.Color.BackgroundSecondary))
        addSubview(starView)
        starView.snp.makeConstraints { make in
            make.top.equalTo(versionLabel.snp.bottom).offset(40)
            make.centerX.equalToSuperview()
        }
        
        let lilyView = UIImageView(image: R.image.lily())
        addSubview(lilyView)
        lilyView.snp.makeConstraints { make in
            make.top.equalTo(starView.snp.bottom).offset(40)
            make.centerX.equalToSuperview()
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
        
}
