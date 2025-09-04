//
//  SheerExtensions.swift
//  ManicEmu
//
//  Created by Daiuno on 2025/3/9.
//  Copyright © 2025 Manic EMU. All rights reserved.
//
// SPDX-License-Identifier: AGPL-3.0-or-later

import ProHUD


extension SheetTarget {
    func configGamePlayingStyle(isForGameMenu: Bool = false, gameViewRect:CGRect, menuInsets: UIEdgeInsets? = nil, hideCompletion: (()->Void)? = nil) {
        //设置点击背景的回调
        self.onTappedBackground { sheet in
            sheet.pop(completon: hideCompletion)
        }
        self.onViewDidDisappear { _ in
            hideCompletion?()
        }
        //背景
        self.contentMaskView.alpha = 0
        self.config.backgroundViewMask { mask in
            mask.backgroundColor = .clear
        }
        //边距
        self.config.windowEdgeInset = 0
        self.config.cardCornerRadius = 0

        //尺寸
        let sheetSize: CGSize
        if UIDevice.isPhone {
            let width = Constants.Size.WindowSize.minDimension
            var height = Constants.Size.WindowHeight - Constants.Size.SafeAera.bottom - 10//默认横屏的高度
            if isForGameMenu && !UIDevice.isLandscape {
                //游戏菜单菜单竖屏时高度
                height = GameSettingView.estimatedHeight(for: width)
            } else if !isForGameMenu && !UIDevice.isLandscape {
                //其他弹窗竖屏时高度
                height = Constants.Size.WindowHeight - Constants.Size.ItemHeightHuge
            }
            sheetSize = CGSize(width: width, height: height)
        } else {
            let width = 500.0
            var height = GameSettingView.estimatedHeight(for: width)
            let maxHeight = Constants.Size.WindowHeight - Constants.Size.ItemHeightHuge*2
            if height > maxHeight {
                height = maxHeight
            }
            sheetSize = CGSize(width: width, height: height)
        }
        self.config.cardMaxWidth = sheetSize.width
        self.config.cardMaxHeight = sheetSize.height
        
        
        if let menuInsets {
            //设置了菜单的边距
            var prefferdHeight = Constants.Size.WindowHeight - menuInsets.top - menuInsets.bottom
            
            if UIDevice.isPhone, !UIDevice.isLandscape {
                prefferdHeight -= Constants.Size.ContentInsetTop
            }
            
            if prefferdHeight < self.config.cardMaxHeight! {
                self.config.cardMaxHeight = prefferdHeight
            }
            
            var prefferdWidth = Constants.Size.WindowWidth - menuInsets.left - menuInsets.right
            
            if UIDevice.isPhone, UIDevice.isLandscape {
                prefferdWidth = prefferdWidth - Constants.Size.SafeAera.left - Constants.Size.SafeAera.right
            }
            
            if prefferdWidth < self.config.cardMaxWidth! {
                self.config.cardMaxWidth = prefferdWidth
            }
            
            if menuInsets.bottom > 0 {
                self.config.bottomEdgeInset = menuInsets.bottom
            }
        }
    }
}
