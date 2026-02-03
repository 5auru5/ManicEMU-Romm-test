//
//  FlexBackground.swift
//  ManicEmu
//
//  Created by Daiuno on 2026/1/22.
//  Copyright © 2026 Manic EMU. All rights reserved.
//

import SmartCodable

struct FlexBackground: SmartCodable, Equatable {
    enum BackgroundType {
        case game, console, global
    }
    
    var name: String = ""
    var hash: String = ""
    var games: [String] = []
    var consoles: [String] = []
    var global: Bool = false
    
    var isValid: Bool {
        return !(games.isEmpty && consoles.isEmpty && !global)
    }
    
    var imageUrl: URL {
        URL(fileURLWithPath: Constants.Path.Assets.appendingPathComponent(name))
    }
    
    static func == (lhs: Self, rhs: Self) -> Bool {
        guard lhs.name == rhs.name, lhs.hash == rhs.hash, lhs.games == rhs.games, lhs.consoles == rhs.consoles, lhs.global == rhs.global else {
            return false
        }
        return true
    }
    
    static func flushBackgrounds() {
        let backgrounds = getAllBackground()
        var newBackgrounds = [FlexBackground]()
        if let fileUrls = try? FileManager.default.contentsOfDirectory(at: URL(fileURLWithPath: Constants.Path.Assets), includingPropertiesForKeys: [.isDirectoryKey], options: .skipsHiddenFiles) {
            for fileUrl in fileUrls {
                let isDirectory = (try? fileUrl.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory ?? false
                if !isDirectory, let validBackground = backgrounds.first(where: { fileUrl.lastPathComponent == $0.name && $0.isValid }) {
                    newBackgrounds.append(validBackground)
                } else {
                    try? FileManager.safeRemoveItem(at: fileUrl)
                }
            }
        }
        newBackgrounds.removeAll(where: { !FileManager.default.fileExists(atPath: $0.imageUrl.path) })
        if newBackgrounds != backgrounds {
            Settings.defalut.updateExtra(key: ExtraKey.flexBackground.rawValue, value: newBackgrounds.toJSONString() ?? "")
        }
    }
    
    static func getAllBackground(isLandScape: Bool? = nil) -> [FlexBackground] {
        if let flexBackgroundStr = Settings.defalut.getExtraString(key: ExtraKey.flexBackground.rawValue),
           let allBackgrounds = [FlexBackground].deserialize(from: flexBackgroundStr) {
#if DEBUG
            Log.debug("[FlexBackground]>>>获取所有背景:\(allBackgrounds.toJSONString(prettyPrint: true) ?? "空")")
#endif
            return allBackgrounds.filter({
                if let isLandScape {
                    return $0.name.contains(isLandScape ? "landscape" : "portrait")
                }
                return true
            })
        }
        return []
    }
    
    static func getBackground(isLandScape: Bool, game: Game) -> (type: BackgroundType, background: FlexBackground)? {
        let backgrounds = getAllBackground(isLandScape: isLandScape)
        var firstConsoleBg: FlexBackground? = nil
        var firstGlobalBg: FlexBackground? = nil
        for bg in backgrounds {
            if bg.games.contains(game.id) {
                return (.game, bg)
            }
            if firstConsoleBg == nil, bg.consoles.contains(game.gameType.localizedShortName) {
                firstConsoleBg = bg
            }
            if firstGlobalBg == nil, bg.global {
                firstGlobalBg = bg
            }
        }
        if let firstConsoleBg {
            return (.console, firstConsoleBg)
        }
        if let firstGlobalBg {
            return (.global, firstGlobalBg)
        }
        return nil
    }
    
    static func addBackgound(isLandScape: Bool, image: UIImage, gameID: String) -> FlexBackground? {
        let allBackgrounds = getAllBackground(isLandScape: isLandScape)
        
        //获取文件名称的index
        var currentIndex: Int = 0
        if let lastBgName = allBackgrounds.last?.name {
            let regex = try! NSRegularExpression(pattern: "(\\d+)(?=\\.[^.]+$)")
            if let match = regex.firstMatch(in: lastBgName, range: NSRange(lastBgName.startIndex..., in: lastBgName)),
               let range = Range(match.range(at: 1), in: lastBgName), let index = Int(lastBgName[range]) {
                currentIndex = index + 1
            }
        }
        
        var updates = [FlexBackground]()
        var result: FlexBackground? = nil
        if let data = image.jpegData(compressionQuality: 0.9) {
            let imageUrl = URL(fileURLWithPath: Constants.Path.Assets.appendingPathComponent("flex_background_\(isLandScape ? "landscape" : "portrait")_\(currentIndex).jpg"))
            try? data.writeWithCompletePath(to: imageUrl)
            if FileManager.default.fileExists(atPath: imageUrl.path) {
                guard let hash = FileHashUtil.truncatedHash(url: imageUrl) else { return nil }
                for existBg in allBackgrounds {
                    if existBg.hash == hash {
                        //bg已经 则无需保存新图片了
                        try? FileManager.safeRemoveItem(at: imageUrl)
                        if !existBg.games.contains(gameID) {
                            //更新games列表后直接返回
                            var newBg = existBg
                            newBg.games.append(gameID)
                            updates.append(newBg)
                            result = newBg
                        } else {
                            result = existBg
                        }
                    } else {
                        if existBg.games.contains(gameID) {
                            var removeGameIDBg = existBg
                            removeGameIDBg.games.removeAll(where: { $0 == gameID })
                            updates.append(removeGameIDBg)
                        }
                    }
                }
                
                if result == nil {
                    //bg不存在 创建一个新的
                    let newBg = FlexBackground(name: imageUrl.lastPathComponent, hash: hash, games: [gameID])
                    result = newBg
                    updates.append(newBg)
                }
            }
        }
        writeBackground(updates: updates)
        return result
    }
    
    private static func writeBackground(updates: [FlexBackground]) {
        var originalAllBackgrounds = getAllBackground()
        for update in updates {
            if let index = originalAllBackgrounds.firstIndex(where: { $0.hash == update.hash }) {
                originalAllBackgrounds[index] = update
            } else {
                originalAllBackgrounds.append(update)
            }
        }
        Settings.defalut.updateExtra(key: ExtraKey.flexBackground.rawValue, value: originalAllBackgrounds.toJSONString() ?? "")
#if DEBUG
        Log.debug("[FlexBackground]>>>写入背景变更:\(originalAllBackgrounds.toJSONString(prettyPrint: true) ?? "空")")
#endif
    }
    
    func updateForGame(isLandScape: Bool, gameID: String) -> FlexBackground? {
        if games.contains(gameID) {
            return self
        }
        var result: FlexBackground? = nil
        var updates = [FlexBackground]()
        let allBackgrounds = Self.getAllBackground(isLandScape: isLandScape)
        for existBg in allBackgrounds {
            if existBg.hash == hash {
                var newBg = self
                newBg.games.append(gameID)
                result = newBg
                updates.append(newBg)
            } else {
                var newBg = existBg
                if newBg.games.contains(where: { $0 == gameID }) {
                    newBg.games.removeAll(where: { $0 == gameID })
                    updates.append(newBg)
                }
            }
        }
        Self.writeBackground(updates: updates)
        return result
    }
    
    func updateForConsole(isLandScape: Bool, console: String, gameID: String) -> FlexBackground? {
        var result: FlexBackground? = nil
        
        if consoles.contains(console) {
            return self
        }
        
        let allBackgrounds = FlexBackground.getAllBackground()
        var updates = [FlexBackground]()
        for existBg in allBackgrounds {
            if existBg.hash == hash {
                var newBg = self
                newBg.games.removeAll(where: { $0 == gameID })
                newBg.consoles.append(console)
                result = newBg
                updates.append(newBg)
            } else {
                var newBg = existBg
                if newBg.consoles.contains(where: { $0 == console }) {
                    newBg.consoles.removeAll(where: { $0 == console })
                    updates.append(newBg)
                }
            }
        }
        
        Self.writeBackground(updates: updates)
        
        return result
    }
    
    func updateForGlobal(isLandScape: Bool, console: String, gameID: String) -> FlexBackground? {
        var result: FlexBackground? = nil
        if global == true {
            return self
        }
        
        let allBackgrounds = FlexBackground.getAllBackground()
        var updates = [FlexBackground]()
        for existBg in allBackgrounds {
            if existBg.hash == hash {
                var newBg = self
                newBg.consoles.removeAll(where: { $0 == console })
                newBg.games.removeAll(where: { $0 == gameID })
                newBg.global = true
                result = newBg
                updates.append(newBg)
            } else {
                var newBg = existBg
                if newBg.global {
                    newBg.global = false
                    updates.append(newBg)
                }
            }
        }
        
        Self.writeBackground(updates: updates)
        
        return result
    }
    
    func update(image: UIImage) {
        if let data = image.jpegData(compressionQuality: 0.9) {
            try? data.writeWithCompletePath(to: imageUrl)
        }
    }
    
    func removeForGame(gameID: String) -> FlexBackground? {
        var result = self
        var isKeep = true
        if result.games.contains(gameID) {
            result.games.removeAll(where: { $0 == gameID })
            let originalAllBackgrounds = FlexBackground.getAllBackground()
            var allBackgrounds = originalAllBackgrounds
            if result.consoles.isEmpty && !result.global {
                //需要移除
                allBackgrounds.removeAll(where: {
                    if $0.hash == result.hash {
                        try? FileManager.safeRemoveItem(at: imageUrl)
                        return true
                    }
                    return false
                })
                isKeep = false
            } else {
                //仅更新
                for (index, allBackground) in allBackgrounds.enumerated() {
                    if allBackground.hash == result.hash {
                        allBackgrounds[index] = result
                        break
                    }
                }
            }
            if originalAllBackgrounds != allBackgrounds {
                Settings.defalut.updateExtra(key: ExtraKey.flexBackground.rawValue, value: allBackgrounds.toJSONString() ?? "")
            }
#if DEBUG
            Log.debug("[FlexBackground]>>>移除游戏背景:\(allBackgrounds.toJSONString() ?? "空")")
#endif
        }
        if isKeep {
            return result
        } else {
            return nil
        }
    }
    
    func removeForConsole(console: String) -> FlexBackground? {
        var result = self
        var isKeep = true
        if result.consoles.contains(console) {
            result.consoles.removeAll(where: { $0 == console })
            let originalAllBackgrounds = FlexBackground.getAllBackground()
            var allBackgrounds = originalAllBackgrounds
            if result.games.isEmpty && !result.global {
                //需要移除
                allBackgrounds.removeAll(where: {
                    if $0.hash == result.hash {
                        try? FileManager.safeRemoveItem(at: imageUrl)
                        return true
                    }
                    return false
                })
                isKeep = false
            } else {
                //仅更新
                for (index, allBackground) in allBackgrounds.enumerated() {
                    if allBackground.hash == result.hash {
                        allBackgrounds[index] = result
                        break
                    }
                }
            }
            if originalAllBackgrounds != allBackgrounds {
                Settings.defalut.updateExtra(key: ExtraKey.flexBackground.rawValue, value: allBackgrounds.toJSONString() ?? "")
            }
#if DEBUG
            Log.debug("[FlexBackground]>>>移除平台背景:\(allBackgrounds.toJSONString() ?? "空")")
#endif
        }
        if isKeep {
            return result
        } else {
            return nil
        }
    }
    
    func removeForGlobal() -> FlexBackground? {
        var result = self
        var isKeep = true
        if result.global {
            result.global = false
            let originalAllBackgrounds = FlexBackground.getAllBackground()
            var allBackgrounds = originalAllBackgrounds
            if result.games.isEmpty && result.consoles.isEmpty {
                //需要移除
                allBackgrounds.removeAll(where: {
                    if $0.hash == result.hash {
                        try? FileManager.safeRemoveItem(at: imageUrl)
                        return true
                    }
                    return false
                })
                isKeep = false
            } else {
                //仅更新
                for (index, allBackground) in allBackgrounds.enumerated() {
                    if allBackground.hash == result.hash {
                        allBackgrounds[index] = result
                        break
                    }
                }
            }
            if originalAllBackgrounds != allBackgrounds {
                Settings.defalut.updateExtra(key: ExtraKey.flexBackground.rawValue, value: allBackgrounds.toJSONString() ?? "")
            }
#if DEBUG
            Log.debug("[FlexBackground]>>>移除全局背景:\(allBackgrounds.toJSONString() ?? "空")")
#endif
        }
        if isKeep {
            return result
        } else {
            return nil
        }
    }
}
