//
//  TriggerProActionSettingViews.swift
//  ManicEmu
//
//  Created by Daiuno on 2025/10/22.
//  Copyright © 2025 Manic EMU. All rights reserved.
//

import ProHUD

class TriggerActionSimpleView: UIView {
    private var repeatIconView: UIImageView = {
        let view = UIImageView()
        view.backgroundColor = Constants.Color.Main
        view.contentMode = .center
        view.layerCornerRadius = 6
        view.image = UIImage(symbol: .repeat, font: Constants.Font.body(size: .s, weight: .medium), color: Constants.Color.LabelPrimary.forceStyle(.dark))
        return view
    }()
    
    private var repeatTitleLabel: UILabel = {
        let label = UILabel()
        label.text = R.string.localizable.repeatTrigger()
        label.font = Constants.Font.body(size: .l, weight: .semibold)
        label.textColor = Constants.Color.LabelPrimary
        return label
    }()
    
    var repeatSwitchButton: DisabledTapSwitch = {
        let view = DisabledTapSwitch()
        view.onTintColor = Constants.Color.Main
        view.tintColor = Constants.Color.BackgroundSecondary
        return view
    }()
    
    private var intervalIconView: UIImageView = {
        let view = UIImageView()
        view.backgroundColor = Constants.Color.Main
        view.contentMode = .center
        view.layerCornerRadius = 6
        view.image = R.image.customClockArrowTriangleheadCounterclockwiseRotate90()?.applySymbolConfig(font: Constants.Font.body(size: .s, weight: .medium), color: Constants.Color.LabelPrimary.forceStyle(.dark))
        return view
    }()
    
    private var intervalTitleLabel: UILabel = {
        let label = UILabel()
        label.text = R.string.localizable.repeatInterval()
        label.font = Constants.Font.body(size: .l, weight: .semibold)
        label.textColor = Constants.Color.LabelPrimary
        return label
    }()
    
    var intervalValueButton: SymbolButton = {
        let view = SymbolButton(image: UIImage(symbol: .chevronRight,
                                               font: Constants.Font.caption(size: .l, weight: .bold),
                                               color: Constants.Color.BackgroundSecondary),
                                title: "",
                                titleFont: Constants.Font.caption(size: .l),
                                titleColor: Constants.Color.LabelSecondary,
                                titleAlignment: .left,
                                edgeInsets: .init(inset: Constants.Size.ContentSpaceUltraTiny),
                                titlePosition: .left,
                                imageAndTitlePadding: Constants.Size.ContentSpaceUltraTiny,
                                enableGlass: false)
        view.backgroundColor = .clear
        return view
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = Constants.Color.Background
        layerCornerRadius = Constants.Size.CornerRadiusMid
        
        addSubview(repeatIconView)
        repeatIconView.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(18)
            make.leading.equalToSuperview().inset(Constants.Size.ContentSpaceMid)
            make.size.equalTo(24)
        }
        
        addSubview(repeatTitleLabel)
        repeatTitleLabel.snp.makeConstraints { make in
            make.centerY.equalTo(repeatIconView)
            make.leading.equalTo(repeatIconView.snp.trailing).offset(Constants.Size.ContentSpaceMin)
        }
        
        addSubview(repeatSwitchButton)
        repeatSwitchButton.snp.makeConstraints { make in
            make.centerY.equalTo(repeatIconView)
            make.leading.equalTo(repeatTitleLabel.snp.trailing).offset(Constants.Size.ContentSpaceMin)
            make.trailing.equalToSuperview().inset(Constants.Size.ContentSpaceMid)
            if #available(iOS 26.0, *) {
                make.size.equalTo(CGSize(width: 63, height: 28))
            } else {
                make.size.equalTo(CGSize(width: 51, height: 31))
            }
        }
        if #available(iOS 26.0, *) {} else {
            repeatSwitchButton.transform = CGAffineTransformMakeScale(0.9, 0.9)
        }
        
        addSubview(intervalIconView)
        intervalIconView.snp.makeConstraints { make in
            make.top.equalTo(repeatIconView.snp.bottom).offset(36)
            make.leading.equalToSuperview().inset(Constants.Size.ContentSpaceMid)
            make.size.equalTo(24)
        }
        
        addSubview(intervalTitleLabel)
        intervalTitleLabel.snp.makeConstraints { make in
            make.centerY.equalTo(intervalIconView)
            make.leading.equalTo(intervalIconView.snp.trailing).offset(Constants.Size.ContentSpaceMin)
        }
        
        addSubview(intervalValueButton)
        intervalValueButton.snp.makeConstraints { make in
            make.centerY.equalTo(intervalIconView)
            make.leading.greaterThanOrEqualTo(intervalTitleLabel.snp.trailing).offset(Constants.Size.ContentSpaceMin)
            make.trailing.equalToSuperview().inset(Constants.Size.ContentSpaceMid)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class TriggerActionHoldView: UIView {
    private var autoStopIconView: UIImageView = {
        let view = UIImageView()
        view.backgroundColor = Constants.Color.Main
        view.contentMode = .center
        view.layerCornerRadius = 6
        view.image = UIImage(symbol: .stopCircle, font: Constants.Font.body(size: .s, weight: .medium), color: Constants.Color.LabelPrimary.forceStyle(.dark))
        return view
    }()
    
    private var autoStopTitleLabel: UILabel = {
        let label = UILabel()
        label.text = R.string.localizable.autoStop()
        label.font = Constants.Font.body(size: .l, weight: .semibold)
        label.textColor = Constants.Color.LabelPrimary
        return label
    }()
    
    var autoStopSwitchButton: DisabledTapSwitch = {
        let view = DisabledTapSwitch()
        view.onTintColor = Constants.Color.Main
        view.tintColor = Constants.Color.BackgroundSecondary
        return view
    }()
    
    private var durationIconView: UIImageView = {
        let view = UIImageView()
        view.backgroundColor = Constants.Color.Main
        view.contentMode = .center
        view.layerCornerRadius = 6
        view.image = UIImage(symbol: .timer, font: Constants.Font.body(size: .s, weight: .medium), color: Constants.Color.LabelPrimary.forceStyle(.dark))
        return view
    }()
    
    private var durationTitleLabel: UILabel = {
        let label = UILabel()
        label.text = R.string.localizable.holdDuration()
        label.font = Constants.Font.body(size: .l, weight: .semibold)
        label.textColor = Constants.Color.LabelPrimary
        return label
    }()
    
    var durationValueButton: SymbolButton = {
        let view = SymbolButton(image: UIImage(symbol: .chevronRight,
                                               font: Constants.Font.caption(size: .l, weight: .bold),
                                               color: Constants.Color.BackgroundSecondary),
                                title: "",
                                titleFont: Constants.Font.caption(size: .l),
                                titleColor: Constants.Color.LabelSecondary,
                                titleAlignment: .left,
                                edgeInsets: .init(inset: Constants.Size.ContentSpaceUltraTiny),
                                titlePosition: .left,
                                imageAndTitlePadding: Constants.Size.ContentSpaceUltraTiny,
                                enableGlass: false)
        view.backgroundColor = .clear
        return view
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = Constants.Color.Background
        layerCornerRadius = Constants.Size.CornerRadiusMid
        
        addSubview(autoStopIconView)
        autoStopIconView.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(18)
            make.leading.equalToSuperview().inset(Constants.Size.ContentSpaceMid)
            make.size.equalTo(24)
        }
        
        addSubview(autoStopTitleLabel)
        autoStopTitleLabel.snp.makeConstraints { make in
            make.centerY.equalTo(autoStopIconView)
            make.leading.equalTo(autoStopIconView.snp.trailing).offset(Constants.Size.ContentSpaceMin)
        }
        
        addSubview(autoStopSwitchButton)
        autoStopSwitchButton.snp.makeConstraints { make in
            make.centerY.equalTo(autoStopIconView)
            make.leading.equalTo(autoStopTitleLabel.snp.trailing).offset(Constants.Size.ContentSpaceMin)
            make.trailing.equalToSuperview().inset(Constants.Size.ContentSpaceMid)
            if #available(iOS 26.0, *) {
                make.size.equalTo(CGSize(width: 63, height: 28))
            } else {
                make.size.equalTo(CGSize(width: 51, height: 31))
            }
        }
        if #available(iOS 26.0, *) {} else {
            autoStopSwitchButton.transform = CGAffineTransformMakeScale(0.9, 0.9)
        }
        
        addSubview(durationIconView)
        durationIconView.snp.makeConstraints { make in
            make.top.equalTo(autoStopIconView.snp.bottom).offset(36)
            make.leading.equalToSuperview().inset(Constants.Size.ContentSpaceMid)
            make.size.equalTo(24)
        }
        
        addSubview(durationTitleLabel)
        durationTitleLabel.snp.makeConstraints { make in
            make.centerY.equalTo(durationIconView)
            make.leading.equalTo(durationIconView.snp.trailing).offset(Constants.Size.ContentSpaceMin)
        }
        
        addSubview(durationValueButton)
        durationValueButton.snp.makeConstraints { make in
            make.centerY.equalTo(durationIconView)
            make.leading.greaterThanOrEqualTo(durationTitleLabel.snp.trailing).offset(Constants.Size.ContentSpaceMin)
            make.trailing.equalToSuperview().inset(Constants.Size.ContentSpaceMid)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class TriggerActionComboView: UIView {
    private var durationPerKeyIconView: UIImageView = {
        let view = UIImageView()
        view.backgroundColor = Constants.Color.Main
        view.contentMode = .center
        view.layerCornerRadius = 6
        view.image = UIImage(symbol: .timer, font: Constants.Font.body(size: .s, weight: .medium), color: Constants.Color.LabelPrimary.forceStyle(.dark))
        return view
    }()
    
    private var durationPerKeyTitleLabel: UILabel = {
        let label = UILabel()
        label.text = R.string.localizable.pressDurationPerKey()
        label.font = Constants.Font.body(size: .l, weight: .semibold)
        label.textColor = Constants.Color.LabelPrimary
        return label
    }()
    
    var durationPerKeyValueButton: SymbolButton = {
        let view = SymbolButton(image: UIImage(symbol: .chevronRight,
                                               font: Constants.Font.caption(size: .l, weight: .bold),
                                               color: Constants.Color.BackgroundSecondary),
                                title: "",
                                titleFont: Constants.Font.caption(size: .l),
                                titleColor: Constants.Color.LabelSecondary,
                                titleAlignment: .left,
                                edgeInsets: .init(inset: Constants.Size.ContentSpaceUltraTiny),
                                titlePosition: .left,
                                imageAndTitlePadding: Constants.Size.ContentSpaceUltraTiny,
                                enableGlass: false)
        view.backgroundColor = .clear
        return view
    }()
    
    private var intervalPerKeyIconView: UIImageView = {
        let view = UIImageView()
        view.backgroundColor = Constants.Color.Main
        view.contentMode = .center
        view.layerCornerRadius = 6
        view.image = R.image.customClockArrowTriangleheadCounterclockwiseRotate90()?.applySymbolConfig(font: Constants.Font.body(size: .s, weight: .medium), color: Constants.Color.LabelPrimary.forceStyle(.dark))
        return view
    }()
    
    private var intervalPerKeyTitleLabel: UILabel = {
        let label = UILabel()
        label.text = R.string.localizable.intervalPerKey()
        label.font = Constants.Font.body(size: .l, weight: .semibold)
        label.textColor = Constants.Color.LabelPrimary
        return label
    }()
    
    var intervalPerKeyValueButton: SymbolButton = {
        let view = SymbolButton(image: UIImage(symbol: .chevronRight,
                                               font: Constants.Font.caption(size: .l, weight: .bold),
                                               color: Constants.Color.BackgroundSecondary),
                                title: "",
                                titleFont: Constants.Font.caption(size: .l),
                                titleColor: Constants.Color.LabelSecondary,
                                titleAlignment: .left,
                                edgeInsets: .init(inset: Constants.Size.ContentSpaceUltraTiny),
                                titlePosition: .left,
                                imageAndTitlePadding: Constants.Size.ContentSpaceUltraTiny,
                                enableGlass: false)
        view.backgroundColor = .clear
        return view
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = Constants.Color.Background
        layerCornerRadius = Constants.Size.CornerRadiusMid
        
        addSubview(durationPerKeyIconView)
        durationPerKeyIconView.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(18)
            make.leading.equalToSuperview().inset(Constants.Size.ContentSpaceMid)
            make.size.equalTo(24)
        }
        
        addSubview(durationPerKeyTitleLabel)
        durationPerKeyTitleLabel.snp.makeConstraints { make in
            make.centerY.equalTo(durationPerKeyIconView)
            make.leading.equalTo(durationPerKeyIconView.snp.trailing).offset(Constants.Size.ContentSpaceMin)
        }
        
        addSubview(durationPerKeyValueButton)
        durationPerKeyValueButton.snp.makeConstraints { make in
            make.centerY.equalTo(durationPerKeyIconView)
            make.leading.greaterThanOrEqualTo(durationPerKeyTitleLabel.snp.trailing).offset(Constants.Size.ContentSpaceMin)
            make.trailing.equalToSuperview().inset(Constants.Size.ContentSpaceMid)
        }
        
        addSubview(intervalPerKeyIconView)
        intervalPerKeyIconView.snp.makeConstraints { make in
            make.top.equalTo(durationPerKeyIconView.snp.bottom).offset(36)
            make.leading.equalToSuperview().inset(Constants.Size.ContentSpaceMid)
            make.size.equalTo(24)
        }
        
        addSubview(intervalPerKeyTitleLabel)
        intervalPerKeyTitleLabel.snp.makeConstraints { make in
            make.centerY.equalTo(intervalPerKeyIconView)
            make.leading.equalTo(intervalPerKeyIconView.snp.trailing).offset(Constants.Size.ContentSpaceMin)
        }
        
        addSubview(intervalPerKeyValueButton)
        intervalPerKeyValueButton.snp.makeConstraints { make in
            make.centerY.equalTo(intervalPerKeyIconView)
            make.leading.greaterThanOrEqualTo(intervalPerKeyTitleLabel.snp.trailing).offset(Constants.Size.ContentSpaceMin)
            make.trailing.equalToSuperview().inset(Constants.Size.ContentSpaceMid)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}


class TriggerProTimePickerView: UIView {
    static func show(title: String, values: [Double], defaultValue: Double, unitString: String, didSelectValue: ((Double)->Void)? = nil) {
        Sheet { sheet in
            sheet.contentMaskView.alpha = 0
            sheet.config.windowEdgeInset = 0
            sheet.onTappedBackground { sheet in
                sheet.pop()
            }
            sheet.config.backgroundViewMask { mask in
                mask.backgroundColor = .black.withAlphaComponent(0.2)
            }
            
            let view = UIView()
            let grabber = UIImageView(image: R.image.grabber_icon())
            grabber.isUserInteractionEnabled = true
            grabber.contentMode = .center
            view.addPanGesture { [weak view, weak sheet] gesture in
                guard let view = view, let sheet = sheet else { return }
                let point = gesture.translation(in: gesture.view)
                view.transform = .init(translationX: 0, y: point.y <= 0 ? 0 : point.y)
                if gesture.state == .recognized {
                    let v = gesture.velocity(in: gesture.view)
                    if (view.y > view.height*2/3 && v.y > 0) || v.y > 1200 {
                        sheet.pop()
                    }
                    UIView.animate(withDuration: 0.8, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0.5, options: [.allowUserInteraction, .curveEaseOut], animations: {
                        view.transform = .identity
                    })
                }
            }
            view.addSubview(grabber)
            grabber.snp.makeConstraints { make in
                make.leading.top.trailing.equalToSuperview()
                make.height.equalTo(Constants.Size.ContentSpaceTiny*3)
            }
            
            let containerView = RoundAndBorderView(roundCorner: (UIDevice.isPad || UIDevice.isLandscape) ? .allCorners : [.topLeft, .topRight])
            containerView.backgroundColor = Constants.Color.Background
            containerView.makeBlur()
            view.addSubview(containerView)
            containerView.snp.makeConstraints { make in
                make.top.equalTo(grabber.snp.bottom)
                make.leading.bottom.trailing.equalToSuperview()
            }
            
            let titleLabel = UILabel()
            titleLabel.text = title
            titleLabel.font = Constants.Font.title(size: .s, weight: .semibold)
            titleLabel.textColor = Constants.Color.LabelPrimary
            containerView.addSubview(titleLabel)
            titleLabel.snp.makeConstraints { make in
                make.leading.equalToSuperview().offset(Constants.Size.ContentSpaceMax)
                make.top.equalToSuperview().offset(Constants.Size.ContentSpaceMid)
            }
            
            let closeButton = SymbolButton(image: UIImage(symbol: .xmark, font: Constants.Font.body(weight: .bold)))
            closeButton.addTapGesture { [weak sheet] gesture in
                sheet?.pop()
            }
            closeButton.enableRoundCorner = true
            containerView.addSubview(closeButton)
            closeButton.snp.makeConstraints { make in
                make.leading.equalTo(titleLabel.snp.trailing).offset(Constants.Size.ContentSpaceMid)
                make.centerY.equalTo(titleLabel)
                make.size.equalTo(Constants.Size.IconSizeMid)
                make.trailing.equalToSuperview().offset(-Constants.Size.ContentSpaceMax)
            }
            
            
            let selectionView = UIPickerView()
            selectionView.addComponents([values.map({ "\($0.rounded(numberOfDecimalPlaces: 1, rule: .toNearestOrEven))\(unitString)"})]) { element, component, row in
                didSelectValue?(values[row])
            }
            if let defaultRow = values.firstIndex(of: defaultValue) {
                DispatchQueue.main.asyncAfter(delay: 0.35, execute: {
                    selectionView.selectRow(defaultRow, inComponent: 0, animated: true)
                })
            }
            
            containerView.addSubview(selectionView)
            selectionView.snp.makeConstraints { make in
                make.top.equalTo(titleLabel.snp.bottom).offset(Constants.Size.ContentSpaceMax)
                make.leading.trailing.equalToSuperview()
                make.height.equalTo(350)
                make.bottom.equalToSuperview()
            }
            
            sheet.set(customView: view).snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
        }
    }
}
