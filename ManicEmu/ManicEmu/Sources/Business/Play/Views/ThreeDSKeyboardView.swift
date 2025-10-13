//
//  ThreeDSKeyboardView.swift
//  ManicEmu
//
//  Created by Daiuno on 2025/4/21.
//  Copyright © 2025 Manic EMU. All rights reserved.
//
// SPDX-License-Identifier: AGPL-3.0-or-later

import ProHUD
import IQKeyboardManagerSwift

struct ThreeDSKeyboardView {
    enum TapType {
        case cancel, ok, forget
    }
    
    static func show(hintText: String?,
                     keyboardType: ThreeDSKeyboardType,
                     maxTextSize: UInt16,
                tapAction: ((_ tapType: TapType, _ inputText: String?)->Void)? = nil) {
        
        Task { @MainActor in
            IQKeyboardManager.shared.isEnabled = true
            IQKeyboardManager.shared.keyboardDistance = 100
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
            containerView.makeBlur()
            //标题
            let titleLabel = UILabel()
            titleLabel.textAlignment = .center
            let textTitle: String
            if let hintText, !hintText.isEmpty {
                textTitle = hintText
            } else {
                textTitle = R.string.localizable.game3DSInputTitle()
            }
            titleLabel.text = textTitle
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
            if maxTextSize > 0 {
                textField.placeholder = R.string.localizable.maxTextSizeAllowDesc("\(maxTextSize)")
            }
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
            
            let line = UIView()
            line.backgroundColor = Constants.Color.Border
            containerView.addSubview(line)
            line.snp.makeConstraints { make in
                make.height.equalTo(1)
                make.leading.trailing.equalToSuperview().inset(Constants.Size.ContentSpaceHuge)
                make.top.equalTo(textFieldContainer.snp.bottom).offset(Constants.Size.ContentSpaceMid)
            }
            
            //按钮
            /**
             Single, /// Ok button
             Dual,   /// Cancel | Ok buttons
             Triple, /// Cancel | I Forgot | Ok buttons
             None,   /// No button (returned by swkbdInputText in special cases)
             */
            func closeKeyboard(text: String?, buttonPressed: Int = 0) {
                alert.pop()
                if let text {
                    NotificationCenter.default.post(name: .init("closeKeyboard"), object: nil, userInfo: [
                        "buttonPressed" : buttonPressed,
                        "keyboardText" : text
                    ])
                }
                
                Task { @MainActor in
                    IQKeyboardManager.shared.isEnabled = false
                }
            }
            
            if keyboardType == .none {
                textField.onReturnKeyPress {
                    closeKeyboard(text: nil)
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
                if let text = textField.text, !text.isEmpty {
                    if maxTextSize > 0, text.count > maxTextSize {
                        textFieldContainer.shake()
                        UIView.makeToast(message: R.string.localizable.maxTextSizeAllowDesc("\(maxTextSize)"))
                    } else {
                        closeKeyboard(text: textField.text, buttonPressed: keyboardType == .single ? 0 : (keyboardType == .dual ? 1 : 2))
                    }
                } else {
                    textFieldContainer.shake()
                    
                }
            }
            
//            let cancelButton = UILabel()
//            cancelButton.isUserInteractionEnabled = true
//            cancelButton.enableInteractive = true
//            cancelButton.text = R.string.localizable.cancelTitle()
//            cancelButton.textAlignment = .center
//            cancelButton.font = Constants.Font.title(size: .s, weight: .regular)
//            cancelButton.textColor = Constants.Color.LabelSecondary
//            cancelButton.addTapGesture { gesture in
//                closeKeyboard(text: nil, buttonPressed: 0)
//            }
//            
//            let forgetButton = UILabel()
//            forgetButton.isUserInteractionEnabled = true
//            forgetButton.enableInteractive = true
//            forgetButton.text = R.string.localizable.game3DSInputForget()
//            forgetButton.textAlignment = .center
//            forgetButton.font = Constants.Font.title(size: .s, weight: .regular)
//            forgetButton.textColor = Constants.Color.LabelSecondary
//            forgetButton.addTapGesture { gesture in
//                closeKeyboard(text: nil, buttonPressed: 1)
//            }
            
//            if keyboardType == .single {
                //只有确定按钮
                containerView.addSubview(okButton)
                okButton.snp.makeConstraints { make in
                    make.centerX.equalToSuperview()
                    make.top.equalTo(line.snp.bottom).offset(Constants.Size.ContentSpaceMax)
                    make.leading.trailing.equalToSuperview().inset(Constants.Size.ContentSpaceMid)
                    make.bottom.equalToSuperview().inset(Constants.Size.ContentSpaceMax)
                }
//            } else if keyboardType == .dual {
//                //有取消 和 确定
//                containerView.addSubview(cancelButton)
//                containerView.addSubview(okButton)
//                
//                let verticalLine = UIView()
//                verticalLine.backgroundColor = Constants.Color.BackgroundSecondary
//                containerView.addSubview(verticalLine)
//                verticalLine.snp.makeConstraints { make in
//                    make.size.equalTo(CGSize(width: 1, height: 26))
//                    make.centerX.equalToSuperview()
//                    make.centerY.equalTo(cancelButton)
//                }
//                
//                cancelButton.snp.makeConstraints { make in
//                    make.top.equalTo(line.snp.bottom).offset(Constants.Size.ContentSpaceMax)
//                    make.leading.equalToSuperview().inset(Constants.Size.ContentSpaceMid)
//                    make.bottom.equalToSuperview().inset(Constants.Size.ContentSpaceMax)
//                    make.trailing.equalTo(verticalLine.snp.leading)
//                }
//                okButton.snp.makeConstraints { make in
//                    make.trailing.equalToSuperview().inset(Constants.Size.ContentSpaceMid)
//                    make.leading.equalTo(verticalLine.snp.trailing)
//                    make.centerY.equalTo(cancelButton)
//                }
//                
//            } else if keyboardType == .triple {
//                //取消 忘记了 确定
//                containerView.addSubview(cancelButton)
//                containerView.addSubview(forgetButton)
//                containerView.addSubview(okButton)
//                
//                forgetButton.snp.makeConstraints { make in
//                    make.centerX.equalToSuperview()
//                    make.top.equalTo(line.snp.bottom).offset(Constants.Size.ContentSpaceMax)
//                    make.width.equalToSuperview().dividedBy(3)
//                    make.bottom.equalToSuperview().inset(Constants.Size.ContentSpaceMax)
//                }
//                
//                cancelButton.snp.makeConstraints { make in
//                    make.leading.equalToSuperview()
//                    make.trailing.equalTo(forgetButton.snp.leading)
//                    make.centerY.equalTo(forgetButton)
//                }
//                
//                okButton.snp.makeConstraints { make in
//                    make.trailing.equalToSuperview()
//                    make.leading.equalTo(forgetButton.snp.trailing)
//                    make.centerY.equalTo(forgetButton)
//                }
//            } else {
//                line.isHidden = true
//                textFieldContainer.snp.remakeConstraints { make in
//                    make.height.equalTo(Constants.Size.ItemHeightMid)
//                    make.top.equalTo(titleLabel.snp.bottom).offset(Constants.Size.ContentSpaceMid)
//                    make.leading.trailing.equalToSuperview().inset(Constants.Size.ContentSpaceMid)
//                    make.width.equalTo(textfiledWidth)
//                    make.bottom.equalToSuperview().offset(-Constants.Size.ContentSpaceMid)
//                }
//            }
            
            alert.set(customView: containerView).snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
        }
    }
}
