//
//  A7800.swift
//  ManicEmu
//
//  Created by Daiuno on 2026/1/23.
//  Copyright © 2026 Manic EMU. All rights reserved.
//
// SPDX-License-Identifier: AGPL-3.0-or-later
import ManicEmuCore
import AVFoundation

extension GameType
{
    static let a7800 = GameType("public.aoshuang.game.7800")
}

@objc enum A7800GameInput: Int, Input, CaseIterable {
    case a //right red button
    case b //left red button
    case x //reset
    case start //pause
    case select //select
    case up
    case down
    case left
    case right
    case l1 //Left Difficulty
    case r1 //Right Difficulty

    case flex
    case menu

    public var type: InputType {
        return .game(.a7800)
    }
    
    init?(stringValue: String) {
        if stringValue == "a" { self = .a }
        else if stringValue == "b" { self = .b }
        else if stringValue == "x" { self = .x }
        else if stringValue == "start" { self = .start }
        else if stringValue == "select" { self = .select }
        else if stringValue == "menu" { self = .menu }
        else if stringValue == "up" { self = .up }
        else if stringValue == "down" { self = .down }
        else if stringValue == "left" { self = .left }
        else if stringValue == "right" { self = .right }
        else if stringValue == "l1" { self = .l1 }
        else if stringValue == "r1" { self = .r1 }
        else if stringValue == "flex" { self = .flex }
        else { return nil }
    }
}

struct A7800: ManicEmuCoreProtocol {
    public static let core = A7800()
    
    public var name: String { "7800" }
    public var identifier: String { "com.aoshuang.7800Core" }
    
    public var gameType: GameType { GameType.a7800 }
    public var gameInputType: Input.Type { A7800GameInput.self }
    var allInputs: [Input] { A7800GameInput.allCases }
    public var gameSaveExtension: String { "srm" }
        
    public let audioFormat = AVAudioFormat(commonFormat: .pcmFormatInt16, sampleRate: 35112 * 60, channels: 2, interleaved: true)!
    public let videoFormat = VideoFormat(format: .bitmap(.bgra8), dimensions: CGSize(width: 320, height: 240))
    
    public var supportCheatFormats: Set<CheatFormat> {
        return []
    }
    
    public var emulatorConnector: EmulatorBase { A7800EmulatorBridge.shared }
    
    private init() {}
}


class A7800EmulatorBridge : NSObject, EmulatorBase {
    static let shared = A7800EmulatorBridge()
    
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
        if let gameInput = A7800GameInput(rawValue: input),
            let libretroButton = gameInputToCoreInput(gameInput: gameInput) {
#if DEBUG
Log.debug("\(String(describing: Self.self))点击了:\(gameInput)")
#endif
            LibretroCore.sharedInstance().press(libretroButton, playerIndex: UInt32(playerIndex))
        }
    }
    
    func gameInputToCoreInput(gameInput: A7800GameInput) -> LibretroButton? {
        if gameInput == .a { return .B }
        else if gameInput == .b { return .B }
        else if gameInput == .x { return .X }
        else if gameInput == .start { return .start }
        else if gameInput == .select { return .select }
        else if gameInput == .up { return .up }
        else if gameInput == .down { return .down }
        else if gameInput == .left { return .left }
        else if gameInput == .right { return .right }
        else if gameInput == .l1 { return .L1 }
        else if gameInput == .r1 { return .R1 }
        return nil
    }
    
    func deactivateInput(_ input: Int, playerIndex: Int) {
        if let gameInput = A7800GameInput(rawValue: input),
            let libretroButton = gameInputToCoreInput(gameInput: gameInput) {
            LibretroCore.sharedInstance().release(libretroButton, playerIndex: UInt32(playerIndex))
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
