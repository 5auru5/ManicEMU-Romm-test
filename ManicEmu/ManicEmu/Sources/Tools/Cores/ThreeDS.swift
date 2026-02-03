//
//  ThreeDS.swift
//  ManicEmu
//
//  Created by Daiuno on 2025/4/8.
//  Copyright © 2025 Manic EMU. All rights reserved.
//
// SPDX-License-Identifier: AGPL-3.0-or-later

import ManicEmuCore
import AVFoundation
#if !targetEnvironment(simulator)
import ThreeDS
#else
import MetalKit
#endif

extension GameType
{
    static let _3ds = GameType("public.aoshuang.game.3ds")
}

extension CheatType
{
    static let gateshark = CheatType("Gateshark")
}

@objc enum ThreeDSGameInput: Int, Input, CaseIterable {
    case a = 700
    case b = 701
    case x = 702
    case y = 703
    case start = 704
    case select = 705
    case home = 706
    case menu = 1
    case l2 = 707
    case r2 = 708
    case up = 709
    case down = 710
    case left = 711
    case right = 712
    case l1 = 773
    case r1 = 774
    case CirclePad = 713
    case leftThumbstickUp = 714
    case leftThumbstickDown = 715
    case leftThumbstickLeft = 716
    case leftThumbstickRight = 717
    case CStick = 718
    case rightThumbstickUp = 719
    case rightThumbstickDown = 720
    case rightThumbstickLeft = 771
    case rightThumbstickRight = 772
    
    case touchScreenX = 4096
    case touchScreenY = 8192
    
    case flex = 0

    public var type: InputType {
        return .game(._3ds)
    }
    
    public var isContinuous: Bool {
        switch self
        {
        case .touchScreenX, .touchScreenY: return true
        default: return false
        }
    }
    
    init?(stringValue: String) {
        if stringValue == "a" { self = .a }
        else if stringValue == "b" { self = .b }
        else if stringValue == "x" { self = .x }
        else if stringValue == "y" { self = .y }
        else if stringValue == "start" { self = .start }
        else if stringValue == "select" { self = .select }
        else if stringValue == "home" { self = .home }
        else if stringValue == "menu" { self = .menu }
        else if stringValue == "l2" { self = .l2 }
        else if stringValue == "r2" { self = .r2 }
        else if stringValue == "up" { self = .up }
        else if stringValue == "down" { self = .down }
        else if stringValue == "left" { self = .left }
        else if stringValue == "right" { self = .right }
        else if stringValue == "l1" { self = .l1 }
        else if stringValue == "r1" { self = .r1 }
        else if stringValue == "CirclePad" { self = .CirclePad }
        else if stringValue == "leftThumbstickUp" { self = .leftThumbstickUp }
        else if stringValue == "leftThumbstickDown" { self = .leftThumbstickDown }
        else if stringValue == "leftThumbstickLeft" { self = .leftThumbstickLeft }
        else if stringValue == "leftThumbstickRight" { self = .leftThumbstickRight }
        else if stringValue == "CStick" { self = .CStick }
        else if stringValue == "rightThumbstickUp" { self = .rightThumbstickUp }
        else if stringValue == "rightThumbstickDown" { self = .rightThumbstickDown }
        else if stringValue == "rightThumbstickLeft" { self = .rightThumbstickLeft }
        else if stringValue == "rightThumbstickRight" { self = .rightThumbstickRight }
        else if stringValue == "touchScreenX" { self = .touchScreenX }
        else if stringValue == "touchScreenY" { self = .touchScreenY }
        else if stringValue == "flex" { self = .flex }
        else { return nil }
    }
}

struct ThreeDS: ManicEmuCoreProtocol {
    static let core = ThreeDS()
    
    var name: String { "3DS" }
    var identifier: String { "com.aoshuang.3DSCore" }
    var version: String? { "1.7.0" }
    
    var gameType: GameType { GameType._3ds }
    var gameInputType: Input.Type { ThreeDSGameInput.self }
    var allInputs: [Input] { ThreeDSGameInput.allCases }
    var gameSaveExtension: String { "3ds.sav" }
    
    let audioFormat = AVAudioFormat(commonFormat: .pcmFormatInt16, sampleRate: 32768, channels: 2, interleaved: true)!
    let videoFormat = VideoFormat(format: .bitmap(.bgra8), dimensions: CGSize(width: 400, height: 480))
    
    var supportCheatFormats: Set<CheatFormat> {
        let actionReplayFormat = CheatFormat(name: NSLocalizedString("Gateshark", comment: ""), format: "XXXXXXXX YYYYYYYY", type: .gateshark)
        return [actionReplayFormat]
    }
    
    static var isAzaharCore: Bool = false
    
    var emulatorConnector: EmulatorBase {
        if Self.isAzaharCore {
            return AzaharEmulatorBridge.shared
        } else {
            return ThreeDSEmulatorBridge.shared
        }
    }
    
    private init()
    {
    }
    
    //For Citra
    static func setupCheats(identifier: UInt64, cheatsTxt: String, enableCheats: [String]) {
#if !targetEnvironment(simulator)
        let manager = CheatsManager(identifier: identifier)
        let path = manager.cheatFilePath()
        try? cheatsTxt.writeWithCompletePath(to: URL(fileURLWithPath: path))
        manager.loadCheats()
        let cheats = manager.getCheats()
        for (index, cheat) in cheats.enumerated() {
            if enableCheats.contains(where: { $0.contains(cheat.name) }) {
                cheat.enabled = true
            } else {
                cheat.enabled = false
            }
            manager.update(cheat, at: index)
        }
        manager.saveCheats()
#endif
    }
    
    struct Cheat {
        let name: String
        let code: String
    }

    static func parseCheatFile(_ text: String) -> [Cheat] {
        let pattern = #"\[(.*?)\]\s*([\s\S]*?)(?=\n\s*\[|$)"#

        let regex = try! NSRegularExpression(pattern: pattern, options: [])
        let nsText = text as NSString
        let matches = regex.matches(
            in: text,
            options: [],
            range: NSRange(location: 0, length: nsText.length)
        )

        return matches.compactMap { match in
            guard match.numberOfRanges == 3 else { return nil }

            let title = nsText.substring(with: match.range(at: 1))

            let rawCode = nsText.substring(with: match.range(at: 2))
            let code = rawCode.trimmingCharacters(in: .whitespacesAndNewlines)

            return Cheat(name: title, code: code)
        }
    }
}

enum ThreeDSKeyboardType: UInt {
    case single
    case dual
    case triple
    case none
}

#if !targetEnvironment(simulator)
class ThreeDSEmulatorBridge : NSObject, EmulatorBase {
    
    static let shared = ThreeDSEmulatorBridge()
    private let threeDSCore = ThreeDSCore.shared
    
    var gameURL: URL?
    
    private(set) var frameDuration: TimeInterval = (1.0 / 60.0)
    
    var audioRenderer: (any ManicEmuCore.AudioRenderProtocol)?
    
    var videoRenderer: (any ManicEmuCore.VideoRenderProtocol)?
    
    var saveUpdateHandler: (() -> Void)?
    
    private var enableControl = false
    
    private var thumbstickPosition: CGPoint = .zero
    private var cstickPosition: CGPoint = .zero
    private var touchPosition: CGPoint = .zero
    
    private weak var metalView: MTKView? = nil
    
    private var topRect: CGRect = .zero
    private var bottomRect: CGRect = .zero
    
    private var isAdvancedMode: Bool = false
    
    func setSimBlowing(start: Bool) {
        threeDSCore.setSimBlowing(start: start)
    }
    
    func jumpToHome() {
        threeDSCore.jumpToHome()
    }
    
    func loadAmiibo(path: String) {
        //https://drive.google.com/drive/folders/1Rto0H_1cATSvgrFk0Ku6HnDHQwx_nnx_?usp=sharing
        threeDSCore.loadAmiibo(path: path)
    }
    
    func isAmiiboSearching() -> Bool {
        return threeDSCore.isSearchingAmiibo()
    }
    
    func setResolution(resolution: GameSetting.Resolution) {
        updateConfig(["ManicEMU.resolutionFactor": resolution.rawValue])
    }
    
    func openKeyboardAction(_ action: ((_ hintText:String?, _ keyboardType: ThreeDSKeyboardType, _ maxTextSize: UInt16) -> Void)? = nil) {
        ThreeDSCore.openKeyboardAction = { action?($0, ThreeDSKeyboardType(rawValue: $1)!, $2) }
    }
    
    func start(withGameURL gameURL: URL,
               metalView: MTKView,
               metalViewFrame: CGRect,
               topRect: CGRect,
               bottomRect: CGRect,
               mute: Bool,
               resolution: GameSetting.Resolution = .one,
               jit: Bool = false,
               accurateShaders: Bool = false,
               language: Int = -1,
               renderRightEye: Bool = false,
               advancedMode: Bool = Settings.defalut.threeDSAdvancedSettingMode) {
        self.topRect = topRect
        self.bottomRect = bottomRect
        self.gameURL = gameURL
        self.isAdvancedMode = advancedMode
        var appendConfig: [String: Any] = ["ManicEMU.audioMuted": mute, "ManicEMU.resolutionFactor": resolution.rawValue < GameSetting.Resolution.one.rawValue ? 1 : resolution.rawValue]
        if jit {
            appendConfig["ManicEMU.cpuJIT"] = true
            switch Settings.defalut.threeDSMode {
            case .compatibility:
                appendConfig["ManicEMU.cpuClockPercentage"] = 60
            case .performance:
                appendConfig["ManicEMU.cpuClockPercentage"] = 50
            case .quality:
                appendConfig["ManicEMU.cpuClockPercentage"] = 75
            }
        } else {
            appendConfig["ManicEMU.cpuJIT"] = false
            switch Settings.defalut.threeDSMode {
            case .performance:
                appendConfig["ManicEMU.cpuClockPercentage"] = 15
            case .compatibility:
                appendConfig["ManicEMU.cpuClockPercentage"] = 20
            case .quality:
                appendConfig["ManicEMU.cpuClockPercentage"] = 25
            }
        }
        if accurateShaders {
            appendConfig["ManicEMU.useShadersAccurateMul"] = true
        } else {
            appendConfig["ManicEMU.useShadersAccurateMul"] = false
        }
        if renderRightEye {
            appendConfig["ManicEMU.disableRightEyeRender"] = false
        } else {
            appendConfig["ManicEMU.disableRightEyeRender"] = true
        }
        appendConfig["ManicEMU.regionValue"] = language
#if DEBUG
        appendConfig["ManicEMU.logLevel"] = 0
#else
        appendConfig["ManicEMU.logLevel"] = 6
#endif
        updateConfig(appendConfig)
        threeDSCore.allocateVulkanLibrary()
        self.metalView = metalView
        let metalLayer = metalView.layer as! CAMetalLayer
        threeDSCore.allocateMetalLayer(for: metalLayer, with: metalViewFrame.size)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            Thread.setThreadPriority(1.0)
            Thread.detachNewThread {
                self.threeDSCore.insertCartridgeAndBoot(with: gameURL, advancedMode: advancedMode, jitSupport: LibretroCore.jitAvailable())
            }
        }
        DispatchQueue.main.asyncAfter(delay: 3.25) {
            self.threeDSCore.orientationChange(with: UIDevice.currentOrientation, using: metalView)
            self.enableControl = true
        }
    }
    
    func start(withGameURL gameURL: URL) {}
    
    func destory() {
        threeDSCore.deallocateVulkanLibrary()
        threeDSCore.deallocateMetalLayers()
    }
    
    func stop() {
        threeDSCore.stop()
    }
    
    func pause() {
        if threeDSCore.stopped() {
            return
        }
        if !threeDSCore.isPaused() {
            threeDSCore.pausePlay(false)
        }
    }
    
    func resume() {
        if threeDSCore.stopped() {
            return
        }
        if threeDSCore.isPaused() {
            threeDSCore.pausePlay(true)
        }
    }
    
    var saveStateCount: Int {
        return threeDSCore.saveStateCount
    }
    
    func addSaveState(fileUrl: URL, slot: UInt32) {
        if let path = threeDSCore.saveStatePathForRunningGame(slot: slot) {
            try? FileManager.safeCopyItem(at: fileUrl, to: URL(fileURLWithPath: path), shouldReplace: true)
        }
    }
    
    func saveState() -> (isSuccess: Bool, path: String) {
        return threeDSCore.saveState()
    }
    
    @discardableResult func loadState(_ slot: UInt32? = nil) -> Bool {
        return threeDSCore.loadState(slot)
    }
    
    func enableVolume() {
        updateConfig(["ManicEMU.audioMuted": false])
    }
    
    func disableVolume() {
        updateConfig(["ManicEMU.audioMuted": true])
    }
    
    func runFrame(processVideo: Bool) { }
    
    func gameInputToCoreInput(gameInput: ThreeDSGameInput) -> VirtualControllerButtonType {
        if gameInput == .a { return .A }
        else if gameInput == .b { return .B }
        else if gameInput == .x { return .X }
        else if gameInput == .y { return .Y }
        else if gameInput == .start { return .start }
        else if gameInput == .select { return .select }
        else if gameInput == .l2 { return .triggerZL }
        else if gameInput == .r2 { return .triggerZR }
        else if gameInput == .up { return .directionalPadUp }
        else if gameInput == .down { return .directionalPadDown }
        else if gameInput == .left { return .directionalPadLeft }
        else if gameInput == .right { return .directionalPadRight }
        else if gameInput == .l1 { return .triggerL }
        else if gameInput == .r1 { return .triggerR }
        else { return .debug }
    }
    
    func activateInput(_ input: Int, value: Double, playerIndex: Int) {
        guard enableControl else { return }
        /**
         摇杆坐标
         0,1
         
   -1,0  0,0  1,0
         
         0,-1
         */
        if input == ThreeDSGameInput.leftThumbstickUp || input == ThreeDSGameInput.leftThumbstickDown {
            
            thumbstickPosition.y = input == ThreeDSGameInput.leftThumbstickUp ? value : -value
            threeDSCore.thumbstickMoved(.circlePad, Float(thumbstickPosition.x), Float(thumbstickPosition.y))
            
            
        } else if input == ThreeDSGameInput.leftThumbstickLeft || input == ThreeDSGameInput.leftThumbstickRight {
            
            thumbstickPosition.x = input == ThreeDSGameInput.leftThumbstickRight ? value : -value
            threeDSCore.thumbstickMoved(.circlePad, Float(thumbstickPosition.x), Float(thumbstickPosition.y))
            
        } else if input == ThreeDSGameInput.rightThumbstickUp || input == ThreeDSGameInput.rightThumbstickDown {
            
            cstickPosition.y = input == ThreeDSGameInput.rightThumbstickUp ? value : -value
            threeDSCore.thumbstickMoved(.cStick, Float(cstickPosition.x), Float(cstickPosition.y))
            
        } else if input == ThreeDSGameInput.rightThumbstickLeft || input == ThreeDSGameInput.rightThumbstickRight {
            
            cstickPosition.x = input == ThreeDSGameInput.rightThumbstickRight ? value : -value
            threeDSCore.thumbstickMoved(.cStick, Float(cstickPosition.x), Float(cstickPosition.y))
            
        } else if input == ThreeDSGameInput.touchScreenX || input == ThreeDSGameInput.touchScreenY {
            if input == ThreeDSGameInput.touchScreenX {
                touchPosition.x = value * bottomRect.width + bottomRect.minX
            }
            if input == ThreeDSGameInput.touchScreenY {
                touchPosition.y = value * bottomRect.height + bottomRect.minY
            }
            if touchPosition.x != 0 && touchPosition.y != 0 {
                threeDSCore.touchBegan(at: touchPosition)
                threeDSCore.touchMoved(at: touchPosition)
            }
            
        } else {
            if let gameInput = ThreeDSGameInput(rawValue: input) {
                let type = gameInputToCoreInput(gameInput: gameInput)
                if type != .debug {
                    threeDSCore.virtualControllerButtonDown(type)
                }
            }
            
        }
    }
    
    func deactivateInput(_ input: Int, playerIndex: Int) {
        guard enableControl else { return }
        if input == ThreeDSGameInput.leftThumbstickUp || input == ThreeDSGameInput.leftThumbstickDown {
            thumbstickPosition.y = 0
            threeDSCore.thumbstickMoved(.circlePad, Float(thumbstickPosition.x), Float(thumbstickPosition.y))
        } else if input == ThreeDSGameInput.leftThumbstickLeft || input == ThreeDSGameInput.leftThumbstickRight {
            thumbstickPosition.x = 0
            threeDSCore.thumbstickMoved(.circlePad, Float(thumbstickPosition.x), Float(thumbstickPosition.y))
        } else if input == ThreeDSGameInput.rightThumbstickUp || input == ThreeDSGameInput.rightThumbstickDown {
            cstickPosition.y = 0
            threeDSCore.thumbstickMoved(.cStick, Float(cstickPosition.x), Float(cstickPosition.y))
        } else if input == ThreeDSGameInput.rightThumbstickLeft || input == ThreeDSGameInput.rightThumbstickRight {
            cstickPosition.x = 0
            threeDSCore.thumbstickMoved(.cStick, Float(cstickPosition.x), Float(cstickPosition.y))
        } else if input == ThreeDSGameInput.touchScreenX || input == ThreeDSGameInput.touchScreenY {
            touchPosition = .zero
            threeDSCore.touchEnded()
            
        }  else {
            if let gameInput = ThreeDSGameInput(rawValue: input) {
                let type = gameInputToCoreInput(gameInput: gameInput)
                if type != .debug {
                    threeDSCore.virtualControllerButtonUp(type)
                }
            }
        }
    }
    
    func updateViews(topRect: CGRect, bottomRect: CGRect) {
        self.topRect = topRect
        self.bottomRect = bottomRect
        updateConfig(buildLayoutConfig())
        DispatchQueue.main.asyncAfter(delay: 0.75) {
            if let metalView = self.metalView {
                self.threeDSCore.orientationChange(with: UIDevice.currentOrientation, using: metalView)
            }
        }
    }
    
    func reload() {
        threeDSCore.reset()
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
    
    private func updateConfig(_ updates: [String: Any] = [:]) {
        var defaultConfigs: [String: Any]
        switch Settings.defalut.threeDSMode {
        case .performance:
            if updates.count > 0 {
                updates.forEach { key, value in
                    PerformanceConfigs[key] = value
                }
            }
            defaultConfigs = PerformanceConfigs
            
        case .compatibility:
            if updates.count > 0 {
                updates.forEach { key, value in
                    CompatibilityConfigs[key] = value
                }
            }
            defaultConfigs = CompatibilityConfigs
            
        case .quality:
            if updates.count > 0 {
                updates.forEach { key, value in
                    QualityConfigs[key] = value
                }
            }
            defaultConfigs = QualityConfigs
        }
        
        defaultConfigs.forEach { key, value in
            UserDefaults.standard.set(value, forKey: "\(key)")
        }
        UserDefaults.standard.synchronize()
        threeDSCore.updateSettings(advancedMode: isAdvancedMode)
    }
    
    private func buildLayoutConfig() -> [String: Any] {
        let layout: [String: Any]
        
        layout = ["ManicEMU.customTopLeft" : topRect.minX,
                  "ManicEMU.customTopTop" : topRect.minY,
                  "ManicEMU.customTopRight" : topRect.minX + topRect.width,
                 "ManicEMU.customTopBottom" : topRect.minY + topRect.height,
                  "ManicEMU.customBottomLeft" : bottomRect.minX,
                  "ManicEMU.customBottomTop" : bottomRect.minY,
                  "ManicEMU.customBottomRight" : bottomRect.minX + bottomRect.width,
                  "ManicEMU.customBottomBottom" : bottomRect.minY + bottomRect.height]
        return layout
    }
    
    
    private lazy var PerformanceConfigs: [String: Any] = {
        [
            "ManicEMU.cpuClockPercentage" : 15,
            "ManicEMU.new3DS" : false,
            "ManicEMU.lleApplets" : false,
            "ManicEMU.regionValue" : -1,
            "ManicEMU.layoutOption" : 0,
            "ManicEMU.customLayout" : true,
            "ManicEMU.spirvShaderGeneration" : true,
            "ManicEMU.useAsyncShaderCompilation" : false,
            "ManicEMU.useAsyncPresentation" : true,
            "ManicEMU.useHardwareShaders" : true,
            "ManicEMU.useDiskShaderCache" : true,
            "ManicEMU.useShadersAccurateMul" : false,
            "ManicEMU.useNewVSync" : true,
            "ManicEMU.useShaderJIT" : false,
            "ManicEMU.resolutionFactor" : 1,
            "ManicEMU.textureFilter" : 0,
            "ManicEMU.textureSampling" : 0,
            "ManicEMU.render3D" : 0,
            "ManicEMU.factor3D" : 0,
            "ManicEMU.monoRender" : 0,
            "ManicEMU.preloadTextures" : false,
            "ManicEMU.redEyeRender" : false,
            "ManicEMU.audioMuted" : false,
            "ManicEMU.audioEmulation" : 0,
            "ManicEMU.audioStretching" : false,
            "ManicEMU.realtimeAudio": true,
            "ManicEMU.outputType" : 3,
            "ManicEMU.inputType" : 3,
            "ManicEMU.webAPIURL" : "http://88.198.47.47:5000"
        ] + buildLayoutConfig()
    }()
    
    private lazy var CompatibilityConfigs: [String: Any] = {
        [
            "ManicEMU.cpuClockPercentage" : 20,
            "ManicEMU.new3DS" : true,
            "ManicEMU.lleApplets" : false,
            "ManicEMU.regionValue" : -1,
            "ManicEMU.layoutOption" : 0,
            "ManicEMU.customLayout" : true,
            "ManicEMU.customTopLeft" : 0,
            "ManicEMU.customTopTop" : 0,
            "ManicEMU.spirvShaderGeneration" : true,
            "ManicEMU.useAsyncShaderCompilation" : false,
            "ManicEMU.useAsyncPresentation" : true,
            "ManicEMU.useHardwareShaders" : true,
            "ManicEMU.useDiskShaderCache" : true,
            "ManicEMU.useShadersAccurateMul" : false,
            "ManicEMU.useNewVSync" : true,
            "ManicEMU.useShaderJIT" : false,
            "ManicEMU.resolutionFactor" : 1,
            "ManicEMU.textureFilter" : 0,
            "ManicEMU.textureSampling" : 0,
            "ManicEMU.render3D" : 0,
            "ManicEMU.factor3D" : 0,
            "ManicEMU.monoRender" : 0,
            "ManicEMU.preloadTextures" : false,
            "ManicEMU.redEyeRender" : false,
            "ManicEMU.audioMuted" : false,
            "ManicEMU.audioEmulation" : 0, //"HLE" : 0, "LLE" : 1, "LLE (Multithreaded)" : 2
            "ManicEMU.audioStretching" : false,
            "ManicEMU.realtimeAudio": true,
            "ManicEMU.outputType" : 3, //Auto = 0, Null = 1, Cubeb = 2, OpenAL = 3, SDL3 = 4,
            "ManicEMU.inputType" : 3,//Auto = 0, Null = 1, Static = 2, Cubeb = 3, OpenAL = 4,
            "ManicEMU.webAPIURL" : "http://88.198.47.47:5000"
        ] + buildLayoutConfig()
    }()
    
    private lazy var QualityConfigs: [String: Any] = {
        [
            "ManicEMU.cpuClockPercentage" : 25,
            "ManicEMU.new3DS" : true,
            "ManicEMU.lleApplets" : false,
            "ManicEMU.regionValue" : -1,
            "ManicEMU.layoutOption" : 0,
            "ManicEMU.customLayout" : true,
            "ManicEMU.customTopLeft" : 0,
            "ManicEMU.customTopTop" : 0,
            "ManicEMU.spirvShaderGeneration" : true,
            "ManicEMU.useAsyncShaderCompilation" : false,
            "ManicEMU.useAsyncPresentation" : true,
            "ManicEMU.useHardwareShaders" : true,
            "ManicEMU.useDiskShaderCache" : true,
            "ManicEMU.useShadersAccurateMul" : false,
            "ManicEMU.useNewVSync" : true,
            "ManicEMU.useShaderJIT" : false,
            "ManicEMU.resolutionFactor" : 1,
            "ManicEMU.textureFilter" : 0,
            "ManicEMU.textureSampling" : 0,
            "ManicEMU.render3D" : 0,
            "ManicEMU.factor3D" : 0,
            "ManicEMU.monoRender" : 0,
            "ManicEMU.preloadTextures" : false,
            "ManicEMU.redEyeRender" : false,
            "ManicEMU.audioMuted" : false,
            "ManicEMU.audioEmulation" : 0,
            "ManicEMU.audioStretching" : false,
            "ManicEMU.realtimeAudio": true,
            "ManicEMU.outputType" : 3,
            "ManicEMU.inputType" : 3,
            "ManicEMU.webAPIURL" : "http://88.198.47.47:5000"
        ] + buildLayoutConfig()
    }()
}

#else
class ThreeDSEmulatorBridge : NSObject, EmulatorBase {
    static let shared = ThreeDSEmulatorBridge()
    
    var gameURL: URL?
    
    private(set) var frameDuration: TimeInterval = (1.0 / 60.0)
    
    var audioRenderer: (any ManicEmuCore.AudioRenderProtocol)?
    
    var videoRenderer: (any ManicEmuCore.VideoRenderProtocol)?
    
    var saveUpdateHandler: (() -> Void)?
    
    private var thumbstickPosition: CGPoint = .zero
    private var cstickPosition: CGPoint = .zero
    private var touchPosition: CGPoint = .zero
    
    private weak var metalView: MTKView? = nil
    
    private var topRect: CGRect = .zero
    private var bottomRect: CGRect = .zero
    
    func setSimBlowing(start: Bool) {}
    
    func jumpToHome() {}
    
    func loadAmiibo(path: String) {}
    
    func isAmiiboSearching() -> Bool { return false }
    
    func setResolution(resolution: GameSetting.Resolution) {}
    
    func openKeyboardAction(_ action: ((_ hintText:String?, _ keyboardType: ThreeDSKeyboardType, _ maxTextSize: UInt16) -> Void)? = nil) {}
    
    func start(withGameURL gameURL: URL, metalView: MTKView, metalViewFrame: CGRect, topRect: CGRect, bottomRect: CGRect, mute: Bool, resolution: GameSetting.Resolution = .one, jit: Bool = false, accurateShaders: Bool = false, language: Int = -1, renderRightEye: Bool = false, advancedMode: Bool = Settings.defalut.threeDSAdvancedSettingMode) {
       
    }
    
    func start(withGameURL gameURL: URL) {}
    
    func destory() {
    }
    
    func stop() {
    }
    
    func pause() {
        
    }
    
    func resume() {
       
    }
    
    var saveStateCount: Int {
        return 0
    }
    
    func addSaveState(fileUrl: URL, slot: UInt32) {
       
    }
    
    func saveState() -> (isSuccess: Bool, path: String) {
      return (true, "")
    }
    
    func loadState(_ slot: UInt32? = nil) {
       
    }
    
    func enableVolume() {
        
    }
    
    func disableVolume() {
        
    }
    
    func runFrame(processVideo: Bool) { }
    
    
    func activateInput(_ input: Int, value: Double, playerIndex: Int) {}
    
    func deactivateInput(_ input: Int, playerIndex: Int) {}
    
    func updateViews(topRect: CGRect, bottomRect: CGRect) {}
    
    func reload() {}
    
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

#endif

class AzaharEmulatorBridge : NSObject, EmulatorBase {
    
    static let shared = AzaharEmulatorBridge()
    
    var gameURL: URL?
    
    private(set) var frameDuration: TimeInterval = (1.0 / 60.0)
    
    var audioRenderer: (any ManicEmuCore.AudioRenderProtocol)?
    
    var videoRenderer: (any ManicEmuCore.VideoRenderProtocol)?
    
    var saveUpdateHandler: (() -> Void)?
    
    private var thumbstickPosition: CGPoint = .zero
    private var cstickPosition: CGPoint = .zero
    private var touchPointX: CGFloat? = nil
    private var touchPointY: CGFloat? = nil
    var touchInputFrame: CGRect = .zero
    
    func start(withGameURL gameURL: URL) {}
    
    func stop() {}
    
    func pause() {}
    
    func resume() {}
    
    func runFrame(processVideo: Bool) { }
    
    func activateInput(_ input: Int, value: Double, playerIndex: Int) {
        /**
         摇杆坐标
         0,1
         
   -1,0  0,0  1,0
         
         0,-1
         */
        if input == ThreeDSGameInput.leftThumbstickUp || input == ThreeDSGameInput.leftThumbstickDown {
            
            thumbstickPosition.y = input == ThreeDSGameInput.leftThumbstickUp ? value : -value
            LibretroCore.sharedInstance().moveStick(true, x: thumbstickPosition.x, y: thumbstickPosition.y, playerIndex: UInt32(playerIndex))
            
            
        } else if input == ThreeDSGameInput.leftThumbstickLeft || input == ThreeDSGameInput.leftThumbstickRight {
            
            thumbstickPosition.x = input == ThreeDSGameInput.leftThumbstickRight ? value : -value
            LibretroCore.sharedInstance().moveStick(true, x: thumbstickPosition.x, y: thumbstickPosition.y, playerIndex: UInt32(playerIndex))
            
        } else if input == ThreeDSGameInput.rightThumbstickUp || input == ThreeDSGameInput.rightThumbstickDown {
            
            cstickPosition.y = input == ThreeDSGameInput.rightThumbstickUp ? value : -value
            LibretroCore.sharedInstance().moveStick(false, x: cstickPosition.x, y: cstickPosition.y, playerIndex: UInt32(playerIndex))
            
        } else if input == ThreeDSGameInput.rightThumbstickLeft || input == ThreeDSGameInput.rightThumbstickRight {
            
            cstickPosition.x = input == ThreeDSGameInput.rightThumbstickRight ? value : -value
            LibretroCore.sharedInstance().moveStick(false, x: cstickPosition.x, y: cstickPosition.y, playerIndex: UInt32(playerIndex))
            
        } else if input == ThreeDSGameInput.touchScreenX || input == ThreeDSGameInput.touchScreenY {
            if input == ThreeDSGameInput.touchScreenX {
                touchPointX = value
            } else if input == ThreeDSGameInput.touchScreenY {
                touchPointY = value
            }
            if let x = touchPointX, let y = touchPointY {
                let touchPoint = CGPoint(x: touchInputFrame.minX + touchInputFrame.width*x, y: touchInputFrame.minY + touchInputFrame.height*y)
                
#if DEBUG
                Log.debug("\(String(describing: Self.self)) 触摸屏幕:\(touchPoint)")
#endif
                LibretroCore.sharedInstance().sendTouchEventX(touchPoint.x, y: touchPoint.y)
                touchPointX = nil
                touchPointY = nil
            }
        } else if let gameInput = ThreeDSGameInput(rawValue: input),
                  let libretroButton = gameInputToCoreInput(gameInput: gameInput) {
#if DEBUG
                Log.debug("\(String(describing: Self.self))点击了:\(gameInput)")
#endif
                LibretroCore.sharedInstance().press(libretroButton, playerIndex: UInt32(playerIndex))
        }
    }
    
    func gameInputToCoreInput(gameInput: ThreeDSGameInput) -> LibretroButton? {
        if gameInput == .a { return .A }
        else if gameInput == .b { return .B }
        else if gameInput == .x { return .X }
        else if gameInput == .y { return .Y }
        else if gameInput == .start { return .start }
        else if gameInput == .select { return .select }
        else if gameInput == .l1 { return .L1 }
        else if gameInput == .l2 { return .L2 }
        else if gameInput == .r1 { return .R1 }
        else if gameInput == .r2 { return .R2 }
        else if gameInput == .up { return .up }
        else if gameInput == .down { return .down }
        else if gameInput == .left { return .left }
        else if gameInput == .right { return .right }
        else { return nil }
    }
    
    func deactivateInput(_ input: Int, playerIndex: Int) {
        if input == ThreeDSGameInput.leftThumbstickUp || input == ThreeDSGameInput.leftThumbstickDown {
            thumbstickPosition.y = 0
            LibretroCore.sharedInstance().moveStick(true, x: thumbstickPosition.x, y: thumbstickPosition.y, playerIndex: UInt32(playerIndex))
        } else if input == ThreeDSGameInput.leftThumbstickLeft || input == ThreeDSGameInput.leftThumbstickRight {
            thumbstickPosition.x = 0
            LibretroCore.sharedInstance().moveStick(true, x: thumbstickPosition.x, y: thumbstickPosition.y, playerIndex: UInt32(playerIndex))
        } else if input == ThreeDSGameInput.rightThumbstickUp || input == ThreeDSGameInput.rightThumbstickDown {
            cstickPosition.y = 0
            LibretroCore.sharedInstance().moveStick(false, x: cstickPosition.x, y: cstickPosition.y, playerIndex: UInt32(playerIndex))
        } else if input == ThreeDSGameInput.rightThumbstickLeft || input == ThreeDSGameInput.rightThumbstickRight {
            cstickPosition.x = 0
            LibretroCore.sharedInstance().moveStick(false, x: cstickPosition.x, y: cstickPosition.y, playerIndex: UInt32(playerIndex))
        } else if input == ThreeDSGameInput.touchScreenX || input == ThreeDSGameInput.touchScreenY {
            if input == ThreeDSGameInput.touchScreenX {
                touchPointX = nil
            } else if input == ThreeDSGameInput.touchScreenY {
                touchPointY = nil
            }
            if touchPointX == nil, touchPointY == nil {
                LibretroCore.sharedInstance().releaseTouchEvent()
            }
        } else if let gameInput = ThreeDSGameInput(rawValue: input),
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
