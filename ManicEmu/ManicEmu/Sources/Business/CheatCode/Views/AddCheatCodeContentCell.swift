//
//  AddCheatCodeContentCell.swift
//  ManicEmu
//
//  Created by Daiuno on 2025/3/6.
//  Copyright © 2025 Manic EMU. All rights reserved.
//
// SPDX-License-Identifier: AGPL-3.0-or-later

import ManicEmuCore

class AddCheatCodeContentCell: UICollectionViewCell {
    
    private var supportedCheatFormats: [CheatFormat]!
    private var currentCheatFormat: CheatFormat!
    var didChangeCheatFormat: ((CheatFormat)->Void)? = nil
    var didTextChange: ((String)->Void)? = nil
    
    private var contextMenuButton: ContextMenuButton = {
        let view = ContextMenuButton()
        return view
    }()
    
    private lazy var titleLabel: SymbolButton = {
        let view = SymbolButton(image: UIImage(symbol: .chevronUpChevronDown, font: Constants.Font.caption(weight: .bold)),
                                title: R.string.localizable.autoDetectCheatTypeName(),
                                titleFont: Constants.Font.title(size: .s),
                                edgeInsets: .zero,
                                titlePosition: .left,
                                imageAndTitlePadding: Constants.Size.ContentSpaceUltraTiny)
        view.layerCornerRadius = 0
        view.backgroundColor = .clear
        view.addTapGesture { [weak self] gesture in
            guard let self = self else { return }
            let actions = self.supportedCheatFormats.map { cheatFormat in
                UIAction(title: cheatFormat.name,
                         image: cheatFormat.type == self.currentCheatFormat.type ? UIImage(symbol: .checkmarkCircleFill) : nil,
                                      handler: { [weak self] _ in
                    guard let self = self else { return }
                    self.titleLabel.titleLabel.text = cheatFormat.name
                    self.textViewPlaceHolderLabel.attributedText = NSAttributedString(string: cheatFormat.format, attributes: [.font: Constants.Font.body(size: .l), .foregroundColor: Constants.Color.LabelSecondary])
                    self.currentCheatFormat = cheatFormat
                    self.didChangeCheatFormat?(cheatFormat)
                })
            }
            self.contextMenuButton.menu = UIMenu(children: actions)
            self.contextMenuButton.triggerTapGesture()
        }
        return view
    }()
    
    private var textViewPlaceHolderLabel = UILabel()
    
    lazy var editTextView: UITextView = {
        let view = UITextView()
        view.backgroundColor = .clear
        view.textColor = Constants.Color.LabelPrimary
        view.font = Constants.Font.body(size: .l)
        view.returnKeyType = .default
        view.delegate = self
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
        
        insertSubview(contextMenuButton, belowSubview: titleLabel)
        contextMenuButton.snp.makeConstraints { make in
            make.edges.equalTo(titleLabel)
        }
        
        let textFieldContainer = RoundAndBorderView(roundCorner: .allCorners, radius: Constants.Size.CornerRadiusMid)
        textFieldContainer.backgroundColor = Constants.Color.InputBackground
        addSubview(textFieldContainer)
        textFieldContainer.snp.makeConstraints { make in
            make.leading.bottom.trailing.equalToSuperview()
            make.height.equalTo(120)
        }
        
        textFieldContainer.addSubview(editTextView)
        editTextView.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(Constants.Size.ContentSpaceMin)
        }
        
        textFieldContainer.addSubview(textViewPlaceHolderLabel)
        textViewPlaceHolderLabel.snp.makeConstraints { make in
            make.top.equalTo(editTextView).offset(Constants.Size.ContentSpaceTiny)
            make.leading.trailing.equalTo(editTextView).inset(Constants.Size.ContentSpaceUltraTiny)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setData(supportedCheatFormats: [CheatFormat], currentCheatFormat: CheatFormat, cheatCode: String) {
        self.supportedCheatFormats = supportedCheatFormats
        self.currentCheatFormat = currentCheatFormat
        titleLabel.titleLabel.text = currentCheatFormat.name
        textViewPlaceHolderLabel.attributedText = NSAttributedString(string: currentCheatFormat.format, attributes: [.font: Constants.Font.body(size: .l), .foregroundColor: Constants.Color.LabelSecondary])
        editTextView.text = cheatCode
        textViewPlaceHolderLabel.isHidden = !cheatCode.isEmpty
    }
}

extension AddCheatCodeContentCell: UITextViewDelegate {
    func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        textViewPlaceHolderLabel.isHidden = !textView.text.isEmpty
        return true
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        textViewPlaceHolderLabel.isHidden = !textView.text.isEmpty
    }
    
    func textViewDidChange(_ textView: UITextView) {
        textViewPlaceHolderLabel.isHidden = !textView.text.isEmpty
        didTextChange?(textView.text)
    }
}
