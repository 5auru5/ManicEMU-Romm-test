//
//  MeloNXKit.swift
//  ManicEmu
//
//  Created by Daiuno on 2025/12/16.
//  Copyright © 2025 Manic EMU. All rights reserved.
//

import ManicEmuCore
import IceCream

extension GameType {
    static let ns = GameType("public.aoshuang.game.ns")
}

struct MeloNXKit {
    static var isInstalled: Bool {
        return UIApplication.shared.canOpenURL(Constants.URLs.FetchMeloNXGames)
    }
    
    static func startGame(id: String) {
        if isInstalled {
            UIApplication.shared.open(Constants.URLs.MeloNXGameLaunch(gameId: id))
        } else {
            DispatchQueue.main.asyncAfter(delay: 0.35) {
                UIView.makeToast(message: R.string.localizable.notInstallMeloNX())
            }
        }
    }
    
    static func fetchGames() {
        if isInstalled {
            UIApplication.shared.open(Constants.URLs.FetchMeloNXGames)
        } else {
            DispatchQueue.main.asyncAfter(delay: 0.35) {
                UIView.makeToast(message: R.string.localizable.notInstallMeloNX())
            }
        }
    }
    
    static func processGames(callbackUrl: URL) {
        var delay: Double
        if let _ = ApplicationSceneDelegate.applicationWindow {
            delay = 0.0
        } else {
            delay = 3.0
        }
        DispatchQueue.global().asyncAfter(delay: delay) {
            let meloNXGames = GameScheme.pullFromURL(callbackUrl)
            var games = [Game]()
            let realm = Database.realm
            for mg in meloNXGames {
                if let _ = realm.object(ofType: Game.self, forPrimaryKey: mg.titleId) {
                    Log.debug("MeloNX游戏已存在:\(mg.titleId) \(mg.titleName)")
                } else {
                    let game = Game()
                    game.id = mg.titleId
                    game.name = mg.titleName
                    game.fileExtension = "xci"
                    game.gameType = .ns
                    game.importDate = Date()
                    game.hasCoverMatch = true
                    if let icon = mg.iconData {
                        game.gameCover = CreamAsset.create(objectID: game.id, propName: "gameCover", data: icon)
                    }
                    games.append(game)
                }
            }
            if games.count > 0 {
                try? realm.write({
                    realm.add(games)
                })
                DispatchQueue.main.asyncAfter(delay: 0.35) {
                    UIView.makeToast(message: R.string.localizable.biosImportSuccess("MeloNX Games"))
                }
            }
        }
    }
}

struct GameScheme: Codable, Identifiable, Equatable, Hashable, Sendable {
    var id = UUID().uuidString
    
    var titleName: String
    var titleId: String
    var developer: String
    var version: String
    var iconData: Data?
    
    static func pullFromURL(_ url: URL) -> [GameScheme] {
        if let components = URLComponents(url: url, resolvingAgainstBaseURL: true) {
            if components.host == Constants.Strings.MeloNXScheme {
                if let text = components.queryItems?.first(where: { $0.name == "games" })?.value, let data = GameScheme.base64URLDecode(text) {
                    
                    if let decoded = try? JSONDecoder().decode([GameScheme].self, from: data) {
                        return decoded
                    }
                }
            }
        }
        return []
    }
    
    private static func base64URLDecode(_ text: String) -> Data? {
        var base64 = text
        base64 = base64.replacingOccurrences(of: "-", with: "+")
        base64 = base64.replacingOccurrences(of: "_", with: "/")
        while base64.count % 4 != 0 {
            base64 = base64.appending("=")
        }
        return Data(base64Encoded: base64)
    }
}
