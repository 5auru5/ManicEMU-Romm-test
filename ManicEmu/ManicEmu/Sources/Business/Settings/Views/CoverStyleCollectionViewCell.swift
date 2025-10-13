//
//  CoverStyleCollectionViewCell.swift
//  ManicEmu
//
//  Created by Daiuno on 2025/5/3.
//  Copyright © 2025 Manic EMU. All rights reserved.
//
// SPDX-License-Identifier: AGPL-3.0-or-later

import BetterSegmentedControl

class CoverStyleCollectionViewCell: UICollectionViewCell {
    
    lazy var segmentView: BetterSegmentedControl = {
        let titles = [
            R.string.localizable.themeCoverStyleName(1),
            R.string.localizable.themeCoverStyleName(2),
            R.string.localizable.themeCoverStyleName(3)
        ]
        let segments = LabelSegment.segments(withTitles: titles,
                                             normalFont: Constants.Font.body(),
                                             normalTextColor: Constants.Color.LabelSecondary,
                                            selectedTextColor: Constants.Color.LabelPrimary)
        let options: [BetterSegmentedControl.Option] = [
            .backgroundColor(Constants.Color.Background),
            .indicatorViewInset(5),
            .indicatorViewBackgroundColor(Constants.Color.BackgroundPrimary),
            .cornerRadius(16)
        ]
        let view = BetterSegmentedControl(frame: .zero,
                                          segments: segments,
                                          options: options)
        
        view.on(.valueChanged) { [weak self] sender, forEvent in
            guard let self = self, let index = (sender as? BetterSegmentedControl)?.index else { return }
            UIDevice.generateHaptic()
            
        }
        
        return view
    }()
    
    private var coverView: GameCoverView = {
        let view = GameCoverView()
        return view
    }()
    
    private var cornerRadiusLabel: UILabel = {
        let label = UILabel()
        label.font = Constants.Font.body(size: .l)
        label.textColor = Constants.Color.LabelPrimary
        return label
    }()
    
    private var sliderView: UISlider = {
        let view = UISlider()
        view.minimumValue = 0
        view.maximumValue = 1
        view.minimumTrackTintColor = Constants.Color.Main
        view.maximumTrackTintColor = Constants.Color.BackgroundSecondary
        return view
    }()
    
    private var forceSquareIconView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .center
        view.layerCornerRadius = 6
        view.image = UIImage(symbol: .square, font: Constants.Font.body(size: .s, weight: .medium), color: Constants.Color.LabelPrimary.forceStyle(.dark))
        return view
    }()
    
    private var forceSquareSwitchButton: DisabledTapSwitch = {
        let view = DisabledTapSwitch()
        view.onTintColor = Constants.Color.Main
        view.tintColor = Constants.Color.BackgroundSecondary
        return view
    }()
    
    private var hideGameTitleIconView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .center
        view.layerCornerRadius = 6
        view.image = UIImage(symbol: .characterTextbox, font: Constants.Font.body(size: .s, weight: .medium), color: Constants.Color.LabelPrimary.forceStyle(.dark))
        return view
    }()
    
    private var hideGameTitleSwitchButton: DisabledTapSwitch = {
        let view = DisabledTapSwitch()
        view.onTintColor = Constants.Color.Main
        view.tintColor = Constants.Color.BackgroundSecondary
        return view
    }()
    
    private var mainColorChangeNotification: Any? = nil
    
    deinit {
        if let mainColorChangeNotification = mainColorChangeNotification {
            NotificationCenter.default.removeObserver(mainColorChangeNotification)
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        layerCornerRadius = Constants.Size.CornerRadiusMax
        backgroundColor = Constants.Color.BackgroundPrimary
        
        let theme = Theme.defalut
        let style = theme.coverStyle
        
        let defaultImage = R.image.brand_icon()
        
        segmentView.setIndex(style.rawValue)
        addSubview(segmentView)
        segmentView.snp.makeConstraints { make in
            make.leading.top.trailing.equalToSuperview().inset(Constants.Size.ContentSpaceTiny)
            make.height.equalTo(Constants.Size.ItemHeightMid)
        }
        segmentView.on(.valueChanged) { [weak self] sender, forEvent in
            guard let self = self, let index = (sender as? BetterSegmentedControl)?.index else { return }
            UIDevice.generateHaptic()
            if let style = CoverStyle(rawValue: index) {
                self.sliderView.value = Float(style.defaultCornerRadius()/style.maxCornerRadius())
                self.coverView.setData(gameType: ._3ds, image: defaultImage, style: style, cornerRadius: CGFloat(self.sliderView.value) * style.maxCornerRadius())
                self.cornerRadiusLabel.text = "\(String(format: "%.0f", self.sliderView.value * 100))%"
                self.updateCoverStyle(style, ratio: self.sliderView.value)
            }
        }
        
        addSubview(coverView)
        coverView.snp.makeConstraints { make in
            make.size.equalTo(154)
            make.centerX.equalToSuperview()
            make.top.equalTo(segmentView.snp.bottom).offset(Constants.Size.ContentSpaceMax)
        }
        coverView.setData(gameType: ._3ds, image: defaultImage, style: style, cornerRadius: CGFloat(theme.coverRadiusRatio) * style.maxCornerRadius(), scalePlatform: false)
        
        
        addSubview(cornerRadiusLabel)
        cornerRadiusLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(Constants.Size.ContentSpaceHuge)
            make.top.equalTo(coverView.snp.bottom).offset(Constants.Size.ContentSpaceMax)
        }
        cornerRadiusLabel.text = "\(String(format: "%.0f", theme.coverRadiusRatio * 100))%"
        
        addSubview(sliderView)
        sliderView.snp.makeConstraints { make in
            make.leading.equalTo(cornerRadiusLabel.snp.trailing).offset(Constants.Size.ContentSpaceHuge)
            make.centerY.equalTo(cornerRadiusLabel)
            make.trailing.equalToSuperview().offset(-Constants.Size.ContentSpaceHuge)
            make.height.equalTo(22)
        }
        sliderView.value = theme.coverRadiusRatio
        sliderView.on(.valueChanged) { [weak self] sender, forEvent in
            guard let self = self else { return }
            if let style = CoverStyle(rawValue: self.segmentView.index) {
                self.coverView.updateCornerRadius(CGFloat(self.sliderView.value) * style.maxCornerRadius())
                self.cornerRadiusLabel.text = "\(String(format: "%.0f", self.sliderView.value * 100))%"
            }
        }
        sliderView.on(.touchUpInside) { [weak self] sender, forEvent in
            guard let self = self else { return }
            self.updateCornerRadiusRatio(ratio: self.sliderView.value)
        }
        sliderView.on(.touchUpOutside) { [weak self] sender, forEvent in
            guard let self = self else { return }
            self.updateCornerRadiusRatio(ratio: self.sliderView.value)
        }
        
        //开关
        let forceSquareContainer = UIView()
        forceSquareContainer.backgroundColor = Constants.Color.Background
        forceSquareContainer.layerCornerRadius = Constants.Size.CornerRadiusMid
        addSubview(forceSquareContainer)
        forceSquareContainer.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(Constants.Size.ContentSpaceMid)
            make.top.equalTo(sliderView.snp.bottom).offset(Constants.Size.ContentSpaceMax)
            make.height.equalTo(Constants.Size.ItemHeightMax)
        }
        
        forceSquareContainer.addSubview(forceSquareIconView)
        forceSquareIconView.backgroundColor = Constants.Color.Main
        forceSquareIconView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(Constants.Size.ContentSpaceMin)
            make.size.equalTo(Constants.Size.IconSizeMid)
            make.centerY.equalToSuperview()
        }
        
        let forceSquareTitleLabel: UILabel = {
            let view = UILabel()
            view.numberOfLines = 3
            var matt = NSMutableAttributedString(string: R.string.localizable.forceSquareRatioTitle(), attributes: [.font: Constants.Font.body(size: .l, weight: .semibold), .foregroundColor: Constants.Color.LabelPrimary])
            if UIDevice.isPad {
                matt.append(NSAttributedString(string: "\n" + R.string.localizable.forceSquareRatioDetail(), attributes: [.font: Constants.Font.caption(size: .l), .foregroundColor: Constants.Color.LabelSecondary]))
                let style = NSMutableParagraphStyle()
                style.lineSpacing = Constants.Size.ContentSpaceUltraTiny/2
                style.lineBreakMode = .byTruncatingTail
                matt = matt.applying(attributes: [.paragraphStyle: style]) as! NSMutableAttributedString
            }
            view.attributedText = matt
            return view
        }()
        forceSquareContainer.addSubview(forceSquareTitleLabel)
        forceSquareTitleLabel.snp.makeConstraints { make in
            make.centerY.equalTo(forceSquareIconView)
            make.leading.equalTo(forceSquareIconView.snp.trailing).offset(Constants.Size.ContentSpaceMin)
            make.trailing.equalToSuperview().offset(-46-Constants.Size.ContentSpaceMid)
        }
        
        forceSquareContainer.addSubview(forceSquareSwitchButton)
        forceSquareSwitchButton.setOn(theme.forceSquare, animated: false)
        forceSquareSwitchButton.snp.makeConstraints { make in
            make.centerY.equalTo(forceSquareIconView)
            make.trailing.equalToSuperview().offset(-Constants.Size.ContentSpaceMin)
            if #available(iOS 26.0, *) {
                make.size.equalTo(CGSize(width: 63, height: 28))
            } else {
                make.size.equalTo(CGSize(width: 51, height: 31))
            }
        }
        if #available(iOS 26.0, *) {} else {
            forceSquareSwitchButton.transform = CGAffineTransformMakeScale(0.9, 0.9)
        }
        forceSquareSwitchButton.onChange { [weak self] value in
            self?.updateCoverForceSquare(value)
        }
        
        //隐藏游戏标题
        let hideGameTitleContainer = UIView()
        hideGameTitleContainer.backgroundColor = Constants.Color.Background
        hideGameTitleContainer.layerCornerRadius = Constants.Size.CornerRadiusMid
        addSubview(hideGameTitleContainer)
        hideGameTitleContainer.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(Constants.Size.ContentSpaceMid)
            make.top.equalTo(forceSquareContainer.snp.bottom).offset(Constants.Size.ContentSpaceMax)
            make.height.equalTo(Constants.Size.ItemHeightMax)
        }
        
        hideGameTitleContainer.addSubview(hideGameTitleIconView)
        hideGameTitleIconView.backgroundColor = Constants.Color.Main
        hideGameTitleIconView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(Constants.Size.ContentSpaceMin)
            make.size.equalTo(Constants.Size.IconSizeMid)
            make.centerY.equalToSuperview()
        }
        
        let hideGameTitleLabel: UILabel = {
            let view = UILabel()
            view.font = Constants.Font.body(size: .l, weight: .semibold)
            view.textColor = Constants.Color.LabelPrimary
            view.text = R.string.localizable.hideGameTitleDesc()
            return view
        }()
        hideGameTitleContainer.addSubview(hideGameTitleLabel)
        hideGameTitleLabel.snp.makeConstraints { make in
            make.centerY.equalTo(hideGameTitleIconView)
            make.leading.equalTo(hideGameTitleIconView.snp.trailing).offset(Constants.Size.ContentSpaceMin)
            make.trailing.equalToSuperview().offset(-46-Constants.Size.ContentSpaceMid)
        }
        
        hideGameTitleContainer.addSubview(hideGameTitleSwitchButton)
        hideGameTitleSwitchButton.setOn(theme.hideGameTitle, animated: false)
        hideGameTitleSwitchButton.snp.makeConstraints { make in
            make.centerY.equalTo(hideGameTitleIconView)
            make.trailing.equalToSuperview().offset(-Constants.Size.ContentSpaceMin)
            if #available(iOS 26.0, *) {
                make.size.equalTo(CGSize(width: 63, height: 28))
            } else {
                make.size.equalTo(CGSize(width: 51, height: 31))
            }
        }
        if #available(iOS 26.0, *) {} else {
            hideGameTitleSwitchButton.transform = CGAffineTransformMakeScale(0.9, 0.9)
        }
        hideGameTitleSwitchButton.onChange { [weak self] value in
            self?.updateGameTitle(value)
        }
        
        
        //通知更新主色
        mainColorChangeNotification = NotificationCenter.default.addObserver(forName: Constants.NotificationName.MainColorChange, object: nil, queue: .main) { [weak self] notification in
            guard let self = self else { return }
            self.forceSquareIconView.backgroundColor = Constants.Color.Main
            self.hideGameTitleIconView.backgroundColor = Constants.Color.Main
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func updateCornerRadiusRatio(ratio: Float) {
        let theme = Theme.defalut
        guard theme.coverRadiusRatio != ratio else { return }
        Theme.change { realm in
            theme.coverRadiusRatio = ratio
        }
    }
    
    private func updateCoverStyle(_ style: CoverStyle, ratio: Float) {
        let theme = Theme.defalut
        guard theme.coverRadiusRatio != ratio || theme.coverStyle != style else { return }
        Theme.change { realm in
            theme.coverStyle = style
            theme.coverRadiusRatio = ratio
        }
    }
    
    private func updateCoverForceSquare(_ forceSquare: Bool) {
        let theme = Theme.defalut
        guard theme.forceSquare != forceSquare else { return }
        Theme.change { realm in
            theme.forceSquare = forceSquare
        }
    }
    
    private func updateGameTitle(_ hideGameTitle: Bool) {
        let theme = Theme.defalut
        guard theme.hideGameTitle != hideGameTitle else { return }
        Theme.change { realm in
            theme.hideGameTitle = hideGameTitle
        }
    }
    
}
