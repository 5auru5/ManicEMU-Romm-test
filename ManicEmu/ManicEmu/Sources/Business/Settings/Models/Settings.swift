//
//  Settings.swift
//  ManicEmu
//
//  Created by Daiuno on 2025/2/20.
//  Copyright © 2025 Manic EMU. All rights reserved.
//
// SPDX-License-Identifier: AGPL-3.0-or-later

import RealmSwift
import ManicEmuCore
import IceCream
import SmartCodable

extension Settings: CKRecordConvertible & CKRecordRecoverable {
    var isDeleted: Bool { return false }
}

class Settings: Object, ObjectUpdatable {
    //一定要在Database的setup调用后才调用此方法
    static let defalut: Settings  = {
        return Database.realm.object(ofType: Settings.self, forPrimaryKey: Settings.defaultName)!
    }()
    
    static let defaultName = "SettingsDefault"
    ///名称当主键
    @Persisted(primaryKey: true) var name: String = Settings.defaultName
    
    ///皮肤配置 平台对应的默认皮肤 json格式 key是GameType value是Skin的id
    @Persisted var skinConfig: String
    
    ///快速开始游戏
    @Persisted var quickGame: Bool = false
    ///AirPlay全屏模式
    @Persisted var airPlay: Bool = true
    ///应用图标配置
    @Persisted var appIconIndex: Int = 0
    ///语言
    @Persisted var language: String?
    ///游戏功能排序
    @Persisted var gameFunctionList: List<Int>
    /// 展示在默认皮肤上的功能数量
    @Persisted var displayGamesFunctionCount: Int = Constants.Numbers.GameFunctionButtonCount
    ///iCloud同步 只会在本地进行存储，意味着一个新设备安装的时候 默认都是false
#if SIDE_LOAD
    var iCloudSyncEnable: Bool = false
#else
    var iCloudSyncEnable: Bool {
        set {
            UserDefaults.standard.set(newValue, forKey: "iCloudSyncEnable")
            if newValue {
                //开启iCloud同步
                SyncManager.shared.startSync()
            } else {
                //关闭iCloud同步
                SyncManager.shared.stopSync()
            }
        }
        get {
            UserDefaults.standard.bool(forKey: "iCloudSyncEnable")
        }
    }
#endif
    ///3DS模式 默认兼容模式
    @Persisted var threeDSMode: ThreeDSMode = .compatibility
    ///连上手柄时 是否自动全屏
    @Persisted var fullScreenWhenConnectController: Bool = true
    ///默认图标
    @Persisted var desktopIcon: String?
    ///是否自动即时存档
    @Persisted var autoSaveState: Bool = false
    ///3ds进阶设置模式
    @Persisted var threeDSAdvancedSettingMode: Bool = false
    ///跟随系统静音
    @Persisted var respectSilentMode: Bool = false
    ///额外数据备用
    @Persisted var extras: Data?
    
    enum Appearance: Int {
        case dark, light, auto
        var desc: String {
            switch self {
            case .light:
                R.string.localizable.appearanceLight()
            case .dark:
                R.string.localizable.appearanceDark()
            case .auto:
                R.string.localizable.appearanceAuto()
            }
        }
    }
    static var appearance: Appearance {
        get {
            return Appearance(rawValue: UserDefaults.standard.integer(forKey: Constants.DefaultKey.Appearance)) ?? .dark
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: Constants.DefaultKey.Appearance)
            ThemeManager.shared.updateAppearance()
        }
    }
    
    func getExtra(key: String) -> Any? {
        if let extras {
            return Self.getExtra(extras: extras, key: key)
        }
        return nil
    }
    
    func updateExtra(key: String, value: Any) {
        if let extras, let data = Self.updateExtra(extras: extras, key: key, value: value) {
            Self.change { realm in
                self.extras = data
            }
        } else if let data = [key: value].jsonData() {
            Self.change { realm in
                self.extras = data
            }
        }
    }
    
    var airPlayScaling: GameSetting.AirPlayScaling {
        GameSetting.AirPlayScaling(rawValue: Settings.defalut.getExtraInt(key: ExtraKey.airPlayScaling.rawValue) ?? 0) ?? .coreProvided
    }
    
    var airPlayLayout: GameSetting.AirPlayLayout {
        GameSetting.AirPlayLayout(rawValue: Settings.defalut.getExtraInt(key: ExtraKey.airPlayLayout.rawValue) ?? 0) ?? .embeddedTopLeft
    }
}

struct SkinConfig: SmartCodable {
    var portraitSkins = [String: String]()
    var landscapeSkins = [String: String]()
    
    static func prefferedPortraitSkin(gameType: GameType) -> Skin? {
        prefferedSkin(gameType: gameType, isLandscape: false)
    }
    
    static func prefferedLandscapeSkin(gameType: GameType) -> Skin? {
        prefferedSkin(gameType: gameType, isLandscape: true)
    }
    
    static func prefferedSkin(gameType: GameType, isLandscape: Bool) -> Skin? {
        if let config = SkinConfig.deserialize(from: Settings.defalut.skinConfig),
           let skinId = isLandscape ? config.landscapeSkins[gameType.rawValue] : config.portraitSkins[gameType.rawValue],
            let skin = Database.realm.object(ofType: Skin.self, forPrimaryKey: skinId) {
            return skin
        } else {
            return Database.realm.objects(Skin.self).first { $0.gameType == gameType && $0.skinType == .default }
        }
    }
    
    static func setDefaultSkin(_ skin: Skin, isLandscape: Bool) {
        if var config = SkinConfig.deserialize(from: Settings.defalut.skinConfig) {
            if isLandscape {
                config.landscapeSkins[skin.gameType.rawValue] = skin.id
            } else {
                config.portraitSkins[skin.gameType.rawValue] = skin.id
            }
            if let jsonString = config.toJSONString() {
                Settings.change { _ in
                    Settings.defalut.skinConfig = jsonString
                }
            }
        }
    }
    
    static func resetDefaultSkin(gameType: GameType? = nil) {
        if var config = SkinConfig.deserialize(from: Settings.defalut.skinConfig) {
            let realm = Database.realm
            let skins: Results<Skin>
            if let gameType {
                skins = realm.objects(Skin.self).where({ !$0.isDeleted && $0.skinType == .default && $0.gameType == gameType })
            } else {
                skins = realm.objects(Skin.self).where({ !$0.isDeleted && $0.skinType == .default })
            }
            for skin in skins {
                config.landscapeSkins[skin.gameType.rawValue] = skin.id
                config.portraitSkins[skin.gameType.rawValue] = skin.id
            }
            if let jsonString = config.toJSONString() {
                Settings.change { _ in
                    Settings.defalut.skinConfig = jsonString
                }
            }
        }
    }
    
    var jsonString: String? {
        self.toJSONString()
    }
}
