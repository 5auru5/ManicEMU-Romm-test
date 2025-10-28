//
//  AddTriggerButtonStyleCell.swift
//  ManicEmu
//
//  Created by Daiuno on 2025/10/22.
//  Copyright © 2025 Manic EMU. All rights reserved.
//

import BetterSegmentedControl
import IceCream

class AddTriggerButtonStyleCell: UICollectionViewCell {
    
    class ButtonView: UIView {
        var style: TriggerItem.Style = .classic {
            didSet {
                triggerButton.style = style
                titleTextField.isUserInteractionEnabled = (style != .custom)
            }
        }
        var buttonSize: CGSize = TriggerItem.Style.classic.defaultSize {
            didSet {
                triggerButton.buttonSize = buttonSize
                triggerButton.snp.updateConstraints { make in
                    make.size.equalTo(buttonSize)
                }
            }
        }
        //0-1
        var buttonOpacity: CGFloat = 1 {
            didSet {
                triggerButton.buttonOpacity = buttonOpacity
            }
        }
        var buttonRadius: CGFloat = Constants.Size.CornerRadiusMid {
            didSet {
                guard style == .custom else { return }
                triggerButton.buttonCornerRadius = buttonRadius
            }
        }
        var buttonText: String = "M" {
            didSet {
                guard style != .custom else { return }
                triggerButton.title = buttonText
            }
        }
        
        var didButtonTextChange: ((String)->Void)? = nil
        var didImageChange: ((UIImage?)->Void)? = nil
        
        private let triggerButton: TriggerButton = {
            let view = TriggerButton(style: .classic,
                                     title: "M",
                                     buttonSize: TriggerItem.Style.classic.defaultSize,
                                     buttonCornerRadius: 0,
                                     buttonOpacity: 1,
                                     isEditMode: true)
            return view
        }()
        
        private lazy var uploadImageMenuButton: ContextMenuButton = {
            //点击选择封面照片
            var titles = [R.string.localizable.readyEditCoverTakePhoto(),
                              R.string.localizable.readyEditCoverAlbum(),
                              R.string.localizable.readyEditCoverFile()]
            
            var symbols: [SFSymbol] = [.camera, .photoOnRectangleAngled, .folder]
            var actions: [UIMenuElement] = []
            for (index, title) in titles.enumerated() {
                let action = UIAction(title: title, image: .symbolImage(symbols[index])) { [weak self] _ in
                    guard let self = self else { return }
                    if index == 0 {
                        //拍摄
                        ImageFetcher.capture { [weak self] image in
                            self?.triggerButton.image = image
                            self?.didImageChange?(image)
                        }
                    } else if index == 1 {
                        //相册
                        ImageFetcher.pick { [weak self] image in
                            self?.triggerButton.image = image
                            self?.didImageChange?(image)
                        }
                    } else if index == 2 {
                        //文件
                        ImageFetcher.file { [weak self] image in
                            self?.triggerButton.image = image
                            self?.didImageChange?(image)
                        }
                    }
                }
                actions.append(action)
            }
            let view = ContextMenuButton(image: nil, menu: UIMenu(children: actions))
            return view
        }()
        
        private lazy var editButton: SymbolButton = {
            let view = SymbolButton(image: R.image.customPencilLine()?.applySymbolConfig(font: Constants.Font.title(size: .s, weight: .regular)))
            view.enableRoundCorner = true
            view.backgroundColor = Constants.Color.BackgroundPrimary
            view.addTapGesture { [weak self] gesture in
                guard let self = self else { return }
                if self.style == .custom {
                    //上传照片
                    self.uploadImageMenuButton.triggerTapGesture()
                } else {
                    self.titleTextField.becomeFirstResponder()
                }
            }
            return view
        }()
        
        private lazy var titleTextField: UITextField = {
            let textField = UITextField()
            textField.textAlignment = .center
            textField.textColor = .clear
            textField.font = style.getFont(buttonSize: buttonSize)
            textField.text = "M"
            textField.clearButtonMode = .never
            textField.returnKeyType = .done
            textField.onReturnKeyPress { [weak self, weak textField] in
                guard let self = self else { return }
                textField?.resignFirstResponder()
            }
            textField.onChange { [weak textField, weak self] text in
                guard let self else { return }
                if text.count > 1 {
                    if let markRange = textField?.markedTextRange, let _ = textField?.position(from: markRange.start, offset: 0) { } else {
                        textField?.text = String(text.prefix(1))
                    }
                }
                let title = textField?.text?.uppercased() ?? ""
                self.triggerButton.title = title
                self.didButtonTextChange?(title)
            }
            return textField
        }()
        
        override init(frame: CGRect) {
            super.init(frame: .zero)
            backgroundColor = Constants.Color.Background
            layerCornerRadius = Constants.Size.CornerRadiusMax
            
            addSubview(triggerButton)
            triggerButton.snp.makeConstraints { make in
                make.center.equalToSuperview()
                make.size.equalTo(buttonSize)
            }
            
            addSubview(editButton)
            editButton.snp.makeConstraints { make in
                make.size.equalTo(Constants.Size.ItemHeightUltraTiny)
                make.trailing.top.equalToSuperview().inset(Constants.Size.ContentSpaceTiny)
            }
            
            insertSubview(uploadImageMenuButton, belowSubview: editButton)
            uploadImageMenuButton.snp.makeConstraints { make in
                make.edges.equalTo(editButton)
            }
            
            addSubview(titleTextField)
            titleTextField.snp.makeConstraints { make in
                make.edges.equalTo(triggerButton).inset(Constants.Size.ContentSpaceTiny)
            }
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
    }
    
    class SliderView: UIView {
        private var titleLabel: UILabel = {
            let label = UILabel()
            label.font = Constants.Font.body(size: .l)
            label.textColor = Constants.Color.LabelPrimary
            return label
        }()
        
        private var detailLabel: UILabel = {
            let label = UILabel()
            label.font = Constants.Font.body(size: .s)
            label.textColor = Constants.Color.LabelSecondary
            return label
        }()
        
        private var sliderView: UISlider = {
            let view = UISlider()
            view.minimumTrackTintColor = Constants.Color.Main
            view.maximumTrackTintColor = Constants.Color.BackgroundSecondary
            return view
        }()
        
        var didValueChange: ((CGFloat)->Void)? = nil
        var valueSufix: String?
        var value: Float = 0 {
            didSet {
                detailLabel.text = "\(value)" + (valueSufix ?? "")
                sliderView.value = value
            }
        }
        
        init(title: String, valueSufix: String?, minimumValue: Float, maximumValue: Float, numberOfDecimalPlaces: Int = 0) {
            self.valueSufix = valueSufix
            super.init(frame: .zero)
            
            addSubview(titleLabel)
            titleLabel.snp.makeConstraints { make in
                make.leading.top.equalToSuperview()
            }
            
            addSubview(detailLabel)
            detailLabel.snp.makeConstraints { make in
                make.leading.equalTo(titleLabel.snp.trailing).offset(Constants.Size.ContentSpaceUltraTiny)
                make.bottom.equalTo(titleLabel)
            }
            
            addSubview(sliderView)
            sliderView.snp.makeConstraints { make in
                make.top.equalTo(titleLabel.snp.bottom).offset(Constants.Size.ContentSpaceUltraTiny)
                make.leading.trailing.equalToSuperview()
                make.height.equalTo(28)
            }
            
            titleLabel.text = title
            detailLabel.text = "\(value)" + (valueSufix ?? "")
            sliderView.minimumValue = minimumValue
            sliderView.maximumValue = maximumValue
            
            sliderView.on(.valueChanged) { [weak self] sender, forEvent in
                guard let self = self else { return }
                let value = self.sliderView.value.rounded(numberOfDecimalPlaces: numberOfDecimalPlaces, rule: .toNearestOrEven)
                self.didValueChange?(CGFloat(value))
                self.detailLabel.text = "\(value)" + (self.valueSufix ?? "")
            }
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
    
    private lazy var segmentView: BetterSegmentedControl = {
        let titles = [
            R.string.localizable.classic(),
            R.string.localizable.flat(),
            R.string.localizable.custom()
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
    
    private var triggerButtonView: ButtonView = {
        let view = ButtonView()
        return view
    }()
    
    private var sizeSliderView: SliderView = {
        let defaultStyle = TriggerItem.Style.classic
        let view = SliderView(title: R.string.localizable.size() + ":",
                              valueSufix: nil,
                              minimumValue: defaultStyle.sizeRange.min,
                              maximumValue: defaultStyle.sizeRange.max,
                              numberOfDecimalPlaces: 1)
        return view
    }()
    
    private var opacitySliderView: SliderView = {
        let defaultStyle = TriggerItem.Style.classic
        let view = SliderView(title: R.string.localizable.opacity() + ":",
                              valueSufix: "%",
                              minimumValue: 5,
                              maximumValue: 100)
        return view
    }()
    
    private var cornerRadiusSliderView: SliderView = {
        let view = SliderView(title: R.string.localizable.cornerRadius() + ":",
                              valueSufix: "%",
                              minimumValue: 0,
                              maximumValue: 100)
        view.isHidden = true
        return view
    }()
    
    var needToUpdateCellHeight: (()->Void)? = nil
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        layerCornerRadius = Constants.Size.CornerRadiusMax
        backgroundColor = Constants.Color.BackgroundPrimary

        addSubview(segmentView)
        segmentView.snp.makeConstraints { make in
            make.leading.top.trailing.equalToSuperview().inset(Constants.Size.ContentSpaceMid)
            make.height.equalTo(Constants.Size.ItemHeightMid)
        }
        
        addSubview(triggerButtonView)
        triggerButtonView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(Constants.Size.ContentSpaceMid)
            make.top.equalTo(segmentView.snp.bottom).offset(Constants.Size.ContentSpaceMax)
            make.height.equalTo(120)
        }
        
        addSubview(sizeSliderView)
        sizeSliderView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(Constants.Size.ContentSpaceHuge)
            make.top.equalTo(triggerButtonView.snp.bottom).offset(Constants.Size.ContentSpaceMax)
            make.height.equalTo(50)
        }
        
        addSubview(opacitySliderView)
        opacitySliderView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(Constants.Size.ContentSpaceHuge)
            make.top.equalTo(sizeSliderView.snp.bottom).offset(Constants.Size.ContentSpaceMax)
            make.height.equalTo(50)
        }
        
        addSubview(cornerRadiusSliderView)
        cornerRadiusSliderView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(Constants.Size.ContentSpaceHuge)
            make.top.equalTo(opacitySliderView.snp.bottom).offset(Constants.Size.ContentSpaceMax)
            make.height.equalTo(50)
        }
    }
    
    func setData(item: TriggerItem) {
        //segmentView
        segmentView.setIndex(item.style.rawValue)
        segmentView.on(.valueChanged) { [weak self] sender, forEvent in
            guard let self = self, let index = (sender as? BetterSegmentedControl)?.index else { return }
            UIDevice.generateHaptic()
            if let style = TriggerItem.Style(rawValue: index) {
                guard item.style != style else { return }
                item.style = style
                item.buttonWidth = style.defaultSize.width
                item.buttonHeight = style.defaultSize.height
                item.buttonOpacity = 1
                item.buttonCornerRadiusRatio = 26.7
                self.triggerButtonView.style = style
                switch style {
                case .classic, .flat:
                    cornerRadiusSliderView.isHidden = true
                case .custom:
                    cornerRadiusSliderView.isHidden = false
                }
                self.needToUpdateCellHeight?()
            }
        }
        
        //ButtonView
        triggerButtonView.style = item.style
        triggerButtonView.buttonSize = item.buttonSize
        triggerButtonView.buttonOpacity = item.buttonOpacity
        if item.style == .custom {
            triggerButtonView.buttonRadius = item.buttonCornerRadius
        } else {
            triggerButtonView.buttonRadius = 0
            triggerButtonView.buttonText = item.buttonText
        }
        triggerButtonView.didButtonTextChange = { title in
            item.buttonText = title
        }
        triggerButtonView.didImageChange = { image in
            if let image, let imageData = image.jpegData(compressionQuality: 0.7) {
                if let oldCustomImage = item.customImage {
                    if let _ = oldCustomImage.realm {
                        oldCustomImage.deleteAndClean(realm: Database.realm)
                    } else {
                        try? FileManager.safeRemoveItem(at: oldCustomImage.filePath)
                    }
                }
                item.customImage = CreamAsset.create(objectID: "\(PersistedKit.incrementID)", propName: "customImage", data: imageData)
            }
        }
        
        //sizeSliderView
        sizeSliderView.value = Float(item.buttonWidth)
        sizeSliderView.didValueChange = { [weak self] size in
            guard let self else { return }
            item.buttonWidth = Double(size).rounded(numberOfDecimalPlaces: 1, rule: .toNearestOrEven)
            item.buttonHeight = item.buttonWidth
            self.triggerButtonView.buttonSize = .init(CGFloat(size))
            if item.style == .custom {
                self.triggerButtonView.buttonRadius = item.buttonCornerRadius
            }
        }
        
        //opacitySliderView
        opacitySliderView.value = Float(item.buttonOpacity*100)
        opacitySliderView.didValueChange = { [weak self] opacity in
            guard let self else { return }
            let opacity = opacity/100
            item.buttonOpacity = Double(opacity).rounded(numberOfDecimalPlaces: 1, rule: .toNearestOrEven)
            self.triggerButtonView.buttonOpacity = opacity
        }
        
        //cornerRadiusSliderView
        if item.style == .custom {
            cornerRadiusSliderView.isHidden = false
            cornerRadiusSliderView.value = Float(item.buttonCornerRadiusRatio)
            cornerRadiusSliderView.didValueChange = { [weak self] cornerRadiusRatio in
                guard let self else { return }
                item.buttonCornerRadiusRatio = Double(cornerRadiusRatio).rounded(numberOfDecimalPlaces: 1, rule: .toNearestOrEven)
                self.triggerButtonView.buttonRadius = item.buttonCornerRadius
            }
        } else {
            cornerRadiusSliderView.isHidden = true
            cornerRadiusSliderView.didValueChange = nil
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
