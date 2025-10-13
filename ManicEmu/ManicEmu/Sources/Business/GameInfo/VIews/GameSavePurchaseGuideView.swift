//
//  GameSavePurchaseGuideView.swift
//  ManicEmu
//
//  Created by Daiuno on 2025/3/17.
//  Copyright © 2025 Manic EMU. All rights reserved.
//
// SPDX-License-Identifier: AGPL-3.0-or-later

class GameSavePurchaseGuideView: UIView {
    init(hideSeperator: Bool) {
        super.init(frame: .zero)
        enableInteractive = true
        delayInteractiveTouchEnd = true
        addTapGesture { gesture in
            topViewController()?.present(PurchaseViewController(), animated: true)
        }
        
        let seperator = SparkleSeperatorView(color: Constants.Color.BackgroundSecondary)
        if !hideSeperator {
            addSubview(seperator)
            seperator.snp.makeConstraints { make in
                make.leading.trailing.equalToSuperview().inset(Constants.Size.ContentSpaceMax)
                make.height.equalTo(16)
                make.top.equalToSuperview().offset(40)
            }
        }
        
        
        let containerView = UIView()
        addSubview(containerView)
        containerView.snp.makeConstraints { make in
            if hideSeperator {
                make.top.equalToSuperview().offset(Constants.Size.ContentSpaceMax)
            } else {
                make.top.equalTo(seperator.snp.bottom).offset(40)
            }
            make.centerX.equalToSuperview()
        }

        let becomeLabel = UILabel()
        becomeLabel.textColor = Constants.Color.LabelPrimary
        becomeLabel.font = Constants.Font.title(size: .s, weight: .semibold)
        becomeLabel.text = R.string.localizable.gameSaveGuideBecomTitle()
        containerView.addSubview(becomeLabel)
        becomeLabel.snp.makeConstraints { make in
            make.leading.top.bottom.equalToSuperview()
        }
        
        let appNameImage = UIImageView(image: UIImage(.dm, light: (R.image.app_title_light()?.scaled(toSize: CGSize(width: 138, height: 11.3)))!, dark: (R.image.app_title()?.scaled(toSize: CGSize(width: 138, height: 11.3)))!))
        containerView.addSubview(appNameImage)
        appNameImage.snp.makeConstraints { make in
            make.leading.equalTo(becomeLabel.snp.trailing).offset(Constants.Size.ContentSpaceUltraTiny)
            make.centerY.equalTo(becomeLabel)
        }
        
        let memberLabel = UILabel()
        memberLabel.textColor = Constants.Color.LabelPrimary
        memberLabel.font = Constants.Font.title(size: .s, weight: .semibold)
        memberLabel.text = R.string.localizable.gameSaveGuideMemberTitle()
        containerView.addSubview(memberLabel)
        memberLabel.snp.makeConstraints { make in
            make.leading.equalTo(appNameImage.snp.trailing).offset(Constants.Size.ContentSpaceUltraTiny)
            make.trailing.equalToSuperview()
            make.centerY.equalTo(becomeLabel)
        }
        
        let detalLabel = UILabel()
        detalLabel.textAlignment = .center
        detalLabel.numberOfLines = 0
        detalLabel.textColor = Constants.Color.LabelSecondary
        detalLabel.font = Constants.Font.caption(size: .l)
        detalLabel.text = R.string.localizable.gameSaveGuideDesc()
        addSubview(detalLabel)
        detalLabel.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(Constants.Size.ContentSpaceHuge)
            make.top.equalTo(containerView.snp.bottom).offset(Constants.Size.ContentSpaceUltraTiny)
        }
        
        let button = SymbolButton(image: nil, title: R.string.localizable.goToUpgrade(), titleFont: Constants.Font.caption(size: .l, weight: .semibold), titleColor: Constants.Color.LabelPrimary.forceStyle(.dark), titlePosition: .left, imageAndTitlePadding: 0)
        button.enableRoundCorner = true
        let buttonBackground = UIView(frame: CGRect(origin: .zero, size: CGSize(width: 100, height: 30)))
        buttonBackground.addGradient(colors: Constants.Color.Gradient, direction: .leftToRight)
        button.insertSubview(buttonBackground, at: 0)
        addSubview(button)
        button.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(detalLabel.snp.bottom).offset(Constants.Size.ContentSpaceMid)
            make.size.equalTo(CGSize(width: 100, height: 30))
            make.bottom.equalToSuperview()
        }
        
       
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
        
}
