//
//  AddCheatCodeTitleCell.swift
//  ManicEmu
//
//  Created by Daiuno on 2025/3/6.
//  Copyright © 2025 Manic EMU. All rights reserved.
//
// SPDX-License-Identifier: AGPL-3.0-or-later

class AddCheatCodeTitleCell: UICollectionViewCell {
    private var titleLabel: UILabel = {
        let view = UILabel()
        view.font = Constants.Font.body(size: .l, weight: .semibold)
        view.textColor = Constants.Color.LabelPrimary
        view.text = R.string.localizable.nameTitle()
        return view
    }()
    
    var shouldGoNext: (()->Void)? = nil
    lazy var editTextField: UITextField = {
        let view = UITextField()
        view.textColor = Constants.Color.LabelPrimary
        view.font = Constants.Font.body(size: .l)
        view.clearButtonMode = .whileEditing
        view.onReturnKeyPress { [weak self] in
            guard let self = self else { return }
            self.shouldGoNext?()
        }
        view.attributedPlaceholder = NSAttributedString(string: R.string.localizable.cheatCodeNamePlaceHolder(), attributes: [.font: Constants.Font.body(size: .l), .foregroundColor: Constants.Color.LabelSecondary])
        view .returnKeyType = .next
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
    
}
