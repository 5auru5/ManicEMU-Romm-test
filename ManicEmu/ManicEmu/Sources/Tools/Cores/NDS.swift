//
//  NDS.swift
//  ManicEmu
//
//  Created by Daiuno on 2025/9/20.
//  Copyright © 2025 Manic EMU. All rights reserved.
//
// SPDX-License-Identifier: AGPL-3.0-or-later

import ManicEmuCore
import AVFoundation

extension GameType
{
    static let ds = GameType("public.aoshuang.game.ds")
}

@objc enum DSGameInput: Int, Input, CaseIterable {
    case a
    case b
    case x
    case y
    case l
    case r
    case l1
    case r1
    case l2//Microphone
    case l3//Close Lid
    case r3//Touch Virtual Cursor
    case start
    case select
    case up
    case down
    case left
    case right
    ///Thumbstick移动光标
    case rightThumbstickUp
    case rightThumbstickDown
    case rightThumbstickLeft
    case rightThumbstickRight
    
    case touchScreenX
    case touchScreenY

    case flex
    case menu

    public var type: InputType {
        return .game(.ds)
    }
    
    init?(stringValue: String) {
        if stringValue == "a" { self = .a }
        else if stringValue == "b" { self = .b }
        else if stringValue == "x" { self = .x }
        else if stringValue == "y" { self = .y }
        else if stringValue == "l" { self = .l }
        else if stringValue == "r" { self = .r }
        else if stringValue == "l1" { self = .l1 }
        else if stringValue == "r1" { self = .r1 }
        else if stringValue == "l2" { self = .l2 }
        else if stringValue == "l3" { self = .l3 }
        else if stringValue == "r3" { self = .r3 }
        else if stringValue == "start" { self = .start }
        else if stringValue == "select" { self = .select }
        else if stringValue == "up" { self = .up }
        else if stringValue == "down" { self = .down }
        else if stringValue == "left" { self = .left }
        else if stringValue == "right" { self = .right }
        else if stringValue == "rightThumbstickUp" { self = .rightThumbstickUp }
        else if stringValue == "rightThumbstickDown" { self = .rightThumbstickDown }
        else if stringValue == "rightThumbstickLeft" { self = .rightThumbstickLeft }
        else if stringValue == "rightThumbstickRight" { self = .rightThumbstickRight }
        else if stringValue == "touchScreenX" { self = .touchScreenX }
        else if stringValue == "touchScreenY" { self = .touchScreenY }
        else if stringValue == "flex" { self = .flex }
        else if stringValue == "menu" { self = .menu }
        else { return nil }
    }
}

struct DS: ManicEmuCoreProtocol {
    public static let core = DS()
    
    public var name: String { "DS" }
    public var identifier: String { "com.aoshuang.DSCore" }
    
    public var gameType: GameType { GameType.ds }
    public var gameInputType: Input.Type { DSGameInput.self }
    var allInputs: [Input] { DSGameInput.allCases }
    public var gameSaveExtension: String { "srm" }
        
    public let audioFormat = AVAudioFormat(commonFormat: .pcmFormatInt16, sampleRate: 32768, channels: 2, interleaved: true)!
    public let videoFormat = VideoFormat(format: .bitmap(.rgb565), dimensions: CGSize(width: 256, height: 384))
    
    public var supportCheatFormats: Set<CheatFormat> {
        let actionReplayFormat = CheatFormat(name: NSLocalizedString("Action Replay", comment: ""), format: "XXXXXXXX YYYYYYYY", type: .actionReplay)
        return [actionReplayFormat]
    }
    
    public var emulatorConnector: EmulatorBase { DSEmulatorBridge.shared }
        
    private init()
    {
    }
}


class DSEmulatorBridge : NSObject, EmulatorBase {
    static let shared = DSEmulatorBridge()
    var touchScale: CGFloat = 1
    var isDeSmuMECore: Bool = false
    
    var gameURL: URL?
    
    private(set) var frameDuration: TimeInterval = (1.0 / 60.0)
    
    var audioRenderer: (any ManicEmuCore.AudioRenderProtocol)?
    
    var videoRenderer: (any ManicEmuCore.VideoRenderProtocol)?
    
    var saveUpdateHandler: (() -> Void)?
    
    private var leftThumbstickPosition: CGPoint = .zero
    private var rightThumbstickPosition: CGPoint = .zero
    private var touchPointX: CGFloat? = nil
    private var touchPointY: CGFloat? = nil
    var touchInputFrame: CGRect = .zero
    
    func start(withGameURL gameURL: URL) {}
    
    func stop() {}
    
    func pause() {}
    
    func resume() {}
    
    func runFrame(processVideo: Bool) {}
    
    func activateInput(_ input: Int, value: Double, playerIndex: Int) {
        guard playerIndex >= 0 else { return }
        
        if input == DSGameInput.rightThumbstickUp || input == DSGameInput.rightThumbstickDown {
            rightThumbstickPosition.y = input == DSGameInput.rightThumbstickUp ? value : -value
            LibretroCore.sharedInstance().moveStick(false, x: rightThumbstickPosition.x, y: rightThumbstickPosition.y, playerIndex: UInt32(playerIndex))
        } else if input == DSGameInput.rightThumbstickLeft || input == DSGameInput.rightThumbstickRight {
            rightThumbstickPosition.x = input == DSGameInput.rightThumbstickRight ? value : -value
            LibretroCore.sharedInstance().moveStick(false, x: rightThumbstickPosition.x, y: rightThumbstickPosition.y, playerIndex: UInt32(playerIndex))
        } else {
            if input == DSGameInput.touchScreenX || input == DSGameInput.touchScreenY {
                if input == DSGameInput.touchScreenX {
                    touchPointX = value
                } else if input == DSGameInput.touchScreenY {
                    touchPointY = value
                }
                if let x = touchPointX, let y = touchPointY {
                    let touchPoint = CGPoint(x: touchInputFrame.minX + touchInputFrame.width*x*touchScale, y: touchInputFrame.minY + touchInputFrame.height*y*touchScale)
                    
#if DEBUG
                    Log.debug("\(String(describing: Self.self)) 触摸屏幕:\(touchPoint) Ratio:(\(x), \(y))")
#endif
                    LibretroCore.sharedInstance().sendTouchEventX(touchPoint.x, y: touchPoint.y)
                    touchPointX = nil
                    touchPointY = nil
                }
            } else if let gameInput = DSGameInput(rawValue: input),
               let libretroButton = gameInputToCoreInput(gameInput: gameInput) {
#if DEBUG
                Log.debug("\(String(describing: Self.self))点击了:\(gameInput)")
#endif
                LibretroCore.sharedInstance().press(libretroButton, playerIndex: UInt32(playerIndex))
            }
        }
    }
    
    //功能映射以MelonDS为准
    func gameInputToCoreInput(gameInput: DSGameInput) -> LibretroButton? {
        if gameInput == .a { return .A }
        else if gameInput == .b { return .B }
        else if gameInput == .x { return .X }
        else if gameInput == .y { return .Y }
        else if gameInput == .l { return .L1 }
        else if gameInput == .r { return .R1 }
        else if gameInput == .l1 { return .L1 }
        else if gameInput == .r1 { return .R1 }
        else if gameInput == .l2 { return isDeSmuMECore ? .L3 : .L2 }
        else if gameInput == .l3 { return isDeSmuMECore ? .L2 : .L3 }
        else if gameInput == .r3 { return isDeSmuMECore ? .R2 : .R3 }
        else if gameInput == .start { return .start }
        else if gameInput == .select { return .select }
        else if gameInput == .up { return .up }
        else if gameInput == .down { return .down }
        else if gameInput == .left { return .left }
        else if gameInput == .right { return .right }
        return nil
    }
    
    func deactivateInput(_ input: Int, playerIndex: Int) {
        if input == DSGameInput.rightThumbstickUp || input == DSGameInput.rightThumbstickDown {
            rightThumbstickPosition.y = 0
            LibretroCore.sharedInstance().moveStick(false, x: rightThumbstickPosition.x, y: rightThumbstickPosition.y, playerIndex: UInt32(playerIndex))
        } else if input == DSGameInput.rightThumbstickLeft || input == DSGameInput.rightThumbstickRight {
            rightThumbstickPosition.x = 0
            LibretroCore.sharedInstance().moveStick(false, x: rightThumbstickPosition.x, y: rightThumbstickPosition.y, playerIndex: UInt32(playerIndex))
        } else {
            if input == DSGameInput.touchScreenX || input == DSGameInput.touchScreenY {
                if input == DSGameInput.touchScreenX {
                    touchPointX = nil
                } else if input == DSGameInput.touchScreenY {
                    touchPointY = nil
                }
                if touchPointX == nil, touchPointY == nil {
                    LibretroCore.sharedInstance().releaseTouchEvent()
                }
            } else if let gameInput = DSGameInput(rawValue: input),
                let libretroButton = gameInputToCoreInput(gameInput: gameInput) {
                LibretroCore.sharedInstance().release(libretroButton, playerIndex: UInt32(playerIndex))
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

