//
//  TriggerProListBlankSlateView.swift
//  ManicEmu
//
//  Created by Daiuno on 2025/10/23.
//  Copyright © 2025 Manic EMU. All rights reserved.
//

class TriggerProListBlankSlateView: BaseView {
    deinit {
        Log.debug("\(String(describing: Self.self)) deinit")
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        Log.debug("\(String(describing: Self.self)) init")
        let containerView = UIView()
        addSubview(containerView)
        containerView.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        
        let iconImageView = UIImageView(image: R.image.empty_icon())
        iconImageView.contentMode = .center
        containerView.addSubview(iconImageView)
        iconImageView.snp.makeConstraints { make in
            make.top.centerX.equalToSuperview()
            make.size.equalTo(100)
        }
        
        let titleLabel = UILabel()
        titleLabel.textColor = Constants.Color.LabelPrimary
        titleLabel.font = Constants.Font.title(size: .s, weight: .semibold)
        titleLabel.text = R.string.localizable.noContentResult()
        containerView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(iconImageView.snp.bottom).offset(Constants.Size.ContentSpaceHuge)
        }
        
        //引导导入游戏
        let guideContainer = UIView()
        containerView.addSubview(guideContainer)
        guideContainer.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(Constants.Size.ContentSpaceTiny)
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview()
        }
        let guideLabelLeft = UILabel()
        guideLabelLeft.textColor = Constants.Color.LabelSecondary
        guideLabelLeft.font = Constants.Font.body(size: .l)
        guideLabelLeft.text = R.string.localizable.cheatCodeEmptyGuideLeft()
        guideContainer.addSubview(guideLabelLeft)
        guideLabelLeft.snp.makeConstraints { make in
            make.leading.centerY.equalToSuperview()
        }
        let guideImageView = SymbolButton(image: UIImage(symbol: .plus, font: Constants.Font.body(size: .m, weight: .bold)))
        guideImageView.enableRoundCorner = true
        guideContainer.addSubview(guideImageView)
        guideImageView.snp.makeConstraints { make in
            make.leading.equalTo(guideLabelLeft.snp.trailing).offset(Constants.Size.ContentSpaceMin)
            make.top.bottom.equalToSuperview()
            make.size.equalTo(Constants.Size.ItemHeightUltraTiny)
        }
        let guideLabelRight = UILabel()
        guideLabelRight.textColor = Constants.Color.LabelSecondary
        guideLabelRight.font = Constants.Font.body(size: .l)
        guideLabelRight.text =  R.string.localizable.addTriggerPro()
        guideContainer.addSubview(guideLabelRight)
        guideLabelRight.snp.makeConstraints { make in
            make.leading.equalTo(guideImageView.snp.trailing).offset(Constants.Size.ContentSpaceMin)
            make.trailing.centerY.equalToSuperview()
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
        
}
