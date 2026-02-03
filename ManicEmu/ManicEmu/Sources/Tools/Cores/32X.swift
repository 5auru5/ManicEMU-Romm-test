//
//  32X.swift
//  ManicEmu
//
//  Created by Daiuno on 2025/6/13.
//  Copyright © 2025 Manic EMU. All rights reserved.
//
// SPDX-License-Identifier: AGPL-3.0-or-later

import ManicEmuCore
import AVFoundation

extension GameType
{
    static let _32x = GameType("public.aoshuang.game.32x")
}

@objc enum S2XGameInput: Int, Input, CaseIterable {
    case a
    case b
    case c
    case x
    case y
    case z
    case l
    case r
    case start
    case select
    case up
    case down
    case left
    case right

    case flex
    case menu

    public var type: InputType {
        return .game(._32x)
    }
    
    init?(stringValue: String) {
        if stringValue == "a" { self = .a }
        else if stringValue == "b" { self = .b }
        else if stringValue == "c" { self = .c }
        else if stringValue == "x" { self = .x }
        else if stringValue == "y" { self = .y }
        else if stringValue == "z" { self = .z }
        else if stringValue == "l" { self = .l }
        else if stringValue == "r" { self = .r }
        else if stringValue == "start" { self = .start }
        else if stringValue == "select" { self = .select }
        else if stringValue == "menu" { self = .menu }
        else if stringValue == "up" { self = .up }
        else if stringValue == "down" { self = .down }
        else if stringValue == "left" { self = .left }
        else if stringValue == "right" { self = .right }
        else if stringValue == "flex" { self = .flex }
        else { return nil }
    }
}

struct S2X: ManicEmuCoreProtocol {
    static var isJGenesisCore: Bool = false
    
    public static let core = S2X()
    
    public var name: String { "32X" }
    public var identifier: String { "com.aoshuang.32XCore" }
    
    public var gameType: GameType { GameType._32x }
    public var gameInputType: Input.Type { S2XGameInput.self }
    var allInputs: [Input] { S2XGameInput.allCases }
    public var gameSaveExtension: String { "srm" }
        
    public let audioFormat = AVAudioFormat(commonFormat: .pcmFormatInt16, sampleRate: 32040, channels: 2, interleaved: true)!
    public let videoFormat = VideoFormat(format: .bitmap(.rgb565), dimensions: CGSize(width: 320, height: 224))
    
    public var supportCheatFormats: Set<CheatFormat> {
        let gameGenieFormat = CheatFormat(name: NSLocalizedString("Game Genie", comment: ""), format: "XXXX-YYYY", type: .gameGenie)
        let proActionReplayFormat = CheatFormat(name: NSLocalizedString("Pro Action Replay 16Bit", comment: ""), format: "XXXXXXYYYY", type: .actionReplay16)
        return [gameGenieFormat, proActionReplayFormat]
    }
    
    public var emulatorConnector: EmulatorBase { S2XEmulatorBridge.shared }
        
    private init()
    {
    }
}


class S2XEmulatorBridge : NSObject, EmulatorBase {
    static let shared = S2XEmulatorBridge()
    
    var gameURL: URL?
    
    private(set) var frameDuration: TimeInterval = (1.0 / 60.0)
    
    var audioRenderer: (any ManicEmuCore.AudioRenderProtocol)?
    
    var videoRenderer: (any ManicEmuCore.VideoRenderProtocol)?
    
    var saveUpdateHandler: (() -> Void)?
    
    private var thumbstickPosition: CGPoint = .zero
    
    func start(withGameURL gameURL: URL) {}
    
    func stop() {}
    
    func pause() {}
    
    func resume() {}
    
    func runFrame(processVideo: Bool) {}
    
    func activateInput(_ input: Int, value: Double, playerIndex: Int) {
        guard playerIndex >= 0 else { return }
        if let gameInput = S2XGameInput(rawValue: input) {
#if DEBUG
            Log.debug("\(String(describing: Self.self))点击了:\(gameInput)")
#endif
            if S2X.isJGenesisCore {
                if let jGenesisButton = gameInputToJGenesisCoreInput(gameInput: gameInput) {
                    PlayViewController.jGenesisView?.pressButton(jGenesisButton, pressed: true, player: playerIndex-1)
                }
            } else {
                if let libretroButton = gameInputToCoreInput(gameInput: gameInput) {
                    LibretroCore.sharedInstance().press(libretroButton, playerIndex: UInt32(playerIndex))
                }
            }
            
        }
        
    }
    
    func gameInputToCoreInput(gameInput: S2XGameInput) -> LibretroButton? {
        if gameInput == .a { return .Y }
        else if gameInput == .b { return .B }
        else if gameInput == .c { return .A }
        else if gameInput == .x { return .L1 }
        else if gameInput == .y { return .X }
        else if gameInput == .z { return .R1 }
        else if gameInput == .l { return .L2 }
        else if gameInput == .r { return .R2 }
        else if gameInput == .start { return .start }
        else if gameInput == .select { return .select }
        else if gameInput == .up { return .up }
        else if gameInput == .down { return .down }
        else if gameInput == .left { return .left }
        else if gameInput == .right { return .right }
        return nil
    }
    
    func gameInputToJGenesisCoreInput(gameInput: S2XGameInput) -> JGenesisButton? {
        if gameInput == .a { return .a }
        else if gameInput == .b { return .b }
        else if gameInput == .c { return .c }
        else if gameInput == .x { return .x }
        else if gameInput == .y { return .y }
        else if gameInput == .z { return .z }
        else if gameInput == .start { return .start }
        else if gameInput == .up { return .up }
        else if gameInput == .down { return .down }
        else if gameInput == .left { return .left }
        else if gameInput == .right { return .right }
        return nil
    }
    
    func deactivateInput(_ input: Int, playerIndex: Int) {
        if let gameInput = S2XGameInput(rawValue: input) {
            if S2X.isJGenesisCore {
                if let jGenesisButton = gameInputToJGenesisCoreInput(gameInput: gameInput) {
                    PlayViewController.jGenesisView?.pressButton(jGenesisButton, pressed: false, player: playerIndex-1)
                }
            } else {
                if let libretroButton = gameInputToCoreInput(gameInput: gameInput) {
                    LibretroCore.sharedInstance().release(libretroButton, playerIndex: UInt32(playerIndex))
                }
            }
            
        }
    }
    
    func resetInputs() {}
    
    func saveSaveState(to url: URL) {}
    
    func loadSaveState(from url: URL) {}
    
    func saveGameSave(to url: URL) {}
    
    func loadGameSave(from url: URL) {}
    
    func addCheatCode(_ cheatCode: String, type: String) -> Bool {
        return false
    }
    
    func resetCheats() {}
    
    func updateCheats() {}
    
}
