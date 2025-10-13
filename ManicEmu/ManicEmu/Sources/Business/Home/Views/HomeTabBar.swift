//
//  HomeTabBar.swift
//  ManicEmu
//
//  Created by Aoshuang Lee on 2024/12/26.
//  Copyright © 2024 Manic EMU. All rights reserved.
//
// SPDX-License-Identifier: AGPL-3.0-or-later

import UIKit

///主页面的tabbar
class HomeTabBar: UIView {
    /// 实现一个视图 拥有点击和非点击状态
    private class BarView: UIView {
        var isSelected: Bool {
            willSet {
                if newValue != self.isSelected {
                    self.updateViews(isSelected: newValue)
                }
            }
        }
        
        /// 计算BarView的宽度
        var contentWidth: CGFloat {
            self.titleLabel.intrinsicContentSize.width +
            (isSelected ? Constants.Size.IconSizeTiny.width + Constants.Size.ContentSpaceTiny : 0)
        }
        private let symbolView: SymbolView
        private let titleLabel: UILabel
        
        init(frame: CGRect, isSelected: Bool = false, normalSymbol: SFSymbol, selectedSymbol: SFSymbol, title: String) {
            self.isSelected = isSelected
            symbolView = SymbolView(normalSymbol: normalSymbol,
                                    selectedSymbol: selectedSymbol,
                                    normalColor: Constants.Color.LabelSecondary,
                                    selectedColor: Constants.Color.LabelPrimary.forceStyle(.dark))
            symbolView.isSelected = isSelected
            
            titleLabel = UILabel()
            titleLabel.font = Constants.Font.body(weight: .medium)
            titleLabel.text = title
            titleLabel.textColor = Constants.Color.LabelPrimary.forceStyle(.dark)
            titleLabel.alpha = isSelected ? 1 : 0
            super.init(frame: .zero)
            
            enableInteractive = true
            
            let contentView = UIView()
            contentView.addSubviews([symbolView, titleLabel])
            symbolView.snp.makeConstraints { makeSymbolViewConstraints(make: $0, isSelected: isSelected) }
            titleLabel.snp.makeConstraints { make in
                make.trailing.centerY.equalToSuperview()
            }
            addSubview(contentView)
            contentView.snp.makeConstraints { make in
                make.center.equalToSuperview()
            }
        }
        
        @MainActor required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        private func updateViews(isSelected: Bool) {
            if isSelected {
                UIView.normalAnimate { [weak self] in
                    self?.titleLabel.alpha = 1
                }
            } else {
                titleLabel.alpha = 0
            }
            symbolView.snp.remakeConstraints { makeSymbolViewConstraints(make: $0, isSelected: isSelected) }
            symbolView.isSelected = isSelected
            UIView.springAnimate { [weak self] in
                self?.layoutIfNeeded()
            }
        }
        
        private func makeSymbolViewConstraints(make: ConstraintMaker, isSelected: Bool) {
            make.leading.centerY.equalToSuperview()
            make.top.bottom.equalToSuperview()
            make.size.equalTo(Constants.Size.IconSizeTiny)
            if isSelected {
                make.trailing.equalTo(titleLabel.snp.leading).offset(-Constants.Size.ContentSpaceTiny)
            } else {
                make.trailing.equalToSuperview()
            }
        }
    }
    
    enum BarSelection: Int, CaseIterable {
        case games = 0, imports, settings
        
        func next() -> BarSelection {
            switch self {
            case .games:
                return .imports
            case .imports:
                return .settings
            case .settings:
                return .games
            }
        }
        
        func previous() -> BarSelection {
            switch self {
            case .games:
                return .settings
            case .imports:
                return .games
            case .settings:
                return .imports
            }
        }
    }
    
    private let gamesBar = BarView(frame: .zero,
                                   isSelected: true,
                                   normalSymbol: .gamecontroller,
                                   selectedSymbol: .gamecontrollerFill,
                                   title: R.string.localizable.tabbarTitleGames())
    private let importBar = BarView(frame: .zero,
                                    isSelected: false,
                                    normalSymbol: .trayAndArrowDown,
                                    selectedSymbol: .trayAndArrowDownFill,
                                    title: R.string.localizable.tabbarTitleImport())
    private let settingsBar = BarView(frame: .zero,
                                      isSelected: false,
                                      normalSymbol: .gearshape,
                                      selectedSymbol: .gearshapeFill,
                                      title: R.string.localizable.tabbarTitleSettings())
    private var indicatorView: AnimatedGradientView = {
        let view = AnimatedGradientView(notifiedUpadate: true)
        view.layerCornerRadius = Constants.Size.ItemHeightTiny/2
        return view
    }()
    
    
    /// 选中状态更改回调
    var selectionChange: ((BarSelection) -> Void)?
    
    /// 当前的选中状态 修改此值会回调selectionChange
    var currentSelection: BarSelection = .games {
        willSet {
            if newValue != currentSelection { //切换tab
                //反选上一次的tab
                var barView: BarView
                switch currentSelection {
                case .games:
                    barView = gamesBar
                case .imports:
                    barView = importBar
                case .settings:
                    barView = settingsBar
                }
                barView.isSelected = false
                
                //选择新tab
                switch newValue {
                case .games:
                    barView = gamesBar
                case .imports:
                    barView = importBar
                case .settings:
                    barView = settingsBar
                }
                barView.isSelected = true
                
                //更新约束和动画
                updateViewsConstraints()
                UIView.springAnimate { [weak self] in
                    self?.layoutIfNeeded()
                }
                UIDevice.generateHaptic()
            }
        }
        didSet {
            selectionChange?(currentSelection)
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = .clear
        self.layer.cornerRadius = Constants.Size.HomeTabBarSize.height/2
        if #available(iOS 26.0, *) {
            self.makeGlass()
        } else {
            self.layer.borderWidth = 1
            self.layer.borderColor = Constants.Color.Border.cgColor
            self.makeBlur(cornerRadius: Constants.Size.HomeTabBarSize.height/2)
        }
        
        addSubviews([indicatorView, gamesBar, importBar, settingsBar])
        updateViewsConstraints(isInit: true)
        gamesBar.addTapGesture { [weak self] gesture in
            self?.currentSelection = .games
        }
        importBar.addTapGesture { [weak self] gesture in
            self?.currentSelection = .imports
        }
        settingsBar.addTapGesture { [weak self] gesture in
            self?.currentSelection = .settings
        }
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            if #available(iOS 26.0, *) { } else {
                self.layer.borderWidth = 1
                self.layer.borderColor = Constants.Color.Border.cgColor
            }
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    override func layoutSubviews() {
        super.layoutSubviews()
    }
    
    private func updateViewsConstraints(isInit: Bool = false) {
        let contentWidth = Constants.Size.HomeTabBarSize.width - 3*Constants.Size.ContentSpaceMin
        let selectedBarConstraintsWidth = contentWidth * 1/2
        let unselectedBarConstraintsWidth = contentWidth * 1/4
        
        func makeWidthConstraints(_ make: ConstraintMaker, _ bar: BarView) {
            make.width.equalTo(bar.isSelected ? selectedBarConstraintsWidth : unselectedBarConstraintsWidth)
        }
        
        if isInit {
            let temp = [gamesBar, importBar, settingsBar]
            for (index, view) in temp.enumerated() {
                view.snp.makeConstraints { make in
                    if index == 0 {
                        make.leading.equalToSuperview().offset(Constants.Size.ContentSpaceMin)
                    } else {
                        make.leading.equalTo(temp[index-1].snp.trailing).offset(index == 1 ? Constants.Size.ContentSpaceMin*1.5 : 0)
                    }
                    make.top.bottom.equalToSuperview()
                    if index == temp.count - 1 {
                        make.trailing.equalToSuperview().offset(-Constants.Size.ContentSpaceMin*0.5)
                    } else {
                        makeWidthConstraints(make, view)
                    }
                }
            }
            
            indicatorView.snp.makeConstraints { make in
                make.centerY.equalToSuperview()
                make.height.equalTo(Constants.Size.ItemHeightTiny)
                if let view = [gamesBar, importBar, settingsBar].filter({ $0.isSelected }).first {
                    make.centerX.equalTo(view)
                    make.width.equalTo(view)
                }
                
            }
            
        } else {
            if gamesBar.isSelected {
                gamesBar.snp.updateConstraints { make in
                    make.leading.equalToSuperview().offset(Constants.Size.ContentSpaceMin)
                }
                importBar.snp.updateConstraints { make in
                    make.leading.equalTo(gamesBar.snp.trailing).offset(Constants.Size.ContentSpaceMin*1.5)
                }
                settingsBar.snp.updateConstraints { make in
                    make.leading.equalTo(importBar.snp.trailing)
                    make.trailing.equalToSuperview().offset(-Constants.Size.ContentSpaceMin*0.5)
                }
            } else if importBar.isSelected {
                gamesBar.snp.updateConstraints { make in
                    make.leading.equalToSuperview().offset(Constants.Size.ContentSpaceMin*0.5)
                }
                importBar.snp.updateConstraints { make in
                    make.leading.equalTo(gamesBar.snp.trailing).offset(Constants.Size.ContentSpaceMin)
                }
                settingsBar.snp.updateConstraints { make in
                    make.leading.equalTo(importBar.snp.trailing).offset(Constants.Size.ContentSpaceMin)
                    make.trailing.equalToSuperview().offset(-Constants.Size.ContentSpaceMin*0.5)
                }
            } else if settingsBar.isSelected {
                gamesBar.snp.updateConstraints { make in
                    make.leading.equalToSuperview().offset(Constants.Size.ContentSpaceMin*0.5)
                }
                importBar.snp.updateConstraints { make in
                    make.leading.equalTo(gamesBar.snp.trailing)
                }
                settingsBar.snp.updateConstraints { make in
                    make.leading.equalTo(importBar.snp.trailing).offset(Constants.Size.ContentSpaceMin*1.5)
                    make.trailing.equalToSuperview().offset(-Constants.Size.ContentSpaceMin)
                }
            }
            
            [gamesBar, importBar].forEach { view in
                view.snp.updateConstraints { make in
                    makeWidthConstraints(make, view)
                }
            }
            indicatorView.snp.remakeConstraints { make in
                make.centerY.equalToSuperview()
                make.height.equalTo(Constants.Size.ItemHeightTiny)
                if let view = [gamesBar, importBar, settingsBar].filter({ $0.isSelected }).first {
                    make.centerX.equalTo(view)
                    make.width.equalTo(view)
                }
                
            }
        }
    }
}
