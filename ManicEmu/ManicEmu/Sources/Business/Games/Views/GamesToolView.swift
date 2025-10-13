//
//  GamesToolView.swift
//  ManicEmu
//
//  Created by Daiuno on 2025/2/7.
//  Copyright © 2025 Manic EMU. All rights reserved.
//
// SPDX-License-Identifier: AGPL-3.0-or-later

import UIKit

enum SelectionChangeMode {
    case normalMode, selectionMode, selectAll, deSelectAll
}

enum SelectionType {
    case selectAll
    case selectSome(onlyOne: Bool)
    case selectNone
}

class GamesToolView: UIView {
    ///选则状态
    var isSelectAll = false
    
    var backgroundGradientView: UIView = {
        let view = GradientView()
        view.setupGradient(colors: [Constants.Color.BackgroundPrimary, Constants.Color.Background], locations: [0.0, 1.0], direction: .topToBottom)
        return view
    }()
    
    fileprivate class RightPaddingTextField: UITextField {
        override func rightViewRect(forBounds bounds: CGRect) -> CGRect {
            return CGRectMake(bounds.size.width - 28, 0, 28, bounds.size.height);
        }
    }
    
    private lazy var searchTextField: UITextField = {
        let textField = RightPaddingTextField()
        textField.attributedPlaceholder = NSAttributedString(string: R.string.localizable.gamesSearchPlaceHolder(), attributes: [.foregroundColor: Constants.Color.LabelSecondary, .font: Constants.Font.body()])
        textField.textColor = Constants.Color.LabelPrimary
        textField.font = Constants.Font.body()
        textField.clearButtonMode = .never
        textField.returnKeyType = .search
        textField.modifyClearButton(with: UIImage(symbol: .xmarkCircleFill, color: Constants.Color.LabelSecondary), size: 28)
        textField.onReturnKeyPress { [weak textField, weak self] in
            textField?.resignFirstResponder()
            self?.didSearchTextResignFirstResponder?()
        }
        textField.onEditingEnded { [weak textField, weak self] in
            self?.didSearchChange?(textField?.text)
        }
        textField.shouldClear { [weak textField, weak self] in
            self?.didSearchChange?(nil)
            return true
        }
        return textField
    }()

    private lazy var searchIcon: GamesToolIconView = {
        let view = GamesToolIconView(toolView: searchTextField, normalSymbol: .magnifyingglass, iconSize: Constants.Size.SymbolSize, autoLayutType: .greater(1000))//占据尽可能多的空间
        view.imageView.addTapGesture { [weak self]  gesture in
            guard let self = self else { return }
            self.searchIcon.isSelected = !self.searchIcon.isSelected
            if self.searchIcon.isSelected {
                self.startSearch()
            } else {
                self.stopSearch()
            }
        }
        return view
    }()
    
    private var selectIconLabel = UILabel()
    
    lazy var selectIcon: GamesToolIconView = {
        //选择视图
        let toolView = UIView()
        //标题
        let label = selectIconLabel
        label.textAlignment = .center
        label.font = Constants.Font.body()
        label.textColor = Constants.Color.LabelPrimary
        label.text = R.string.localizable.deSelectAll()
        let deSelectAllTextWidth = label.intrinsicContentSize.width
        label.text = R.string.localizable.selectAll()
        let selectAllTextWidth = label.intrinsicContentSize.width
        toolView.addSubview(label)
        label.snp.makeConstraints { make in
            make.top.leading.bottom.equalToSuperview()
            make.trailing.equalToSuperview().offset(-Constants.Size.ContentSpaceUltraTiny)
        }
        let view = GamesToolIconView(toolView: toolView, normalSymbol: .checkmarkCircle, selectedSymbol: .xmarkCircle, iconSize: 18, autoLayutType: .equal(max(deSelectAllTextWidth, selectAllTextWidth) + Constants.Size.ContentSpaceUltraTiny*2))
        view.addTapGesture { [weak self, weak label] gesture in
            guard let self = self else { return }
            selectIcon.isSelected = !selectIcon.isSelected
            isSelectAll = false
            if selectIcon.isSelected {
                //展开工具条
                didToolViewSelectionChange?(.selectionMode)
            } else {
                //收缩工具条
                label?.text = R.string.localizable.selectAll()
                didToolViewSelectionChange?(.normalMode)
            }
        }
        toolView.addTapGesture { [weak self, weak label] gesture in
            guard let self = self else { return }
            self.isSelectAll = !self.isSelectAll
            self.updateSelectIconLabel(selectionType: self.isSelectAll ? .selectAll : .selectNone)
            didToolViewSelectionChange?(isSelectAll ? .selectAll : .deSelectAll)
        }
        return view
    }()
    
    var didToolViewSelectionChange: ((SelectionChangeMode)->Void)?
    var didSearchChange: ((String?)->Void)?
    var didSearchTextResignFirstResponder: (()->Void)? = nil
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        addSubview(backgroundGradientView)
        backgroundGradientView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        searchIcon.isSelected = true
        
        let icons = [searchIcon, selectIcon]
        addSubviews(icons)
        for (index, icon) in icons.enumerated() {
            icon.snp.makeConstraints { make in
                make.centerY.equalToSuperview()
                if index == 0 {
                    make.leading.equalToSuperview().offset(Constants.Size.ContentSpaceMax)
                } else {
                    make.leading.equalTo(icons[index-1].snp.trailing).offset(Constants.Size.ContentSpaceMid)
                }
                if index == icons.count - 1 {
                    make.trailing.lessThanOrEqualToSuperview().offset(-Constants.Size.ContentSpaceMax)
                }
            }
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        roundCorners([.topLeft, .topRight], radius: Constants.Size.CornerRadiusMax)
    }
    
    func updateSelectIconLabel(selectionType: SelectionType) {
        switch selectionType {
        case .selectAll:
            selectIconLabel.text = R.string.localizable.deSelectAll()
        case .selectSome(_):
            selectIconLabel.text = R.string.localizable.selectAll()
        case .selectNone:
            selectIconLabel.text = R.string.localizable.selectAll()
        }
    }
    
    func startSearch() {
        searchTextField.becomeFirstResponder()
    }
    
    func stopSearch() {
        if searchTextField.isFirstResponder || !(searchTextField.text ?? "").isEmpty {
            searchTextField.text = nil
            searchTextField.resignFirstResponder()
            didSearchChange?(nil)
            didSearchTextResignFirstResponder?()
        }
        
    }
    
    func stopSelect() {
        if selectIcon.isSelected {
            selectIcon.isSelected = false
            isSelectAll = false
            selectIconLabel.text = R.string.localizable.selectAll()
            didToolViewSelectionChange?(.normalMode)
        }
    }
    
    func foldKeyboard() {
        if searchTextField.isFirstResponder {
            searchTextField.resignFirstResponder()
            didSearchTextResignFirstResponder?()
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class GamesToolIconView: UIView {
    enum AutoLayutType {
        case equal(CGFloat)
        case greater(CGFloat)
    }
    
    private var normalSymbol: SFSymbol
    private var selectedSymbol: SFSymbol?
    private var iconSize: CGFloat
    
    var isSelected: Bool = false {
        willSet {
            guard isSelected != newValue else { return }
            //更新约束
            if let toolView = toolView {
                imageView.snp.remakeConstraints { make in
                    make.size.equalTo(Constants.Size.IconSizeMax.height)
                    make.leading.top.bottom.equalToSuperview()
                    if newValue {
                        make.trailing.equalTo(toolView.snp.leading).offset(Constants.Size.ContentSpaceUltraTiny)
                    } else {
                        make.trailing.equalToSuperview()
                    }
                }
                
                //执行动画
                if newValue {
                    UIView.normalAnimate {
                        toolView.alpha = 1
                    }
                } else {
                    toolView.alpha = 0
                }
                UIView.springAnimate { [weak self] in
                    self?.superview?.layoutIfNeeded()
                }
            }
            //更新icon
            imageView.image = UIImage(symbol: newValue ? (selectedSymbol ?? normalSymbol) : normalSymbol,
                                      size: iconSize,
                                      color: newValue ? Constants.Color.LabelPrimary : Constants.Color.LabelSecondary)
        }
    }
    
    lazy var imageView: UIImageView = {
        let view = UIImageView()
        view.image = UIImage(symbol: normalSymbol,
                             size: iconSize ,
                             color: Constants.Color.LabelSecondary)
        view.contentMode = .center
        view.isUserInteractionEnabled = true
        return view
    }()
    private var toolView: UIView? = nil
    
    init(toolView: UIView? = nil, normalSymbol: SFSymbol = .wrenchAndScrewdriver, selectedSymbol: SFSymbol? = nil, iconSize: CGFloat = Constants.Size.SymbolSize, autoLayutType: AutoLayutType) {
        self.normalSymbol = normalSymbol
        self.iconSize = iconSize
        super.init(frame: .zero)
        self.toolView = toolView
        self.selectedSymbol = selectedSymbol
        backgroundColor = Constants.Color.Background
        enableInteractive = true
        delayInteractiveTouchEnd = true
        
        addSubview(imageView)
        imageView.snp.makeConstraints { make in
            make.size.equalTo(Constants.Size.IconSizeMax.height)
            make.edges.equalToSuperview()
        }
        
        if case let .equal(value) = autoLayutType, value == 0 {
           //不必添加toolView
        } else if let toolView = toolView {
            addSubview(toolView)
            toolView.snp.makeConstraints { make in
                make.top.trailing.bottom.equalToSuperview().inset(Constants.Size.ContentSpaceUltraTiny)
                switch autoLayutType {
                case .equal(let value):
                    make.width.equalTo(value)
                case .greater(let value):
                    make.width.greaterThanOrEqualTo(value).priority(.medium)
                }
            }
            toolView.alpha = 0
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        layerCornerRadius = height/2
        layer.borderWidth = 1
        layer.borderColor = Constants.Color.Border.cgColor
    }
}
