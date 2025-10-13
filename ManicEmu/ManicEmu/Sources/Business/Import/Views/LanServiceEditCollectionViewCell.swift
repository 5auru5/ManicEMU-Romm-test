//
//  LandServiceEditCollectionViewCell.swift
//  ManicEmu
//
//  Created by Daiuno on 2025/2/27.
//  Copyright © 2025 Manic EMU. All rights reserved.
//
// SPDX-License-Identifier: AGPL-3.0-or-later

import UIKit
import IQKeyboardManagerSwift

class LanServiceEditCollectionViewCell: UICollectionViewCell {
    private var titleLabel: UILabel = {
        let view = UILabel()
        view.font = Constants.Font.body(size: .l, weight: .semibold)
        view.textColor = Constants.Color.LabelPrimary
        return view
    }()
    
    var shouldGoNext: (()->Void)? = nil
    lazy var editTextField: UITextField = {
        let view = UITextField()
        view.autocapitalizationType = .none
        view.autocorrectionType = .no
        view.textColor = Constants.Color.LabelPrimary
        view.font = Constants.Font.body(size: .l)
        view.clearButtonMode = .whileEditing
        view.onReturnKeyPress { [weak self] in
            guard let self = self else { return }
            if self.editTextField.returnKeyType == .done {
                self.editTextField.resignFirstResponder()
            } else if self.editTextField.returnKeyType == .next {
                self.shouldGoNext?()
            }
        }
        return view
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        enableInteractive = true
        delayInteractiveTouchEnd = true
        
        addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(Constants.Size.ContentSpaceTiny)
            make.top.equalToSuperview()
        }
        
        let textFieldContainer = RoundAndBorderView(roundCorner: .allCorners, radius: Constants.Size.CornerRadiusMid)
        textFieldContainer.backgroundColor = Constants.Color.InputBackground
        addSubview(textFieldContainer)
        textFieldContainer.snp.makeConstraints { make in
            make.leading.bottom.trailing.equalToSuperview()
            make.height.equalTo(Constants.Size.ItemHeightMid)
        }
        
        textFieldContainer.addSubview(editTextField)
        editTextField.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(Constants.Size.ContentSpaceMid)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setData(item: LanServiceEditViewController.EditItem) {
        titleLabel.text = item.title
        editTextField.attributedPlaceholder = NSAttributedString(string: item.placeholderString, attributes: [.font: Constants.Font.body(size: .l), .foregroundColor: Constants.Color.LabelTertiary])
        editTextField.keyboardType = item.keyboardType
        editTextField.returnKeyType = item.returnKeyType
    }
    
}
