//
//  AddTriggerActionCell.swift
//  ManicEmu
//
//  Created by Daiuno on 2025/10/22.
//  Copyright © 2025 Manic EMU. All rights reserved.
//

import BetterSegmentedControl

class AddTriggerActionCell: UICollectionViewCell {
    
    lazy var segmentView: BetterSegmentedControl = {
        let titles = [
            R.string.localizable.simple(),
            R.string.localizable.hold(),
            R.string.localizable.combo()
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
        return view
    }()
    
    private lazy var simpleActionView: TriggerActionSimpleView = {
        let view = TriggerActionSimpleView()
        return view
    }()
    
    private lazy var holdActionView: TriggerActionHoldView = {
        let view = TriggerActionHoldView()
        return view
    }()
    
    private lazy var comboActionView: TriggerActionComboView = {
        let view = TriggerActionComboView()
        return view
    }()
    
    var didActionTypeChange: ((TriggerItem.Action)->Void)? = nil
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        layerCornerRadius = Constants.Size.CornerRadiusMax
        backgroundColor = Constants.Color.BackgroundPrimary
        
        addSubview(segmentView)
        segmentView.snp.makeConstraints { make in
            make.leading.top.trailing.equalToSuperview().inset(Constants.Size.ContentSpaceTiny)
            make.height.equalTo(Constants.Size.ItemHeightMid)
        }
        segmentView.on(.valueChanged) { [weak self] sender, forEvent in
            guard let self = self, let index = (sender as? BetterSegmentedControl)?.index else { return }
            UIDevice.generateHaptic()
            if let action = TriggerItem.Action(rawValue: index) {
                switch action {
                case .simple:
                    simpleActionView.isHidden = false
                    holdActionView.isHidden = true
                    comboActionView.isHidden = true
                case .hold:
                    simpleActionView.isHidden = true
                    holdActionView.isHidden = false
                    comboActionView.isHidden = true
                case .combo:
                    simpleActionView.isHidden = true
                    holdActionView.isHidden = true
                    comboActionView.isHidden = false
                }
                self.didActionTypeChange?(action)
            }
        }
        
        addSubview(simpleActionView)
        simpleActionView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(Constants.Size.ContentSpaceMid)
            make.top.equalTo(segmentView.snp.bottom).offset(Constants.Size.ContentSpaceMax)
            make.height.equalTo(120)
        }
        
        holdActionView.isHidden = true
        addSubview(holdActionView)
        holdActionView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(Constants.Size.ContentSpaceMid)
            make.top.equalTo(segmentView.snp.bottom).offset(Constants.Size.ContentSpaceMax)
            make.height.equalTo(120)
        }
        
        addSubview(comboActionView)
        comboActionView.isHidden = true
        comboActionView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(Constants.Size.ContentSpaceMid)
            make.top.equalTo(segmentView.snp.bottom).offset(Constants.Size.ContentSpaceMax)
            make.height.equalTo(120)
        }
    }
    
    func setData(triggerItem: TriggerItem) {
        segmentView.setIndex(triggerItem.action.rawValue)
        
        switch triggerItem.action {
        case .simple:
            simpleActionView.isHidden = false
            holdActionView.isHidden = true
            comboActionView.isHidden = true
        case .hold:
            simpleActionView.isHidden = true
            holdActionView.isHidden = false
            comboActionView.isHidden = true
        case .combo:
            simpleActionView.isHidden = true
            holdActionView.isHidden = true
            comboActionView.isHidden = false
        }
        
        simpleActionView.repeatSwitchButton.setOn(triggerItem.simpleActionRepeat, animated: false)
        simpleActionView.repeatSwitchButton.onChange { value in
            triggerItem.simpleActionRepeat = value
        }
        simpleActionView.intervalValueButton.titleLabel.text = "\(triggerItem.simpleActionRepeatInterval)s"
        simpleActionView.intervalValueButton.addTapGesture { [weak self] gesture in
            guard let self else { return }
            //0.1-0.9s //1-60s
            let values = Array(stride(from: 0.1, through: 0.9, by: 0.1)) + Array(stride(from: 1.0, through: 60.0, by: 1.0))
            TriggerProTimePickerView.show(title: R.string.localizable.repeatInterval(),
                                          values: values,
                                          defaultValue: triggerItem.simpleActionRepeatInterval,
                                          unitString: "s",
                                          didSelectValue: { value in
                triggerItem.simpleActionRepeatInterval = value
                self.simpleActionView.intervalValueButton.titleLabel.text = "\(value)s"
            })
        }
        
        holdActionView.autoStopSwitchButton.setOn(triggerItem.holdActionAutoStop, animated: false)
        holdActionView.autoStopSwitchButton.onChange { value in
            triggerItem.holdActionAutoStop = value
        }
        holdActionView.durationValueButton.titleLabel.text = "\(triggerItem.holdActionDuration)s"
        holdActionView.durationValueButton.addTapGesture { [weak self] gesture in
            guard let self else { return }
            //0.1-0.9s 1-59s 60-3600s
            let values = Array(stride(from: 1.0, through: 0.9, by: 0.1)) + Array(stride(from: 1.0, through: 59.0, by: 1.0)) + Array(stride(from: 60.0, through: 3600.0, by: 60.0))
            TriggerProTimePickerView.show(title: R.string.localizable.holdDuration(),
                                          values: values,
                                          defaultValue: triggerItem.holdActionDuration,
                                          unitString: "s",
                                          didSelectValue: { value in
                triggerItem.holdActionDuration = value
                self.holdActionView.durationValueButton.titleLabel.text = "\(value)s"
            })
        }
        
        comboActionView.durationPerKeyValueButton.titleLabel.text = "\(triggerItem.comboActionPressDurationPerKey)ms"
        comboActionView.durationPerKeyValueButton.addTapGesture { [weak self] gesture in
            guard let self else { return }
            //16.7ms 50.0-1000ms
            let values = [16.7] + Array(stride(from: 50.0, through: 1000.0, by: 50.0))
            TriggerProTimePickerView.show(title: R.string.localizable.pressDurationPerKey(),
                                          values: values,
                                          defaultValue: triggerItem.comboActionPressDurationPerKey,
                                          unitString: "ms",
                                          didSelectValue: { value in
                triggerItem.comboActionPressDurationPerKey = value
                self.comboActionView.durationPerKeyValueButton.titleLabel.text = "\(value)ms"
            })
        }
        comboActionView.intervalPerKeyValueButton.titleLabel.text = "\(triggerItem.comboActionIntervalPerKey)ms"
        comboActionView.intervalPerKeyValueButton.addTapGesture { [weak self] gesture in
            guard let self else { return }
            //16.7ms 50.0-1000ms
            let values = [16.7] + Array(stride(from: 50.0, through: 1000.0, by: 50.0))
            TriggerProTimePickerView.show(title: R.string.localizable.intervalPerKey(),
                                          values: values,
                                          defaultValue: triggerItem.comboActionIntervalPerKey,
                                          unitString: "ms",
                                          didSelectValue: { value in
                triggerItem.comboActionIntervalPerKey = value
                self.comboActionView.intervalPerKeyValueButton.titleLabel.text = "\(value)ms"
            })
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
