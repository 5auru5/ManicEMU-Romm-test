//
//  ColorPickerView.swift
//  ManicEmu
//
//  Created by Daiuno on 2025/5/6.
//  Copyright © 2025 Manic EMU. All rights reserved.
//
// SPDX-License-Identifier: AGPL-3.0-or-later

import ChromaColorPicker
import IQKeyboardManagerSwift

class ColorPickerView: UIView {
    private let colorPicker = ChromaColorPicker()
    private let brightnessSlider = ChromaBrightnessSlider()
    private let colorView = ThemeColorCollectionViewCell.ColorView()
    private var textField: UITextField = {
        let view = UITextField()
        view.textColor = Constants.Color.LabelPrimary
        view.font = Constants.Font.body(size: .l)
        view.clearButtonMode = .whileEditing
        view.attributedPlaceholder = NSAttributedString(string: Constants.Color.Main.hexString, attributes: [.font: Constants.Font.body(size: .l), .foregroundColor: Constants.Color.LabelSecondary])
        return view
    }()
    private var addButton: SymbolButton = {
        let view = SymbolButton(image: UIImage(symbol: .plus, font: Constants.Font.title()), enableGlass: true)
        view.backgroundColor = Constants.Color.BackgroundPrimary
        view.enableRoundCorner = true
        return view
    }()
    private var topBlurView: UIView = {
        let view = UIView()
        view.makeBlur()
        return view
    }()
    private lazy var closeButton: SymbolButton = {
        let view = SymbolButton(image: UIImage(symbol: .xmark, font: Constants.Font.body(weight: .bold)), enableGlass: true)
        view.enableRoundCorner = true
        view.addTapGesture { [weak self] gesture in
            guard let self = self else { return }
            self.didTapClose?()
        }
        return view
    }()
    private lazy var saveButton: HowToButton = {
        let view = HowToButton(title: R.string.localizable.saveTitle(), enableGlass: true) { [weak self] in
            guard let self = self else { return }
            if var themeColor = self.themeColor {
                //编辑
                themeColor.colors = self.colorPicker.handles.map({ $0.color.hexString })
                self.didSaveAction?(themeColor)
            } else {
                //新增
                let themeColor = ThemeColor(timestamp: Date.now.timeIntervalSince1970ms, colors: self.colorPicker.handles.map({ $0.color.hexString }), isSelect: false, system: false)
                self.didSaveAction?(themeColor)
            }
            self.didTapClose?()
        }
        return view
    }()

    
    ///点击关闭按钮回调
    var didTapClose: (()->Void)? = nil
    //点击保存回调
    var didSaveAction: ((ThemeColor)->Void)? = nil
    
    private var themeColor: ThemeColor? = nil
    
    deinit {
        Log.debug("\(String(describing: Self.self)) deinit")
        Task {
            await MainActor.run {
                IQKeyboardManager.shared.isEnabled = false
            }
        }
    }
    
    init(color: ThemeColor? = nil) {
        super.init(frame: .zero)
        
        themeColor = color
        
        Log.debug("\(String(describing: Self.self)) init")
        colorPicker.delegate = self
        colorPicker.borderColor = Constants.Color.BackgroundPrimary
        addSubview(colorPicker)
        colorPicker.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().offset(-Constants.Size.ItemHeightHuge)
            make.size.equalTo(320)
        }
        
        brightnessSlider.handle.borderColor = Constants.Color.BackgroundPrimary
        brightnessSlider.borderColor = Constants.Color.BackgroundPrimary
        brightnessSlider.trackColor = Constants.Color.Main
        brightnessSlider.handle.borderWidth = 2.0
        addSubview(brightnessSlider)
        brightnessSlider.snp.makeConstraints { make in
            make.width.equalTo(colorPicker).multipliedBy(0.9)
            make.height.equalTo(brightnessSlider.snp.width).multipliedBy(0.1)
            make.centerX.equalToSuperview()
            make.top.equalTo(colorPicker.snp.bottom).offset(Constants.Size.ItemHeightTiny)
        }
        
        //添加两个颜色
        if let colors = themeColor?.colors.compactMap({ UIColor(hexString: $0) }), colors.count > 0 {
            for (index, color) in colors.enumerated() {
                if index == 0 {
                    let homeHandle = colorPicker.addHandle(at: color)
                    homeHandle.accessoryView = UIImageView(image: .init(symbol: .house, font: Constants.Font.title(), color: .white))
                } else {
                    colorPicker.addHandle(at: color)
                }
            }
        } else {
            let homeHandle = colorPicker.addHandle(at: Constants.Color.Main)
            homeHandle.accessoryView = UIImageView(image: .init(symbol: .house, font: Constants.Font.title(), color: .white))
            colorPicker.addHandle(at: UIColor.random)
        }
        
        brightnessSlider.connect(to: colorPicker)
        
        colorView.selectView.isHidden = true
        colorView.animatedGradientView.setColors(colorPicker.handles.map({ $0.color }))
        addSubview(colorView)
        colorView.snp.makeConstraints { make in
            make.size.equalTo(48)
            make.leading.equalTo(brightnessSlider)
            make.top.equalTo(brightnessSlider.snp.bottom).offset(Constants.Size.ItemHeightTiny)
        }
        
        let textFieldContainer = RoundAndBorderView(roundCorner: .allCorners, radius: Constants.Size.CornerRadiusMid)
        textFieldContainer.backgroundColor = Constants.Color.InputBackground
        addSubview(textFieldContainer)
        textFieldContainer.snp.makeConstraints { make in
            make.centerY.equalTo(colorView)
            make.leading.equalTo(colorView.snp.trailing).offset(Constants.Size.ContentSpaceMax)
            make.height.equalTo(Constants.Size.ItemHeightMin)
        }
        
        textFieldContainer.addSubview(textField)
        textField.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(Constants.Size.ContentSpaceMid)
        }
        textField.onReturnKeyPress { [weak self] in
            guard let self = self else { return }
            self.textField.resignFirstResponder()
            if let hex = self.textField.text, let color = UIColor(hexString: hex), let handle = self.colorPicker.currentHandle {
                handle.color = color
                self.colorPicker.setNeedsLayout()
                self.brightnessSlider.trackColor = color
                self.colorPickerHandleDidChangeEnd(self.colorPicker)
            }
        }
        
        addSubview(addButton)
        addButton.snp.makeConstraints { make in
            make.size.equalTo(48)
            make.centerY.equalTo(colorView)
            make.leading.equalTo(textFieldContainer.snp.trailing).offset(Constants.Size.ContentSpaceMax)
            make.trailing.equalTo(brightnessSlider)
        }
        addButton.addTapGesture { [weak self] gesture in
            guard let self = self else { return }
            guard self.colorPicker.handles.count < Constants.Numbers.ThemeColorMaxCount else {
                UIView.makeToast(message: R.string.localizable.themeColorLimitToast())
                return
            }
            self.colorPicker.addHandle(at: UIColor.random)
            self.colorView.animatedGradientView.setColors(self.colorPicker.handles.map({ $0.color }))
        }
        
        addSubview(topBlurView)
        topBlurView.snp.makeConstraints { make in
            make.leading.top.trailing.equalToSuperview()
            make.height.equalTo(Constants.Size.ItemHeightMid)
        }
        
        topBlurView.addSubview(closeButton)
        closeButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-Constants.Size.ContentSpaceMax)
            make.centerY.equalToSuperview()
            make.size.equalTo(Constants.Size.ItemHeightUltraTiny)
        }
        
        topBlurView.addSubview(saveButton)
        saveButton.snp.makeConstraints { make in
            make.leading.equalTo(Constants.Size.ContentSpaceMax)
            make.centerY.equalToSuperview()
            make.height.equalTo(Constants.Size.ItemHeightUltraTiny)
        }
        
        IQKeyboardManager.shared.isEnabled = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

extension ColorPickerView: ChromaColorPickerDelegate {
    func colorPickerHandleDidChange(_ colorPicker: ChromaColorPicker, handle: ChromaColorHandle, to color: UIColor) {
        textField.text = color.hexString
    }
    
    func colorPickerHandleDidChangeEnd(_ colorPicker: ChromaColorPicker) {
        colorView.animatedGradientView.setColors(colorPicker.handles.map({ $0.color }))
    }
    
}
