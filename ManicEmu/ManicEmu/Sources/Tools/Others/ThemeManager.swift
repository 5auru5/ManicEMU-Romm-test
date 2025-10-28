//
//  ThemeManager.swift
//  ManicEmu
//
//  Created by Daiuno on 2025/5/6.
//  Copyright © 2025 Manic EMU. All rights reserved.
//
// SPDX-License-Identifier: AGPL-3.0-or-later

import RealmSwift
import FluentDarkModeKit
import ProHUD

class ThemeManager {
    static let shared = ThemeManager()
    private var themeUpdateToken: Any? = nil
    
    func setup() {
        themeUpdateToken = Theme.defalut.observe(keyPaths: [\Theme.icon, \Theme.colors, \Theme.coverStyle, \Theme.coverRadiusRatio, \Theme.platformOrder, \Theme.forceSquare, \Theme.gamesPerRow, \Theme.hideIndicator, \Theme.hideGameTitle, \Theme.hideGroupTitle, \Theme.groupTitleStyle]) { [weak self] change in
            switch change {
            case .change(_, let properties):
                for property in properties {
                    if property.name == "icon" {
                        //切换图标
                        self?.updateIcon()
                    } else if property.name == "coverStyle" || property.name == "coverRadiusRatio" || property.name == "forceSquare" {
                        //更新封面样式
                        self?.updateCoverStyle()
                    } else if property.name == "colors" {
                        //更新主题颜色
                        self?.updateThemeColor()
                    } else if property.name == "platformOrder" {
                        //更新平台顺序
                        self?.updatePlatformOrder()
                    } else if property.name == "gamesPerRow" || property.name == "hideIndicator" || property.name == "hideGroupTitle" || property.name == "hideGameTitle" || property.name == "groupTitleStyle" {
                        //更新游戏列表样式
                        self?.updateGamelist()
                    }
                    Log.debug("主题更新 Property '\(property.name)' changed from \(property.oldValue == nil ? "nil" : property.oldValue!) to '\(property.newValue!)'")
                }
            default:
                break
            }
        }
        
        updateAppearance()
        updateIcon(isSetup: true)
        updateThemeColor()
        updateCoverStyle()
        updatePlatformOrder()
        updateGamelist()
    }
    
    private func updateIcon(isSetup: Bool = false) {
        //每年的10月31日都尝试展示Halloween图标
        var showHalloweenIcon = false
        if isSetup && Date.now.month == 10 && Date.now.day == 31 {
            //检查上一次自动展示Halloween图标的时间
            if let halloweenIconShowUpDate = UserDefaults.standard.object(forKey: Constants.DefaultKey.HalloweenIconShowUpDate) as? Date {
                if halloweenIconShowUpDate.isInToday {
                    //已经展示过了 不再展示
                } else {
                    //今天还没展示过 展示
                    showHalloweenIcon = true
                }
            } else {
                //从没展示过 展示
                showHalloweenIcon = true
            }
        }
        if showHalloweenIcon {
            Log.debug("开始更新图标 今天是万圣节 直接使用万圣节图标")
            UserDefaults.standard.set(Date.now, forKey: Constants.DefaultKey.HalloweenIconShowUpDate)
            UserDefaults.standard.synchronize()
            let theme = Theme.defalut
            theme.updateExtra(key: ExtraKey.recoverIcon.rawValue, value: theme.icon)
            Theme.change { realm in
                theme.icon = "AppIcon_Halloween"
            }
            return
        }
        
        if Date.now.string(withFormat: "MMdd") != "1031" {
            //万圣节已经过了 需要恢复图标
            let theme = Theme.defalut
            if let icon = theme.getExtraString(key: ExtraKey.recoverIcon.rawValue), !icon.isEmpty {
                //有待恢复的图标
                let theme = Theme.defalut
                theme.updateExtra(key: ExtraKey.recoverIcon.rawValue, value: "")
                Theme.change { realm in
                    theme.icon = icon
                }
                return
            }
        }
        
        Log.debug("开始更新图标")
        let theme = Theme.defalut
        Log.debug("主题图标:\(theme.icon)")
        if let alternateIconName = UIApplication.shared.alternateIconName {
            Log.debug("已设置图标:\(alternateIconName)")
            if alternateIconName == theme.icon {
                Log.debug("无需更新图标")
                return
            }
        } else {
            Log.debug("当前未设置图标 说明使用的是默认图标")
            if theme.icon == "AppIcon" {
                Log.debug("无需更新图标")
                return
            }
        }
        
        if theme.icon == "AppIcon" {
            Log.debug("恢复默认图标")
            UIApplication.shared.setAlternateIconName(nil)
        } else {
            Log.debug("设置图标:\(theme.icon)")
            UIApplication.shared.setAlternateIconName(theme.icon)
        }
        
    }
    
    private func updateThemeColor() {
        let theme = Theme.defalut
        if let themeColor = theme.getThemeColors().first(where: { $0.isSelect }),
            let mainColorHex = themeColor.colors.first,
            let mainColor = UIColor(hexString: mainColorHex) {
            let gradientColors = themeColor.colors.compactMap({ UIColor(hexString: $0) })
            if Constants.Color.MainDynamicColor.hexString != mainColor.hexString {
                Constants.Color.MainDynamicColor = mainColor
                //刷新整个系统的外观 会驱使traitCollectionDidChange方法进行调用
                if let userInterfaceStyle = ApplicationSceneDelegate.applicationWindow?.traitCollection.userInterfaceStyle {
                    if userInterfaceStyle == .dark {
                        ThemeManager.updateUserInterfaceStyle(.light)
                    } else {
                        ThemeManager.updateUserInterfaceStyle(.dark)
                    }
                }
                self.updateAppearance()
                NotificationCenter.default.post(name: Constants.NotificationName.MainColorChange, object: nil)
            }
            
            if Constants.Color.Gradient != gradientColors {
                Constants.Color.Gradient = gradientColors
                NotificationCenter.default.post(name: Constants.NotificationName.GradientColorChange, object: nil)
            }
        }
    }
    
    private func updateCoverStyle() {
        let theme = Theme.defalut
        Constants.Size.GameCoverForceSquare = theme.forceSquare
        Constants.Size.GameCoverStyle = theme.coverStyle
        Constants.Size.GameCoverCornerRatio = CGFloat(theme.coverRadiusRatio)
        NotificationCenter.default.post(name: Constants.NotificationName.GameCoverChange, object: nil)
    }
    
    private func updatePlatformOrder() {
        let theme = Theme.defalut
        Constants.Config.PlatformOrder = theme.platformOrder.map({ $0 })
        NotificationCenter.default.post(name: Constants.NotificationName.PlatformOrderChange, object: nil)
    }
    
    private func updateGamelist() {
        let theme = Theme.defalut
        if theme.gamesPerRow > 0 && theme.gamesPerRow <= 5 {
            Constants.Size.GamesPerRow = Double(theme.gamesPerRow)
            Constants.Size.GamesHideScrollIndicator = theme.hideIndicator
            Constants.Size.GamesHideTitle = theme.hideGameTitle
            Constants.Size.GamesHideGroupTitle = theme.hideGroupTitle
            Constants.Size.GamesGroupTitleStyle = theme.groupTitleStyle
            NotificationCenter.default.post(name: Constants.NotificationName.GameListStyleChange, object: nil)
        }
    }
    
    func updateAppearance() {
        switch Settings.appearance {
        case .auto:
            ThemeManager.updateUserInterfaceStyle(.unspecified)
        case .light:
            ThemeManager.updateUserInterfaceStyle(.light)
        case .dark:
            ThemeManager.updateUserInterfaceStyle(.dark)
        }
    }
    
    static func updateUserInterfaceStyle(_ style: UIUserInterfaceStyle) {
        UIApplication.shared.connectedWindowScenes.forEach { windowScene in
            windowScene.windows.forEach { window in
                window.overrideUserInterfaceStyle = style
            }
        }
        AppContext.overrideUserInterfaceStyle = style
    }
}
