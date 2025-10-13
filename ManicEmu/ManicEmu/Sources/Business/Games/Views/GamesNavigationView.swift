//
//  GamesNavigationView.swift
//  ManicEmu
//
//  Created by Max on 2025/1/25.
//  Copyright © 2025 Manic EMU. All rights reserved.
//
// SPDX-License-Identifier: AGPL-3.0-or-later

import UIKit

class GamesNavigationView: UIView {
    private var appTitle: UIImageView = {
        let view = UIImageView(image: UIImage(.dm, light: R.image.app_title_light()!, dark: R.image.app_title()!))
        return view
    }()
    
    var controllerButton: SymbolButton = {
        let view = SymbolButton(image: R.image.customArcadeStickConsoleFill()?.applySymbolConfig(), enableGlass: true)
        view.enableRoundCorner = true
        view.backgroundColor = Constants.Color.BackgroundPrimary
        return view
    }()
    
    var historyButton: SymbolButton = {
        let view = SymbolButton(image: R.image.customFlagPatternCheckered()?.applySymbolConfig(), enableGlass: true)
        view.enableRoundCorner = true
        view.backgroundColor = Constants.Color.BackgroundPrimary
        return view
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        addSubviews([controllerButton, appTitle, historyButton])
        appTitle.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        
        controllerButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(Constants.Size.ContentSpaceMax)
            make.centerY.equalToSuperview()
            make.size.equalTo(Constants.Size.IconSizeMax)
        }
        
        historyButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-Constants.Size.ContentSpaceMax)
            make.centerY.equalToSuperview()
            make.size.equalTo(Constants.Size.IconSizeMax)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
