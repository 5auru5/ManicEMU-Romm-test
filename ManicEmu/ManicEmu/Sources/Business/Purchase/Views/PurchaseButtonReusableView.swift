//
//  PurchaseButtonReusableView.swift
//  ManicEmu
//
//  Created by Daiuno on 2025/3/15.
//  Copyright © 2025 Manic EMU. All rights reserved.
//
// SPDX-License-Identifier: AGPL-3.0-or-later

class PurchaseButtonReusableView: UICollectionReusableView {
    var descriptionLabel: UILabel = {
        let view = UILabel()
        view.textColor = Constants.Color.LabelSecondary
        view.font = Constants.Font.caption(size: .l, weight: .semibold)
        return view
    }()
    
    var buttonContainer: UIView = {
        let view = UIView()
        view.isUserInteractionEnabled = false
        view.enableInteractive = false
        view.delayInteractiveTouchEnd = true
        view.layerCornerRadius = Constants.Size.ItemHeightMid/2
        return view
    }()
    
    private var buttonLabel: UILabel = {
        let view = UILabel()
        view.textAlignment = .center
        view.font = Constants.Font.body(size: .l, weight: .medium)
        return view
    }()
    
    private var termsOfServiceLabel: UILabel = {
        let view = UILabel()
        view.text = R.string.localizable.termOfServiceTitle()
        view.textColor = Constants.Color.LabelSecondary
        view.font = Constants.Font.caption(weight: .regular)
        view.isUserInteractionEnabled = true
        view.adjustsFontSizeToFitWidth = true
        view.addTapGesture { gesture in
            topViewController()?.present(WebViewController(url: Constants.URLs.PaymentTerms), animated: true)
        }
        return view
    }()
    
    private var privacyLabel: UILabel = {
        let view = UILabel()
        view.text = R.string.localizable.privacyPolicyTitle()
        view.textColor = Constants.Color.LabelSecondary
        view.font = Constants.Font.caption(weight: .regular)
        view.isUserInteractionEnabled = true
        view.adjustsFontSizeToFitWidth = true
        view.addTapGesture { gesture in
            topViewController()?.present(WebViewController(url: Constants.URLs.PrivacyPolicy), animated: true)
        }
        return view
    }()
    
    private var userProtocolLabel: UILabel = {
        let view = UILabel()
        view.text = R.string.localizable.userAgreementTitle()
        view.textColor = Constants.Color.LabelSecondary
        view.font = Constants.Font.caption(weight: .regular)
        view.isUserInteractionEnabled = true
        view.adjustsFontSizeToFitWidth = true
        view.addTapGesture { gesture in
            topViewController()?.present(WebViewController(url: Constants.URLs.TermsOfUse), animated: true)
        }
        return view
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        addSubview(descriptionLabel)
        descriptionLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().offset(Constants.Size.ContentSpaceHuge)
        }
        
        addSubview(buttonContainer)
        buttonContainer.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(Constants.Size.ContentSpaceHuge)
            make.top.equalTo(descriptionLabel.snp.bottom).offset(Constants.Size.ContentSpaceMin)
            make.height.equalTo(Constants.Size.ItemHeightMid)
        }
        
        buttonContainer.addSubview(buttonLabel)
        buttonLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        addSubview(privacyLabel)
        privacyLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(buttonContainer.snp.bottom).offset(Constants.Size.ContentSpaceMin)
        }
        
        let leftLine = UIView()
        leftLine.backgroundColor = Constants.Color.LabelSecondary
        addSubview(leftLine)
        leftLine.snp.makeConstraints { make in
            make.trailing.equalTo(privacyLabel.snp.leading).offset(-Constants.Size.ContentSpaceUltraTiny)
            make.centerY.equalTo(privacyLabel)
            make.height.equalTo(privacyLabel).inset(2)
            make.width.equalTo(1)
        }
        
        let rightLine = UIView()
        rightLine.backgroundColor = Constants.Color.LabelSecondary
        addSubview(rightLine)
        rightLine.snp.makeConstraints { make in
            make.leading.equalTo(privacyLabel.snp.trailing).offset(Constants.Size.ContentSpaceUltraTiny)
            make.centerY.equalTo(privacyLabel)
            make.height.equalTo(privacyLabel).inset(2)
            make.width.equalTo(1)
        }
        
        //左边 服务条款
        addSubview(termsOfServiceLabel)
        termsOfServiceLabel.snp.makeConstraints { make in
            make.trailing.equalTo(leftLine.snp.leading).offset(-Constants.Size.ContentSpaceUltraTiny)
            make.centerY.equalTo(leftLine)
            make.leading.greaterThanOrEqualTo(Constants.Size.ContentSpaceHuge)
        }
        
        //右边 用户协议
        addSubview(userProtocolLabel)
        userProtocolLabel.snp.makeConstraints { make in
            make.leading.equalTo(rightLine.snp.trailing).offset(Constants.Size.ContentSpaceUltraTiny)
            make.centerY.equalTo(rightLine)
            make.trailing.lessThanOrEqualToSuperview().offset(-Constants.Size.ContentSpaceHuge)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setData(title: String, descripton: String, enable: Bool) {
        descriptionLabel.text = descripton
        buttonContainer.backgroundColor = enable ? Constants.Color.Main : Constants.Color.Main.darken(by: UIDevice.isDarkMode ? 0.7 : 0.35)
        buttonContainer.isUserInteractionEnabled = enable
        buttonContainer.enableInteractive = false
        buttonLabel.text = title
        buttonLabel.textColor = enable ? Constants.Color.LabelPrimary.forceStyle(.dark) : Constants.Color.LabelPrimary.forceStyle(.dark).darken(by: UIDevice.isDarkMode ? 0.7 : 0.35)
    }
    
    
}
