//
//  MembershipInfoView.swift
//  ManicEmu
//
//  Created by Daiuno on 2025/3/17.
//  Copyright © 2025 Manic EMU. All rights reserved.
//
// SPDX-License-Identifier: AGPL-3.0-or-later

class MembershipInfoView: UIView {
    
    private var membershipNotification: Any? = nil
    private var productUpdateNotification: Any? = nil
    
    deinit {
        Log.debug("\(String(describing: Self.self)) deinit")
        if let membershipNotification = membershipNotification {
            NotificationCenter.default.removeObserver(membershipNotification)
        }
        if let productUpdateNotification = productUpdateNotification {
            NotificationCenter.default.removeObserver(productUpdateNotification)
        }
    }
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        Log.debug("\(String(describing: Self.self)) init")
        setupViews()
        
        membershipNotification = NotificationCenter.default.addObserver(forName: Constants.NotificationName.MembershipChange, object: nil, queue: .main) { [weak self] notification in
            self?.setupViews()
        }
        productUpdateNotification = NotificationCenter.default.addObserver(forName: Constants.NotificationName.ProductsUpdate, object: nil, queue: .main) { [weak self] notification in
            self?.setupViews()
        }
    }
    
    private func setupViews() {
        subviews.forEach { $0.removeFromSuperview() }
        let isMember = PurchaseManager.isMember
        
        if isMember {
            let titleContainer = UIView()
            addSubview(titleContainer)
            titleContainer.snp.makeConstraints { make in
                make.top.equalToSuperview().offset(Constants.Size.ContentSpaceMax)
                make.centerX.equalToSuperview()
                make.height.equalTo(Constants.Size.IconSizeMin.height)
                make.leading.greaterThanOrEqualToSuperview().offset(Constants.Size.ContentSpaceMid)
                make.trailing.lessThanOrEqualToSuperview().offset(-Constants.Size.ContentSpaceMid)
            }
            
            let titleLeftView = UIImageView(image: R.image.customLaurelLeading()?.applySymbolConfig(font: UIFont.systemFont(ofSize: 16, weight: .bold), color: Constants.Color.LabelPrimary.forceStyle(.dark)))
            if Locale.isRTLLanguage {
                titleLeftView.transform = CGAffineTransform(scaleX: -1, y: 1)
            }
            
            titleLeftView.contentMode = .center
            titleContainer.addSubview(titleLeftView)
            titleLeftView.snp.makeConstraints { make in
                make.leading.top.bottom.equalToSuperview()
            }
            
            let titleLabel = UILabel()
            titleLabel.adjustsFontSizeToFitWidth = true
            var text = R.string.localizable.hi() + " " + R.string.localizable.foreverMemberTitle()
            if PurchaseManager.isAnnualMember {
                text = R.string.localizable.hi() + " " + R.string.localizable.annualMemberTitle()
            } else if PurchaseManager.isMonthlyMember {
                text = R.string.localizable.hi() + " " + R.string.localizable.monthlyMemberTitle()
            }
            titleLabel.text = text
            titleLabel.font = Constants.Font.title(size: .s)
            titleLabel.textColor = Constants.Color.LabelPrimary.forceStyle(.dark)
            titleContainer.addSubview(titleLabel)
            titleLabel.snp.makeConstraints { make in
                make.leading.equalTo(titleLeftView.snp.trailing).offset(Constants.Size.ContentSpaceUltraTiny)
                make.centerY.equalToSuperview()
            }
            
            let titleRightView = UIImageView(image: R.image.customLaurelLeading()?.applySymbolConfig(font: UIFont.systemFont(ofSize: 16, weight: .bold), color: Constants.Color.LabelPrimary.forceStyle(.dark)))
            if !Locale.isRTLLanguage {
                titleRightView.transform = CGAffineTransform(scaleX: -1, y: 1)
            }
            titleRightView.contentMode = .center
            titleContainer.addSubview(titleRightView)
            titleRightView.snp.makeConstraints { make in
                make.trailing.top.bottom.equalToSuperview()
                make.leading.equalTo(titleLabel.snp.trailing).offset(Constants.Size.ContentSpaceUltraTiny)
            }
            
            let thankContainer = UIView()
            addSubview(thankContainer)
            thankContainer.snp.makeConstraints { make in
                make.centerX.equalToSuperview()
                make.top.equalTo(titleContainer.snp.bottom).offset(Constants.Size.ContentSpaceUltraTiny)
                make.leading.greaterThanOrEqualToSuperview().offset(Constants.Size.ContentSpaceMid)
                make.trailing.lessThanOrEqualToSuperview().offset(-Constants.Size.ContentSpaceMid)
            }
            let thankLabel = UILabel()
            thankLabel.textColor = Constants.Color.LabelPrimary.forceStyle(.dark)
            thankLabel.font = Constants.Font.body(size: .s, weight: .medium)
            thankLabel.text = R.string.localizable.thanksCommingDesc()
            thankLabel.adjustsFontSizeToFitWidth = true
            thankContainer.addSubview(thankLabel)
            thankLabel.snp.makeConstraints { make in
                make.leading.top.bottom.equalToSuperview()
            }
            
            let appNameImage = UIImageView(image: R.image.app_title()?.scaled(toSize: CGSize(width: 100, height: 8.2)))
            thankContainer.addSubview(appNameImage)
            appNameImage.snp.makeConstraints { make in
                make.leading.equalTo(thankLabel.snp.trailing).offset(Constants.Size.ContentSpaceUltraTiny)
                make.centerY.equalTo(thankLabel)
            }
            
            let playLabel = UILabel()
            playLabel.textColor = Constants.Color.LabelPrimary.forceStyle(.dark)
            playLabel.font = Constants.Font.body(size: .s, weight: .medium)
            playLabel.text = R.string.localizable.playGameDesc()
            playLabel.adjustsFontSizeToFitWidth = true
            thankContainer.addSubview(playLabel)
            playLabel.snp.makeConstraints { make in
                make.leading.equalTo(appNameImage.snp.trailing).offset(Constants.Size.ContentSpaceUltraTiny)
                make.trailing.equalToSuperview()
                make.centerY.equalTo(thankLabel)
            }
            
        } else {
            let becomeLabel = UILabel()
            becomeLabel.textColor = Constants.Color.LabelPrimary.forceStyle(.dark)
            becomeLabel.font = Constants.Font.title(size: .s)
            becomeLabel.text = R.string.localizable.gameSaveGuideBecomTitle()
            becomeLabel.adjustsFontSizeToFitWidth = true
            addSubview(becomeLabel)
            becomeLabel.snp.makeConstraints { make in
                make.leading.equalToSuperview().offset(Constants.Size.ContentSpaceMid)
                make.top.equalToSuperview().offset(Constants.Size.ContentSpaceMin)
            }
            
            let appNameImage = UIImageView(image: R.image.app_title()?.scaled(toSize: CGSize(width: 138, height: 11.31)))
            addSubview(appNameImage)
            appNameImage.snp.makeConstraints { make in
                make.leading.equalTo(becomeLabel.snp.trailing).offset(Constants.Size.ContentSpaceUltraTiny)
                make.centerY.equalTo(becomeLabel)
            }
            
            let memberLabel = UILabel()
            memberLabel.textColor = Constants.Color.LabelPrimary.forceStyle(.dark)
            memberLabel.font = Constants.Font.title(size: .s)
            memberLabel.text = R.string.localizable.gameSaveGuideMemberTitle()
            memberLabel.adjustsFontSizeToFitWidth = true
            addSubview(memberLabel)
            memberLabel.snp.makeConstraints { make in
                make.leading.equalTo(appNameImage.snp.trailing).offset(Constants.Size.ContentSpaceUltraTiny)
                make.centerY.equalTo(becomeLabel)
                make.trailing.lessThanOrEqualToSuperview().offset(-Constants.Size.ContentSpaceMid)
            }
            
            let detalLabel = UILabel()
            detalLabel.textColor = Constants.Color.LabelPrimary.forceStyle(.dark)
            detalLabel.font = Constants.Font.body(size: .s, weight: .medium)
            detalLabel.text = R.string.localizable.settingsNonMemberDesc()
            detalLabel.adjustsFontSizeToFitWidth = true
            addSubview(detalLabel)
            detalLabel.snp.makeConstraints { make in
                make.leading.trailing.equalToSuperview().inset(Constants.Size.ContentSpaceMid)
                make.top.equalTo(becomeLabel.snp.bottom).offset(Constants.Size.ContentSpaceUltraTiny)
            }
        }
       
        
        let symbol: SFSymbol
        var title = R.string.localizable.promptLabelForYear()
        if isMember {
            symbol = .sparkles
            title = R.string.localizable.thanksSupportDesc()
        } else {
            symbol = .appGiftFill
            if let freeTrialDay = PurchaseManager.maxFreeTrialDay {
                //有试用
                title = R.string.localizable.settingsFreeTrialDesc(freeTrialDay)
            }
        }
        let giftView = SettingsMembershipGiftView(symbol: symbol, title: title)
        addSubview(giftView)
        giftView.snp.makeConstraints { make in
            make.bottom.equalToSuperview().inset(Constants.Size.ContentSpaceMin)
            if PurchaseManager.isMember {
                make.centerX.equalToSuperview()
            } else {
                make.leading.equalToSuperview().offset(Constants.Size.ContentSpaceMid)
            }
            make.height.equalTo(32)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
