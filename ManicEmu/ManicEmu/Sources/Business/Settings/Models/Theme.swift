//
//  Theme.swift
//  ManicEmu
//
//  Created by Daiuno on 2025/5/4.
//  Copyright © 2025 Manic EMU. All rights reserved.
//
// SPDX-License-Identifier: AGPL-3.0-or-later

import RealmSwift
import IceCream
import SmartCodable


extension Theme: CKRecordConvertible & CKRecordRecoverable {
    var isDeleted: Bool { return false }
}

enum CoverStyle: Int, PersistableEnum {
    case style1, style2, style3
    
    func defaultCornerRadius() -> CGFloat {
        switch self {
        case .style1:
            12
        case .style2:
            20
        case .style3:
            20
        }
    }
    
    func maxCornerRadius(frameHeight: CGFloat = 154) -> CGFloat {
        switch self {
        case .style1:
            frameHeight/2
        default:
            50
        }
    }
}

enum GroupTitleStyle: Int, PersistableEnum {
    case abbr, fullName, brand
}

enum GameSortType: Int, CaseIterable {
    case title, latestPlayed, addTime, playTime
    
    var title: String {
        switch self {
        case .title:
            R.string.localizable.gameSortTitleType()
        case .latestPlayed:
            R.string.localizable.gameSortLatestPlayed()
        case .addTime:
            R.string.localizable.gameSortAddTime()
        case .playTime:
            R.string.localizable.gameSortPlayTime()
        }
    }
}

enum GameSortOrder: Int, CaseIterable {
    case ascending, descending
    
    var title: String {
        switch self {
        case .ascending:
            R.string.localizable.ascending()
        case .descending:
            R.string.localizable.descending()
        }
    }
}

class Theme: Object, ObjectUpdatable {
    
    //一定要在Database的setup调用后才调用此方法
    static let defalut: Theme  = {
        return Database.realm.object(ofType: Theme.self, forPrimaryKey: Theme.defaultName)!
    }()
    
    static let defaultName = "ThemeDefault"
    
    ///名称当主键
    @Persisted(primaryKey: true) var name: String = Theme.defaultName
    ///选中的图标名称
    @Persisted var icon: String = "AppIcon"
    /**
     [{
        "timestamp": 123456
        "colors": ["#123", "#123"],
        "isSelect": false,
        "system": true
     }]
     */
    @Persisted var colors: String = {
        return Theme.initColors().toJSONString() ?? ""
    }()
    ///封面样式
    @Persisted var coverStyle: CoverStyle = .style1
    ///封面圆角 0-1 0是正方形 1是圆形
    @Persisted var coverRadiusRatio: Float = Float(CoverStyle.style1.defaultCornerRadius()/CoverStyle.style1.maxCornerRadius())
    ///平台顺序 ["3DS", "NDS"...]
    @Persisted var platformOrder: List<String> = {
        var list = List<String>()
        list.append(objectsIn: System.allCases.map({ $0.gameType.localizedShortName }))
        return list
    }()
    ///强制方形比例
    @Persisted var forceSquare: Bool = false
    ///iPhone游戏列表列数 默认2列
    @Persisted var gamesPerRow: Int = 2
    ///滑动索引条是否隐藏
    @Persisted var hideIndicator: Bool = false
    ///隐藏游戏标题
    @Persisted var hideGameTitle: Bool = false
    ///隐藏分组标题
    @Persisted var hideGroupTitle: Bool = false
    ///分组标题样式
    @Persisted var groupTitleStyle: GroupTitleStyle = .abbr
    ///额外数据备用
    @Persisted var extras: Data?
    
    private static func initColors() -> [ThemeColor] {
        let now = Date.now.timeIntervalSince1970ms
        var colors = [ThemeColor]()
        colors.append(ThemeColor(timestamp: now, colors: ["#FF2442", "#BB64FF", "#0096FF", "#EB7500"], isSelect: true, system: true))
        colors.append(ThemeColor(timestamp: now+1, colors: ["#472ff7", "#2d6cde", "#46c2da", "#f3f16a"], isSelect: false, system: true))
        colors.append(ThemeColor(timestamp: now+2, colors: ["#F10384", "#7637F8", "#FDB700", "#FD2749"], isSelect: false, system: true))
        colors.append(ThemeColor(timestamp: now+3, colors: ["#f036f8", "#4a00d9", "#4fd8f8", "#36246a"], isSelect: false, system: true))
        colors.append(ThemeColor(timestamp: now+4, colors: ["#6c89c6", "#f4f5a8", "#2c3b6c", "#161e2d"], isSelect: false, system: true))
        return colors
    }
    
    func getThemeColors() -> [ThemeColor] {
        [ThemeColor].deserialize(from: colors) ?? Theme.initColors()
    }
    
    func updateThemeColor(_ themeColor: ThemeColor) {
        let colors = getThemeColors()
        var newColors = [ThemeColor]()
        var newColor = true
        for var color in colors {
            if color.timestamp == themeColor.timestamp {
                newColors.append(themeColor)
                newColor = false
            } else {
                if themeColor.isSelect {
                    //传入的主题已经选中 则现将所有其他主题颜色置为非选中
                    color.isSelect = false
                }
                newColors.append(color)
            }
        }
        if newColor {
            newColors.append(themeColor)
        }
        Theme.change { realm in
            Theme.defalut.colors = newColors.toJSONString() ?? ""
        }
    }
    
    func deleteThemeColor(_ themeColor: ThemeColor) {
        var colors = getThemeColors()
        colors.removeAll { $0.timestamp == themeColor.timestamp }
        if colors.allSatisfy({ $0.isSelect == false }) {
            colors[0].isSelect = true
        }
        Theme.change { realm in
            Theme.defalut.colors = colors.toJSONString() ?? ""
        }
    }
    
    func getExtra(key: String) -> Any? {
        if let extras {
            return Self.getExtra(extras: extras, key: key)
        }
        return nil
    }
    
    func updateExtra(key: String, value: Any?) {
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
}

struct ThemeColor: SmartCodable {
    var timestamp: Double = 0.0
    var colors: [String] = []
    var isSelect: Bool = false
    var system: Bool = false
}
