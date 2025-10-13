//
//  GamesListBlankSlateView.swift
//  ManicEmu
//
//  Created by Daiuno on 2025/3/11.
//  Copyright © 2025 Manic EMU. All rights reserved.
//
// SPDX-License-Identifier: AGPL-3.0-or-later

import Device

class GamesListBlankSlateView: BaseView {
    
    deinit {
        Log.debug("\(String(describing: Self.self)) deinit")
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        Log.debug("\(String(describing: Self.self)) init")
        let containerView = UIView()
        addSubview(containerView)
        containerView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        //中间的分割线和星星
        let seperator = SparkleSeperatorView()
        containerView.addSubview(seperator)
        seperator.snp.makeConstraints { make in
            make.leading.trailing.equalTo(containerView).inset(Constants.Size.ContentSpaceMax)
            make.height.equalTo(16)
            make.centerY.equalToSuperview()
        }
        
        //引导导入游戏
        let guideContainer = UIView()
        containerView.addSubview(guideContainer)
        guideContainer.snp.makeConstraints { make in
            make.bottom.equalTo(seperator.snp.top).offset(-40)
            make.centerX.equalToSuperview()
            make.leading.greaterThanOrEqualToSuperview().offset(Constants.Size.ContentSpaceMax)
            make.trailing.lessThanOrEqualToSuperview().offset(-Constants.Size.ContentSpaceMax)
        }
        let guideLabelLeft = UILabel()
        guideLabelLeft.textColor = Constants.Color.LabelPrimary
        guideLabelLeft.font = Constants.Font.body()
        guideLabelLeft.text = R.string.localizable.gamesListEmptyGuideLeft()
        guideContainer.addSubview(guideLabelLeft)
        guideLabelLeft.adjustsFontSizeToFitWidth = true
        guideLabelLeft.snp.makeConstraints { make in
            make.leading.centerY.equalToSuperview()
        }
        let guideImageView = GradientImageView(image: UIImage(symbol: .trayAndArrowDown).withRenderingMode(.alwaysTemplate))
        guideContainer.addSubview(guideImageView)
        guideImageView.snp.makeConstraints { make in
            make.leading.equalTo(guideLabelLeft.snp.trailing).offset(Constants.Size.ContentSpaceMin)
            make.top.bottom.equalToSuperview()
            make.size.equalTo(Constants.Size.IconSizeTiny)
        }
        let guideLabelRight = UILabel()
        guideLabelRight.textColor = Constants.Color.LabelPrimary
        guideLabelRight.font = Constants.Font.body()
        guideLabelRight.text = R.string.localizable.gamesListEmptyGuideRight()
        guideContainer.addSubview(guideLabelRight)
        guideLabelRight.adjustsFontSizeToFitWidth = true
        guideLabelRight.snp.makeConstraints { make in
            make.leading.equalTo(guideImageView.snp.trailing).offset(Constants.Size.ContentSpaceMin)
            make.trailing.centerY.equalToSuperview()
        }
        
        //欢迎标语
        let welcomeContainer = UIView()
        containerView.addSubview(welcomeContainer)
        welcomeContainer.snp.makeConstraints { make in
            make.bottom.equalTo(guideContainer.snp.top).offset(-Constants.Size.ContentSpaceTiny)
            make.centerX.equalToSuperview()
            make.leading.greaterThanOrEqualToSuperview().offset(Constants.Size.ContentSpaceMax)
            make.trailing.lessThanOrEqualToSuperview().offset(-Constants.Size.ContentSpaceMax)
        }
        let welcomeLabelLeft = UILabel()
        welcomeLabelLeft.textColor = Constants.Color.LabelPrimary
        welcomeLabelLeft.font = Constants.Font.title(size: .s, weight: .semibold)
        welcomeLabelLeft.text = R.string.localizable.gamesListEmptyWelcomeLeft()
        welcomeContainer.addSubview(welcomeLabelLeft)
        welcomeLabelLeft.adjustsFontSizeToFitWidth = true
        welcomeLabelLeft.snp.makeConstraints { make in
            make.leading.top.bottom.equalToSuperview()
        }
        
        let appNameImage = UIImageView(image: UIImage(.dm, light: (R.image.app_title_light()?.scaled(toSize: CGSize(width: 138, height: 11.3)))!, dark: (R.image.app_title()?.scaled(toSize: CGSize(width: 138, height: 11.3)))!))
        welcomeContainer.addSubview(appNameImage)
        appNameImage.snp.makeConstraints { make in
            make.leading.equalTo(welcomeLabelLeft.snp.trailing).offset(Constants.Size.ContentSpaceUltraTiny)
            make.centerY.equalToSuperview()
        }
        let welcomeLabelRight = UILabel()
        welcomeLabelRight.textColor = Constants.Color.LabelPrimary
        welcomeLabelRight.font = Constants.Font.title(size: .s, weight: .semibold)
        welcomeLabelRight.text = R.string.localizable.gamesListEmptyWelcomeRight()
        welcomeContainer.addSubview(welcomeLabelRight)
        welcomeLabelRight.adjustsFontSizeToFitWidth = true
        welcomeLabelRight.snp.makeConstraints { make in
            make.leading.equalTo(appNameImage.snp.trailing).offset(Constants.Size.ContentSpaceUltraTiny)
            make.trailing.centerY.equalToSuperview()
        }
        
        //加入社区
        let channelLinkContainerView = UIView()
        channelLinkContainerView.backgroundColor = Constants.Color.Background
        channelLinkContainerView.layerCornerRadius = 15
        addSubview(channelLinkContainerView)
        channelLinkContainerView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.height.equalTo(30)
            make.top.equalTo(seperator.snp.bottom).offset(40)
            make.leading.greaterThanOrEqualToSuperview().offset(Constants.Size.ContentSpaceMax)
            make.trailing.lessThanOrEqualToSuperview().offset(-Constants.Size.ContentSpaceMax)
        }
        let channelLinkLabel = UILabel()
        let channelName = Locale.prefersCN ? R.string.localizable.qqChannelName() : "Discord"
        let matt = NSMutableAttributedString(string: R.string.localizable.importChannelTips(" \(channelName) "), attributes: [.font: Constants.Font.caption(size: .l), .foregroundColor: Constants.Color.LabelPrimary])
        channelLinkLabel.attributedText = matt.applying(attributes: [.foregroundColor: Constants.Color.Main], toOccurrencesOf: channelName)
        channelLinkLabel.isUserInteractionEnabled = true
        channelLinkLabel.textAlignment = .center
        channelLinkLabel.adjustsFontSizeToFitWidth = true
        channelLinkContainerView.addSubview(channelLinkLabel)
        channelLinkLabel.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(Constants.Size.ContentSpaceMid)
            make.centerY.equalToSuperview()
        }
        let channelLinkButton = UIButton()
        channelLinkContainerView.addSubview(channelLinkButton)
        channelLinkButton.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        channelLinkButton.onTap {
            if Locale.prefersCN {
                UIApplication.shared.open(Constants.URLs.JoinQQ)
            } else {
                UIApplication.shared.open(Constants.URLs.JoinDiscord)
            }
        }
        
        //warnning
        let warnningContainer = UIView()
        containerView.addSubview(warnningContainer)
        warnningContainer.snp.makeConstraints { make in
            make.bottom.equalToSuperview().offset(-(Constants.Size.ContentInsetBottom + Constants.Size.ItemHeightMax + ((Device.size().rawValue < Size.screen5_8Inch.rawValue || UIDevice.isPad) ? Constants.Size.ContentSpaceHuge : 0)))
            make.centerX.equalToSuperview()
            make.leading.greaterThanOrEqualToSuperview().offset(Constants.Size.ContentSpaceMax)
            make.trailing.lessThanOrEqualToSuperview().offset(-Constants.Size.ContentSpaceMax)
        }
        let warnningIcon = UIImageView(image: UIImage(symbol: .exclamationmarkTriangleFill, size: 14, weight: .medium, colors: [Constants.Color.Background, Constants.Color.Yellow]))
        warnningIcon.contentMode = .center
        warnningContainer.addSubview(warnningIcon)
        warnningIcon.snp.makeConstraints { make in
            make.leading.top.bottom.centerY.equalToSuperview()
            make.size.equalTo(Constants.Size.IconSizeMin)
        }
        let warnningLabel = UILabel()
        warnningLabel.font = Constants.Font.body(size: .m, weight: .medium)
        warnningLabel.textColor = Constants.Color.Yellow
        warnningLabel.text = R.string.localizable.gamesListEmptyWarnning()
        warnningLabel.adjustsFontSizeToFitWidth = true
        warnningContainer.addSubview(warnningLabel)
        warnningLabel.snp.makeConstraints { make in
            make.centerY.equalTo(warnningIcon)
            make.leading.equalTo(warnningIcon.snp.trailing).offset(Constants.Size.ContentSpaceUltraTiny)
            make.trailing.equalToSuperview()
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
        
}
