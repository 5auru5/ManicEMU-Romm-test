//
//  DeadZoneControl.swift
//  ManicEmu
//
//  Created by Daiuno on 2025/8/6.
//  Copyright © 2025 Manic EMU. All rights reserved.
//
// SPDX-License-Identifier: AGPL-3.0-or-later

import UIKit
import ProHUD
import IQKeyboardManagerSwift
import ManicEmuCore

class DeadZoneControl: UIView, UITextFieldDelegate {

    // MARK: - Private UI
    private let minusButton: SymbolButton = {
        let view = SymbolButton(image: UIImage(symbol: .minus, font: Constants.Font.body(size: .m, weight: .bold)), enableGlass: true)
        view.enableRoundCorner = true
        return view
    }()
    private let plusButton: SymbolButton = {
        let view = SymbolButton(image: UIImage(symbol: .plus, font: Constants.Font.body(size: .m, weight: .bold)), enableGlass: true)
        view.enableRoundCorner = true
        return view
    }()
    let textField = UITextField()

    // MARK: - Config
    private let step: Float = 0.1
    private let range: ClosedRange<Float> = 0.0...1.0

    // MARK: - Value
    private var internalValue: Float = 0.0 {
        didSet {
            textField.text = String(format: "%.2f", internalValue)
            if oldValue != internalValue {
                Settings.defalut.updateExtra(key: ExtraKey.deadZone.rawValue, value: internalValue)
                ExternalGameControllerUtils.shared.deadZone = internalValue
            }
        }
    }
    
    deinit {
        Task { @MainActor in
            IQKeyboardManager.shared.isEnabled = false
        }
    }

    // MARK: - Init
    init(initialValue: Float = 0.0) {
        super.init(frame: .zero)
        internalValue = Settings.defalut.getExtraFloat(key: ExtraKey.deadZone.rawValue) ?? 0
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    // MARK: - UI Setup
    private func setupUI() {
        IQKeyboardManager.shared.isEnabled = true
        IQKeyboardManager.shared.keyboardDistance = Constants.Size.ContentSpaceHuge
        
        // Minus Button
        minusButton.addTapGesture { [weak self] gesture in
            guard let self else { return }
            self.decreaseValue()
        }

        // Plus Button
        plusButton.addTapGesture { [weak self] gesture in
            guard let self else { return }
            self.increaseValue()
        }

        // Text Field
        textField.tintColor = Constants.Color.Main
        textField.textColor = Constants.Color.LabelPrimary
        textField.font = Constants.Font.body()
        textField.layerCornerRadius = Constants.Size.CornerRadiusMid
        textField.layerBorderColor = Constants.Color.Border
        textField.keyboardType = .decimalPad
        textField.textAlignment = .center
        textField.delegate = self
        textField.text = String(format: "%.2f", Settings.defalut.getExtraFloat(key: ExtraKey.deadZone.rawValue) ?? 0)

        // Layout
        let stack = UIStackView(arrangedSubviews: [minusButton, textField, plusButton])
        
        minusButton.snp.makeConstraints({ make in
            make.height.equalTo(Constants.Size.ItemHeightTiny)
        })
        textField.snp.makeConstraints({ make in
            make.height.equalTo(Constants.Size.ItemHeightTiny)
        })
        plusButton.snp.makeConstraints({ make in
            make.height.equalTo(Constants.Size.ItemHeightTiny)
        })

        
        stack.axis = .horizontal
        stack.spacing = 8
        stack.alignment = .center
        stack.distribution = .fillEqually

        addSubview(stack)
        stack.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    // MARK: - Actions
    @objc private func decreaseValue() {
        updateValue(internalValue - step)
    }

    @objc private func increaseValue() {
        updateValue(internalValue + step)
    }

    private func updateValue(_ newValue: Float) {
        internalValue = min(max(newValue, range.lowerBound), range.upperBound)
    }

    // MARK: - UITextFieldDelegate
    func textFieldDidEndEditing(_ textField: UITextField) {
        guard let text = textField.text,
              let floatVal = Float(text),
              range.contains(floatVal)
        else {
            // 恢复为原来的合法值
            textField.text = String(format: "%.2f", internalValue)
            return
        }

        internalValue = floatVal
    }

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let allowed = CharacterSet(charactersIn: "0123456789.")
        if string.rangeOfCharacter(from: allowed.inverted) != nil {
            return false
        }

        let current = textField.text ?? ""
        
        if current.isEmpty , string == "." {
            textField.text = "0"
        }
        
        if current == "0", string != ".", !string.isEmpty {
            return false
        }
        
        if current.isEmpty, let value = Float(string), value > 1 {
            return false
        }
        
        if let textRange = Range(range, in: current) {
            let updated = current.replacingCharacters(in: textRange, with: string)
            // 只允许一个小数点
            let decimalCount = updated.filter { $0 == "." }.count
            return decimalCount <= 1
        }

        return true
    }
    
    static func show() {
        Sheet { sheet in
            let deadZoneControl = DeadZoneControl()
            
            sheet.contentMaskView.alpha = 0
            sheet.config.windowEdgeInset = 0
            sheet.onTappedBackground { sheet in
                if deadZoneControl.textField.isFirstResponder {
                    deadZoneControl.textField.resignFirstResponder()
                } else {
                    sheet.pop()
                }
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
                        if deadZoneControl.textField.isFirstResponder {
                            deadZoneControl.textField.resignFirstResponder()
                        } else {
                            sheet.pop()
                        }
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
            titleLabel.textAlignment = .center
            titleLabel.text = R.string.localizable.deadZoneSetting()
            titleLabel.font = Constants.Font.title(size: .s, weight: .semibold)
            titleLabel.textColor = Constants.Color.LabelPrimary
            containerView.addSubview(titleLabel)
            titleLabel.snp.makeConstraints { make in
                make.centerX.equalToSuperview()
                make.top.equalToSuperview().offset(30)
            }
            
            let detailLabel = UILabel()
            detailLabel.numberOfLines = 0
            detailLabel.text = R.string.localizable.deadZoneDesc()
            detailLabel.font = Constants.Font.body(size: .s)
            detailLabel.textColor = Constants.Color.LabelSecondary
            containerView.addSubview(detailLabel)
            detailLabel.snp.makeConstraints { make in
                make.leading.trailing.equalToSuperview().inset(Constants.Size.ContentSpaceHuge)
                make.top.equalTo(titleLabel.snp.bottom).offset(Constants.Size.ContentSpaceMin)
            }
            
            
            containerView.addSubview(deadZoneControl)
            deadZoneControl.snp.makeConstraints { make in
                make.width.equalTo(250)
                make.centerX.equalToSuperview()
                make.top.equalTo(detailLabel.snp.bottom).offset(Constants.Size.ContentSpaceMax)
                make.height.equalTo(Constants.Size.ItemHeightTiny)
                make.bottom.equalToSuperview().offset(-Constants.Size.ContentInsetBottom-Constants.Size.ContentSpaceMax)
            }
            
            sheet.set(customView: view).snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
        }
    }
}
