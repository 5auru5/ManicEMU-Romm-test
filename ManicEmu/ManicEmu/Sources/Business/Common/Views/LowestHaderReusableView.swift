//
//  TitleHaderCollectionReusableView.swift
//  ManicEmu
//
//  Created by Max on 2025/1/21.
//  Copyright © 2025 Manic EMU. All rights reserved.
//
// SPDX-License-Identifier: AGPL-3.0-or-later

import UIKit
import VisualEffectView

class LowestHaderReusableView: UICollectionReusableView {
    var titleLabel: UILabel = {
        let view = UILabel()
        view.textColor = Constants.Color.LabelSecondary
        view.font = Constants.Font.body(size: .s, weight: .semibold)
        return view
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubviews([titleLabel])
        makeBlur(blurColor: UIColor(.dm, light: .white, dark: .black))
        
        titleLabel.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.leading.equalToSuperview().offset(Constants.Size.ContentSpaceMax)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
        
}

class BackgroundColorHaderReusableView: UICollectionReusableView {
    var titleLabel: UILabel = {
        let view = UILabel()
        view.textColor = Constants.Color.LabelSecondary.forceStyle(UIDevice.isDarkMode ? .dark : .light)
        view.font = Constants.Font.body(size: .s, weight: .semibold)
        return view
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubviews([titleLabel])
        makeBlur(blurColor: Constants.Color.Background)
        
        titleLabel.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.leading.equalToSuperview().offset(Constants.Size.ContentSpaceHuge)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //完全搞不懂为什么UICollectionView的滚动会导致UIColor的dynamicColor错乱，只能这样处理了
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if traitCollection.userInterfaceStyle.rawValue != previousTraitCollection?.userInterfaceStyle.rawValue {
            if let blurView = subviews.first(where: { $0 is VisualEffectView }) as? VisualEffectView {
                blurView.colorTint = Constants.Color.Background.forceStyle(UIDevice.isDarkMode ? .dark : .light)
                blurView.colorTintAlpha = 0.9
            }
            titleLabel.textColor = Constants.Color.LabelSecondary.forceStyle(UIDevice.isDarkMode ? .dark : .light)
        }
    }
        
}

class BackgroundColorTitleAndButtonHaderReusableView: UICollectionReusableView {
    var titleLabel: UILabel = {
        let view = UILabel()
        view.textColor = Constants.Color.LabelSecondary.forceStyle(UIDevice.isDarkMode ? .dark : .light)
        view.font = Constants.Font.body(size: .s, weight: .semibold)
        return view
    }()
    
    var button: SymbolButton = {
        let view = SymbolButton(image: UIImage(symbol: .plus, font: Constants.Font.body(size: .m, weight: .bold)), enableGlass: false)
        view.enableRoundCorner = true
        return view
    }()
    
    var didTapButton: (()->Void)? = nil
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubviews([titleLabel, button])
        makeBlur(blurColor: Constants.Color.Background)
        
        titleLabel.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.leading.equalToSuperview().offset(Constants.Size.ContentSpaceHuge)
        }
        
        button.snp.makeConstraints { make in
            make.size.equalTo(CGSize(width: 44, height: 26))
            make.centerY.equalTo(titleLabel)
            make.trailing.equalToSuperview().offset(-Constants.Size.ContentSpaceHuge)
        }
        
        button.addTapGesture { [weak self] gesture in
            self?.didTapButton?()
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class BackgroundColorTitleAndDetailHaderReusableView: UICollectionReusableView {
    var titleLabel: UILabel = {
        let view = UILabel()
        view.textColor = Constants.Color.LabelSecondary.forceStyle(UIDevice.isDarkMode ? .dark : .light)
        view.font = Constants.Font.body(size: .s, weight: .semibold)
        return view
    }()
    
    var detailLabel: UILabel = {
        let view = UILabel()
        view.textColor = Constants.Color.LabelSecondary.forceStyle(UIDevice.isDarkMode ? .dark : .light)
        view.font = Constants.Font.caption(size: .l, weight: .regular)
        view.numberOfLines = 0
        return view
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubviews([titleLabel, detailLabel])
        makeBlur(blurColor: Constants.Color.Background)
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(14)
            make.leading.equalToSuperview().offset(Constants.Size.ContentSpaceHuge)
        }
        
        detailLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(2)
            make.leading.equalTo(titleLabel)
            make.trailing.equalToSuperview().offset(-Constants.Size.ContentSpaceHuge)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
