//
//  LimitedTextInputView.swift
//  ManicEmu
//
//  Created by Daiuno on 2025/6/27.
//  Copyright © 2025 Manic EMU. All rights reserved.
//
// SPDX-License-Identifier: AGPL-3.0-or-later

import ProHUD
import IQKeyboardManagerSwift

struct LimitedTextInputView {
    enum LimitedType {
        case integer(min: Int, max: Int)
        case decimal(min: Double, max: Double)
        case normal(textSize: Int)
    }
    
    static func show(title: String?, detail: String?, text: String?, limitedType: LimitedType, keyboadType: UIKeyboardType = .default, confirmAction: ((_ result: Any)->Void)? = nil) {
        
        Task { @MainActor in
            IQKeyboardManager.shared.isEnabled = true
            IQKeyboardManager.shared.keyboardDistance = 150
        }
        
        Alert { alert in
            alert.config.cardCornerRadius = 0
            alert.contentMaskView.alpha = 0
            alert.config.backgroundViewMask { mask in
                mask.backgroundColor = .clear
            }
            
            let textfiledWidth = UIDevice.isPhone ? 300 : 380

            let containerView = RoundAndBorderView(roundCorner: .allCorners)
            containerView.backgroundColor = Constants.Color.Background
            
            //标题
            let titleLabel = UILabel()
            titleLabel.textAlignment = .center
            titleLabel.text = title
            titleLabel.font = Constants.Font.title(size: .s)
            titleLabel.textColor = Constants.Color.LabelPrimary
            containerView.addSubview(titleLabel)
            titleLabel.snp.makeConstraints { make in
                make.centerX.equalToSuperview()
                make.top.equalToSuperview().offset(Constants.Size.ContentSpaceMid)
                make.leading.trailing.greaterThanOrEqualToSuperview().inset(Constants.Size.ContentSpaceMid)
            }
            
            //输入框
            let textFieldContainer = RoundAndBorderView(roundCorner: .allCorners, radius: Constants.Size.CornerRadiusMid, borderColor: Constants.Color.Border, borderWidth: 1)
            textFieldContainer.backgroundColor = Constants.Color.InputBackground
            containerView.addSubview(textFieldContainer)
            textFieldContainer.snp.makeConstraints { make in
                make.height.equalTo(Constants.Size.ItemHeightMid)
                make.top.equalTo(titleLabel.snp.bottom).offset(Constants.Size.ContentSpaceMid)
                make.leading.trailing.equalToSuperview().inset(Constants.Size.ContentSpaceMid)
                make.width.equalTo(textfiledWidth)
            }
            
            let textField = UITextField()
            switch limitedType {
            case .integer(_, _):
                textField.keyboardType = .numberPad
            case .decimal(_, _):
                textField.keyboardType = .decimalPad
            case .normal(_):
                break
            }
            if keyboadType != .default {
                textField.keyboardType = keyboadType
            }
            textField.text = text
            textField.tintColor = Constants.Color.Main
            textField.textColor = Constants.Color.LabelPrimary
            textField.font = Constants.Font.body()
            textField.clearButtonMode = .whileEditing
            textFieldContainer.addSubview(textField)
            textField.snp.makeConstraints { make in
                make.top.bottom.equalToSuperview()
                make.leading.trailing.equalToSuperview().inset(Constants.Size.ContentSpaceTiny)
            }
            textField.becomeFirstResponder()
            textField.onChange { text in
                Log.debug(text)
            }
            
            let detailLabel = UILabel()
            detailLabel.numberOfLines = 0
            detailLabel.text = detail
            detailLabel.font = Constants.Font.caption()
            detailLabel.textColor = Constants.Color.LabelSecondary
            containerView.addSubview(detailLabel)
            detailLabel.snp.makeConstraints { make in
                make.leading.trailing.equalToSuperview().inset(Constants.Size.ContentSpaceHuge)
                make.top.equalTo(textFieldContainer.snp.bottom).offset(Constants.Size.ContentSpaceMid)
            }
            
            let line = UIView()
            line.backgroundColor = Constants.Color.Border
            containerView.addSubview(line)
            line.snp.makeConstraints { make in
                make.height.equalTo(1)
                make.leading.trailing.equalToSuperview().inset(Constants.Size.ContentSpaceHuge)
                make.top.equalTo(detailLabel.snp.bottom).offset(Constants.Size.ContentSpaceMid)
            }
            
            func closeKeyboard(input: Any? = nil) {
                alert.pop()
                Task { @MainActor in
                    IQKeyboardManager.shared.isEnabled = false
                }
                if let input {
                    confirmAction?(input)
                }
            }
            
            let okButton = UILabel()
            okButton.isUserInteractionEnabled = true
            okButton.enableInteractive = true
            okButton.text = R.string.localizable.confirmTitle()
            okButton.textAlignment = .center
            okButton.font = Constants.Font.title(size: .s, weight: .regular)
            okButton.textColor = Constants.Color.LabelPrimary
            okButton.addTapGesture { gesture in
                if let text = textField.text?.trimmed, !text.isEmpty {
                    switch limitedType {
                    case .integer(let min, let max):
                        if let int = Int(text), int >= min, int <= max {
                            closeKeyboard(input: int)
                        } else {
                            textFieldContainer.shake()
                        }
                    case .decimal(let min, let max):
                        if let double = Double(text), double >= min, double <= max {
                            closeKeyboard(input: double)
                        } else {
                            textFieldContainer.shake()
                        }
                    case .normal(let textSize):
                        if text.count <= textSize {
                            closeKeyboard(input: text)
                        } else {
                            textFieldContainer.shake()
                        }
                    }
                } else {
                    textFieldContainer.shake()
                }
            }
            
            let cancelButton = UILabel()
            cancelButton.isUserInteractionEnabled = true
            cancelButton.enableInteractive = true
            cancelButton.text = R.string.localizable.cancelTitle()
            cancelButton.textAlignment = .center
            cancelButton.font = Constants.Font.title(size: .s, weight: .regular)
            cancelButton.textColor = Constants.Color.LabelSecondary
            cancelButton.addTapGesture { gesture in
                closeKeyboard()
            }
            
            //有取消 和 确定
            containerView.addSubview(cancelButton)
            containerView.addSubview(okButton)

            let verticalLine = UIView()
            verticalLine.backgroundColor = Constants.Color.Border
            containerView.addSubview(verticalLine)
            verticalLine.snp.makeConstraints { make in
                make.size.equalTo(CGSize(width: 1, height: 26))
                make.centerX.equalToSuperview()
                make.centerY.equalTo(cancelButton)
            }

            cancelButton.snp.makeConstraints { make in
                make.top.equalTo(line.snp.bottom).offset(Constants.Size.ContentSpaceMax)
                make.leading.equalToSuperview().inset(Constants.Size.ContentSpaceMid)
                make.bottom.equalToSuperview().inset(Constants.Size.ContentSpaceMax)
                make.trailing.equalTo(verticalLine.snp.leading)
            }
            okButton.snp.makeConstraints { make in
                make.trailing.equalToSuperview().inset(Constants.Size.ContentSpaceMid)
                make.leading.equalTo(verticalLine.snp.trailing)
                make.centerY.equalTo(cancelButton)
            }
            
            alert.set(customView: containerView).snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
        }
    }
}
