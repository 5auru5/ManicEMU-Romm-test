//
//  GameSetting.swift
//  ManicEmu
//
//  Created by Daiuno on 2025/3/5.
//  Copyright © 2025 Manic EMU. All rights reserved.
//
// SPDX-License-Identifier: AGPL-3.0-or-later

import RealmSwift
import ManicEmuCore

struct GameSetting: SettingCellItem {
    enum ControllerType: Int, PersistableEnum {
        case dPad, thumbStick
        
        var image: UIImage {
            switch self {
            case .dPad:
                UIImage(symbol: .dpad)
            case .thumbStick:
                R.image.customArcadeStick()!.applySymbolConfig()
            }
        }
        
        var title: String {
            switch self {
            case .dPad:
                R.string.localizable.gameSettingControllerTypeDPad()
            case .thumbStick:
                R.string.localizable.gameSettingControllerTypeStick()
            }
        }
        
        var next: ControllerType {
            return self == .dPad ? .thumbStick : .dPad
        }
    }
    
    enum HapticType: Int, PersistableEnum {
        case off, soft, light, medium, heavy, rigid
        
        var image: UIImage {
            switch self {
            case .off:
                UIImage(symbol: .iphoneSlash)
            default:
                UIImage(symbol: .iphoneRadiowavesLeftAndRight)
            }
        }
        
        var title: String {
            switch self {
            case .off:
                R.string.localizable.gameSettingHapticOff()
            case .soft:
                R.string.localizable.gameSettingHapticSoft()
            case .light:
                R.string.localizable.gameSettingHapticLight()
            case .medium:
                R.string.localizable.gameSettingHapticMedium()
            case .heavy:
                R.string.localizable.gameSettingHapticHeavy()
            case .rigid:
                R.string.localizable.gameSettingHapticRigid()
            }
        }
        
        var next: HapticType {
            if let type = HapticType(rawValue: self.rawValue + 1) {
                return type
            } else {
                return .off
            }
        }
    }
    
    enum OrientationType: Int, PersistableEnum {
        case auto, portrait, landscape
        
        var title: String {
            switch self {
            case .auto:
                R.string.localizable.gameSettingOrientationAuto()
            case .portrait:
                R.string.localizable.gameSettingOrientationPortrait()
            case .landscape:
                R.string.localizable.gameSettingOrientationLandscape()
            }
        }
        
        var next: OrientationType {
            if let type = OrientationType(rawValue: self.rawValue + 1) {
                return type
            } else {
                return .auto
            }
        }
    }
    
    enum FastForwardSpeed: Int, CaseIterable, PersistableEnum  {
        case one = 1, two, three, four, five
        
        var title: String {
            R.string.localizable.gameSettingFastForward(self == .one ? "" : " x\(self.rawValue)")
        }
        
        var next: FastForwardSpeed {
            if let speed = FastForwardSpeed(rawValue: self.rawValue + 1) {
                return speed
            } else {
                return .one
            }
        }
    }
    
    //undefine是为了realm迁移时不出问题
    enum Resolution: Int, CaseIterable, PersistableEnum  {
        case undefine, one, two, three, four, five, six, seven, eight, nine, ten
        
        var title: String {
            return R.string.localizable.gameSettingResolution(self == .undefine ? "x1" : "x\(self.rawValue)")
        }
        
        var next: Resolution {
            if let speed = Resolution(rawValue: self.rawValue + 1) {
                return speed
            } else {
                return .one
            }
        }
        
        //PS1
        static var ResolutionForPS1: [Resolution] { Array(Resolution.allCases[1..<5]) }
        
        static var AllResolutionTitleForPS1: [String] { ["1x", "2x", "4x", "8x"] }
        
        var resolutionTitleForPS1: String {
            let titles = Self.AllResolutionTitleForPS1
            if let index = Self.ResolutionForPS1.firstIndex(of: self), index < titles.count {
                return titles[index]
            }
            return "1x"
        }
        
        var nextForPS1: Resolution {
            if let p = Resolution(rawValue: self.rawValue + 1), Self.ResolutionForPS1.contains([p]) {
                return p
            } else {
                return .one
            }
        }
        
        //N64ParaLLEl
        static var ResolutionForN64ParaLLEl: [Resolution] { Array(Resolution.allCases[1..<4]) }
        
        static var AllResolutionTitleForN64ParaLLEl: [String] { ["1x", "2x", "4x"] }
        
        var resolutionTitleForN64ParaLLEl: String {
            let titles = Self.AllResolutionTitleForN64ParaLLEl
            if let index = Self.ResolutionForN64ParaLLEl.firstIndex(of: self), index < titles.count {
                return titles[index]
            }
            return "1x"
        }
        
        var nextForN64ParaLLEl: Resolution {
            if let p = Resolution(rawValue: self.rawValue + 1), Self.ResolutionForN64ParaLLEl.contains([p]) {
                return p
            } else {
                return .one
            }
        }
    }
    
    enum Palette: Int, CaseIterable, PersistableEnum {
        case None, DMG, Light, Pocket, Blue, Brown, DarkBlue, DarkBrown, DarkGreen, Grayscale, Green, Inverted, Orange, PastelMix, Red, Yellow
        
        var shortTitle: String {
            switch self {
            case .None: ""
            case .DMG: "DMG"
            case .Light: "Light"
            case .Pocket: "Pocket"
            case .Blue: "Blue"
            case .Brown: "Brown"
            case .DarkBlue: "Dark Blue"
            case .DarkBrown: "Dark Brown"
            case .DarkGreen: "Dark Green"
            case .Grayscale: "Grayscale"
            case .Green: "Green"
            case .Inverted: "Inverted"
            case .Orange: "Orange"
            case .PastelMix: "Pastel Mix"
            case .Red: "Red"
            case .Yellow: "Yellow"
            }
        }
        
        var optionForGambatte: String {
            switch self {
            case .None:
                ""
            case .DMG:
                "GB - DMG"
            case .Light:
                "GB - Light"
            case .Pocket:
                "GB - Pocket"
            case .Blue:
                "GBC - Blue"
            case .Brown:
                "GBC - Brown"
            case .DarkBlue:
                "GBC - Dark Blue"
            case .DarkBrown:
                "GBC - Dark Brown"
            case .DarkGreen:
                "GBC - Dark Green"
            case .Grayscale:
                "GBC - Grayscale"
            case .Green:
                "GBC - Green"
            case .Inverted:
                "GBC - Inverted"
            case .Orange:
                "GBC - Orange"
            case .PastelMix:
                "GBC - Pastel Mix"
            case .Red:
                "GBC - Red"
            case .Yellow:
                "GBC - Yellow"
            }
        }
        
        var optionForMGBA: String {
            switch self {
            case .None:
                "Grayscale"
            case .DMG:
                "DMG Green"
            case .Light:
                "GB Light"
            case .Pocket:
                "GB Pocket"
            case .Blue:
                "GBC Blue ←"
            case .Brown:
                "GBC Brown ↑"
            case .DarkBlue:
                "GBC Dark Blue ←A"
            case .DarkBrown:
                "GBC Dark Brown ↑B"
            case .DarkGreen:
                "GBC Dark Green →A"
            case .Grayscale:
                "GBC Gray ←B"
            case .Green:
                "GBC Green →"
            case .Inverted:
                "GBC Reverse →B"
            case .Orange:
                "GBC Orange ↓A"
            case .PastelMix:
                "GBC Pale Yellow ↓"
            case .Red:
                "GBC Red ↑A"
            case .Yellow:
                "GBC Yellow ↓B"
            }
        }
        
        var optionForVBAM: String {
            switch self {
            case .None:
                "black and white"
            case .DMG:
                "gba sp"
            case .Light:
                "green forest"
            case .Pocket:
                "original gameboy"
            case .Blue:
                "blue sea"
            case .Brown:
                "hot desert"
            case .DarkBlue:
                "blue sea"
            case .DarkBrown:
                "wierd colors"
            case .DarkGreen:
                "green forest"
            case .Grayscale:
                "black and white"
            case .Green:
                "green forest"
            case .Inverted:
                "dark knight"
            case .Orange:
                "hot desert"
            case .PastelMix:
                "wierd colors"
            case .Red:
                "pink dreams"
            case .Yellow:
                "hot desert"
            }
        }
        
        var title: String {
            return R.string.localizable.paletteTitle() +  (self == .None ? "" : "\n") + shortTitle
        }
        
        var next: Palette {
            if let p = Palette(rawValue: self.rawValue + 1) {
                return p
            } else {
                return .None
            }
        }
        
        //For VB
        static var PalettesForVB: [Palette] { Array(Palette.allCases[0..<8]) }
        
        static var AllPaletteTitleForVB: [String] { ["black & red", "black & white", "black & blue", "black & cyan", "black & electric cyan", "black & green", "black & magenta", "black & yellow"] }
        
        var paletteTitleForVB: String {
            let titles = Self.AllPaletteTitleForVB
            if let index = Self.PalettesForVB.firstIndex(of: self), index < titles.count {
                return titles[index]
            }
            return "black & red"
        }
        
        var nextForVB: Palette {
            if let p = Palette(rawValue: self.rawValue + 1), Self.PalettesForVB.contains([p]) {
                return p
            } else {
                return .None
            }
        }
        
        //For PM
        static var PalettesForPM: [Palette] { Array(Palette.allCases[0..<14]) }
        
        static var AllPaletteTitleForPM: [String] { ["Default", "Old", "Monochrome", "Green", "Green Vector", "Red", "Red Vector", "Blue LCD", "LEDBacklight", "Girl Power", "Blue", "Blue Vector", "Sepia", "Monochrome Vector"] }
        
        var paletteTitleForPM: String {
            let titles = Self.AllPaletteTitleForPM
            if let index = Self.PalettesForPM.firstIndex(of: self), index < titles.count {
                return titles[index]
            }
            return "Default"
        }
        
        var nextForPM: Palette {
            if let p = Palette(rawValue: self.rawValue + 1), Self.PalettesForPM.contains([p]) {
                return p
            } else {
                return .None
            }
        }
    }
    
    enum AirPlayScaling: Int, CaseIterable {
        case coreProvided, square, standard, widescreen, full
        
        var title: String {
            switch self {
            case .coreProvided:
                R.string.localizable.scalingCoreProvided()
            case .square:
                R.string.localizable.scalingSquare()
            case .standard:
                R.string.localizable.scalingStandard()
            case .widescreen:
                R.string.localizable.scalingWidescreen()
            case .full:
                R.string.localizable.scalingFull()
            }
        }
        
        var ratio: CGSize {
            switch self {
            case .coreProvided, .full, .square:
                    .init(1)
            case .standard:
                    .init(width: 4, height: 3)
            case .widescreen:
                    .init(width: 16, height: 9)
            }
        }
        
        var next: AirPlayScaling {
            if let type = AirPlayScaling(rawValue: self.rawValue + 1) {
                return type
            } else {
                return .coreProvided
            }
        }
    }
    
    enum AirPlayLayout: Int, CaseIterable {
        
        case embeddedTopLeft, embeddedTopRight, embeddedBottomLeft, embeddedBottomRight, sideBySide, stacked, largeSmallTopLeft, largeSmallTopRight, largeSmallBottomLeft, largeSmallBottomRight, singleScreen
        
        var title: String {
            switch self {
            case .sideBySide: R.string.localizable.layoutSideBySide()
            case .stacked: R.string.localizable.layoutStacked()
            case .largeSmallTopLeft: R.string.localizable.layoutLargeSmallTopLeft()
            case .largeSmallTopRight: R.string.localizable.layoutLargeTopRight()
            case .largeSmallBottomLeft: R.string.localizable.layoutLargeBottomLeft()
            case .largeSmallBottomRight: R.string.localizable.layoutLargeBottomRight()
            case .embeddedTopLeft: R.string.localizable.layoutEmbeddedTopLeft()
            case .embeddedTopRight: R.string.localizable.layoutEmbeddedTopRight()
            case .embeddedBottomLeft: R.string.localizable.layoutEmbeddedBottomLeft()
            case .embeddedBottomRight: R.string.localizable.layoutEmbeddedBottomRight()
            case .singleScreen: R.string.localizable.layoutSingleScreen()
            }
        }
        
        var next: AirPlayLayout {
            if let type = AirPlayLayout(rawValue: self.rawValue + 1) {
                return type
            } else {
                return .sideBySide
            }
        }
    }
    
    enum ScreenScaling: Int, CaseIterable {
        case stretch, fit
        var title: String {
            switch self {
            case .stretch: R.string.localizable.screenScalingStretch()
            case .fit: R.string.localizable.screenScalingFit()
            }
        }
        
        var next: ScreenScaling {
            if let type = ScreenScaling(rawValue: self.rawValue + 1) {
                return type
            } else {
                return .stretch
            }
        }
    }
    
    enum MappingOnlyType: Int, CaseIterable, SettingCellItem {
        case holdX2FastForward, holdX3FastForward, holdX4FastForward, holdMaxFastForward
        
        var title: String {
            switch self {
            case .holdX2FastForward:
                R.string.localizable.holdFastForward("2x")
            case .holdX3FastForward:
                R.string.localizable.holdFastForward("3x")
            case .holdX4FastForward:
                R.string.localizable.holdFastForward("4x")
            case .holdMaxFastForward:
                R.string.localizable.holdMaxFastForward()
            }
        }
        
        var image: UIImage {
            switch self {
            case .holdX2FastForward, .holdX3FastForward, .holdX4FastForward, .holdMaxFastForward:
                UIImage(symbol: .forward)
            }
        }
        
        func enable(for gameType: GameType, defaultCore: Int) -> Bool {
            if gameType == ._3ds,
               (self == .holdX2FastForward || self == .holdX3FastForward || self == .holdX4FastForward || self == .holdMaxFastForward) {
                return false
            }
            return true
        }
        
        var enableLongPress: Bool {
            switch self {
            case .holdX2FastForward, .holdX3FastForward, .holdX4FastForward, .holdMaxFastForward:
                return false
            }
        }
        
        var inputKey: String {
            switch self {
            case .holdX2FastForward:
                "fastForward2x"
            case .holdX3FastForward:
                "fastForward3x"
            case .holdX4FastForward:
                "fastForward4x"
            case .holdMaxFastForward:
                "fastForward"
            }
        }
    }
    
    enum ItemType: Int, CaseIterable {
        //位置很重要 新增内容一定要接到最后面
        case saveState, quickLoadState, volume, fastForward, stateList, cheatCode, skins, filter, screenShot, haptic, airplay, controllerSetting, orientation, functionSort, reload, quit, swapScreen, resolution, consoleHome, amiibo, toggleFullscreen, simBlowing, palette, swapDisk, retro, airPlayScaling, airPlayLayout, toggleAnalog, gameplayManuals, triggerPro, screenScaling, j2meSettings
    }
    
    var type: ItemType
    var loadState: GameSaveState? = nil
    var volumeOn: Bool = true
    var fastForwardSpeed: FastForwardSpeed = .one
    var resolution: Resolution = .one
    var hapticType: HapticType = .soft
    var controllerType: ControllerType = .dPad
    var orientation: OrientationType = .auto
    var isFullScreen: Bool = false
    var palette: Palette = .None
    var currentDiskIndex: UInt = 0
    var airPlayScaling: AirPlayScaling = .coreProvided
    var airPlayLayout: AirPlayLayout = .sideBySide
    var mappingOnlyType: MappingOnlyType? = nil
    var nesPalette = Game.defaultNesPalette
    var triggerProID: Int? = nil
    var screenScaling: ScreenScaling = .stretch
    
    var image: UIImage {
        switch type {
        case .saveState:
            R.image.customArrowDownDocument()!.applySymbolConfig()
        case .quickLoadState:
            R.image.customTextDocument()!.applySymbolConfig()
        case .stateList:
            UIImage(symbol: .listTriangle)
        case .volume:
            if volumeOn {
                UIImage(symbol: .speakerWave2)
            } else {
                UIImage(symbol: .speakerSlash)
            }
        case .fastForward:
            UIImage(symbol: .forward)
        case .cheatCode:
            R.image.customAppleTerminal()!.applySymbolConfig()
        case .skins:
            UIImage(symbol: .tshirt)
        case .filter:
            R.image.customAppBackgroundDotted()!.applySymbolConfig(size: 20)
        case .screenShot:
            UIImage(symbol: .cameraViewfinder)
        case .haptic:
            hapticType.image
        case .airplay:
            UIImage(symbol: .airplayvideo)
        case .controllerSetting:
            R.image.customArcadeStickConsole()!.applySymbolConfig()
        case .orientation:
            R.image.customRectangleLandscapeRotate()!.applySymbolConfig()
        case .functionSort:
            UIImage(symbol: .sliderHorizontalBelowRectangle)
        case .reload:
            R.image.customArrowTriangleheadClockwise()!.applySymbolConfig()
        case .quit:
            UIImage(symbol: .rectanglePortraitAndArrowRight)
        case .swapScreen:
            UIImage(symbol: .rectangle2Swap)
        case .resolution:
            UIImage(symbol: .sparklesTv)
        case .consoleHome:
            UIImage(symbol: .house)
        case .amiibo:
            UIImage(symbol: .dotRadiowavesLeftAndRight)
        case .toggleFullscreen:
            UIImage(symbol: .lJoystickPressDown)
        case .simBlowing:
            UIImage(symbol: .wind)
        case .palette:
            UIImage(symbol: .paintpalette)
        case .swapDisk:
            UIImage(symbol: .opticaldisc)
        case .retro:
            R.image.customTrophy()!.applySymbolConfig()
        case .airPlayScaling:
            UIImage(symbol: .tv)
        case .airPlayLayout:
            UIImage(symbol: .sliderHorizontalBelowSquareFilledAndSquare)
        case .toggleAnalog:
            UIImage(symbol: .gamecontroller)
        case .gameplayManuals:
            UIImage(symbol: .textBookClosed)
        case .triggerPro:
            R.image.customXmarkTriangleCircleSquare()!.applySymbolConfig()
        case .screenScaling:
            UIImage(symbol: .arrowUpRightAndArrowDownLeftRectangle)
        case .j2meSettings:
            R.image.customJava()!.applySymbolConfig(size: 30)
        }
    }
    
    var title: String {
        switch type {
        case .saveState:
            R.string.localizable.gameSettingSaveState()
        case .quickLoadState:
            R.string.localizable.gameSettingQuickLoadState()
        case .volume:
            R.string.localizable.gameSettingVolume()
        case .fastForward:
            fastForwardSpeed.title
        case .stateList:
            R.string.localizable.gameSettingStateList()
        case .cheatCode:
            R.string.localizable.gamesCheatCode()
        case .skins:
            R.string.localizable.gameSettingSkins()
        case .filter:
            R.string.localizable.shaders()
        case .screenShot:
            R.string.localizable.gameSettingScreenShot()
        case .haptic:
            hapticType.title
        case .airplay:
            R.string.localizable.gameSettingAirplay()
        case .controllerSetting:
            R.string.localizable.gameSettingControllerSetting()
        case .orientation:
            orientation.title
        case .functionSort:
            R.string.localizable.gameSettingFunctionSort()
        case .reload:
            R.string.localizable.gameSettingReload()
        case .quit:
            R.string.localizable.gameSettingQuit()
        case .swapScreen:
            R.string.localizable.gameSettingSwapScreen()
        case .resolution:
            resolution.title
        case .consoleHome:
            R.string.localizable.consoleHomeTitle()
        case .amiibo:
            R.string.localizable.amiiboTitle()
        case .toggleFullscreen:
            if isFullScreen {
                R.string.localizable.showControlsTitle()
            } else {
                R.string.localizable.hideControlsTitle()
            }
        case .simBlowing:
            R.string.localizable.simulateBlowingTitle()
        case .palette:
            palette.title
        case .swapDisk:
            R.string.localizable.swapDisk() + "\nDisc \(currentDiskIndex + 1)"
        case .retro:
            R.string.localizable.retroAchievements2()
        case .airPlayScaling:
            R.string.localizable.airPlayScaling()
        case .airPlayLayout:
            R.string.localizable.airPlayLayout()
        case .toggleAnalog:
            R.string.localizable.toggleAnolog()
        case .gameplayManuals:
            R.string.localizable.gameplayManuals()
        case .triggerPro:
            "TriggerPro"
        case .screenScaling:
            R.string.localizable.screenScaling()
        case .j2meSettings:
            R.string.localizable.j2MESettings()
        }
    }
    
    func enable(for gameType: GameType, defaultCore: Int) -> Bool {
        if let mappingOnlyType {
            return mappingOnlyType.enable(for: gameType, defaultCore: defaultCore)
        }
        
        if type == .airPlayLayout {
            return gameType == .ds || (gameType == ._3ds && defaultCore == 1)
        }
        
        if type == .toggleAnalog {
            return gameType == .ps1
        }
        
        if type == .j2meSettings {
            return gameType == .j2me
        }
        
        switch gameType {
        case .j2me:
            if  type == .saveState ||
                type == .quickLoadState ||
                (type == .fastForward && defaultCore == 1) ||
                type == .stateList ||
                type == .cheatCode ||
                type == .filter ||
                type == .swapScreen ||
                type == .resolution ||
                type == .consoleHome ||
                type == .amiibo ||
                type == .simBlowing ||
                type == .palette ||
                type == .swapDisk ||
                type == .retro ||
                type == .airPlayLayout ||
                type == .toggleAnalog  {
                return false
            }
            return true
            
        case .doom:
            if type == .swapScreen || type == .consoleHome || type == .amiibo || type == .simBlowing || type == .palette || type == .retro {
                return false
            }
            return true
                
        case .a2600, .a5200, .a7800, .lynx, .jaguar:
            if gameType == .a5200, type == .retro {
                return false
            }
            
            if gameType == .jaguar && (type == .saveState || type == .quickLoadState || type == .stateList) {
                return false
            }
            
            if type == .cheatCode || type == .swapScreen || type == .resolution || type == .consoleHome || type == .amiibo || type == .simBlowing || type == .palette || type == .swapDisk || type == .airPlayLayout || type == .toggleAnalog {
                return false
            }
            return true
        case ._3ds:
            if defaultCore == 0 {
                if type == .fastForward || type == .filter || type == .palette || type == .swapDisk || type == .retro || type == .airPlayScaling || type == .screenScaling {
                    return false
                }
            } else {
                if type == .palette || type == .swapDisk || type == .retro || type == .consoleHome {
                    return false
                }
            }
            return true
        case .ds:
            if (type == .resolution && defaultCore == 0) || type == .consoleHome || type == .amiibo || type == .palette || type == .swapDisk {
                return false
            }
            return true
        case .gba, .gbc, .gb, .nes, .fds, .snes, .md, .mcd, ._32x, .gg, .sg1000, .ms, .ss, .vb, .pm, .arcade:
            if (gameType == .gb || gameType == .vb || gameType == .pm || gameType == .nes || gameType == .fds) && type == .palette {
                return true
            }
            
            if gameType == ._32x || gameType == .mcd {
                //JGenesis核心
                let notEnableForJGenesis = (type == .cheatCode || type == .filter || type == .retro || type == .swapDisk || type == .screenScaling)
                if defaultCore == 1 && notEnableForJGenesis {
                    return false
                }
            }
            
            if ((gameType == .mcd && defaultCore == 2) || (gameType == .md && defaultCore == 0)) && type == .cheatCode {
                //ClownMDEmu核心
                return false
            }
            
            if (gameType == .mcd || gameType == .ss || gameType == .fds) && type == .swapDisk {
                return true
            }
            
            if (gameType == .vb || gameType == .pm) && type == .cheatCode {
                return false
            }
            
            if (gameType == .nes || gameType == .fds) && type == .simBlowing {
                return true
            }
            
            if gameType == .arcade, type == .retro, defaultCore == 0 {
                return false
            }
            
            if type == .swapScreen || type == .resolution || type == .consoleHome || type == .amiibo || type == .simBlowing || type == .palette || type == .swapDisk {
                return false
            }
            return true
        case .psp, .n64:
            if type == .swapScreen || type == .consoleHome || type == .amiibo || type == .simBlowing || type == .palette || type == .swapDisk {
                return false
            }
            return true
        case .ps1:
            if type == .swapScreen || type == .consoleHome || type == .amiibo || type == .simBlowing || type == .palette {
                return false
            }
            return true
        case .dc:
            if type == .swapScreen || type == .consoleHome || type == .amiibo || type == .simBlowing || type == .palette || type == .cheatCode {
                return false
            }
            return true
        default:
            return false
        }
    }
    
    var enableLongPress: Bool {
        switch self.type {
        case .quickLoadState, .fastForward, .haptic, .orientation, .resolution, .palette, .swapDisk, .airPlayScaling, .airPlayLayout, .triggerPro, .screenScaling:
            return true
        default:
            return false
        }
    }
    
    var inputKey: String {
        if let mappingOnlyType {
            return mappingOnlyType.inputKey
        }
        
        switch self.type {
        case .saveState:
            return "quickSave"
        case .quickLoadState:
            return "quickLoad"
        case .volume:
            return "volume"
        case .fastForward:
            return "toggleFastForward"
        case .stateList:
            return "saveStates"
        case .cheatCode:
            return "cheatCodes"
        case .skins:
            return "skins"
        case .filter:
            return "filters"
        case .screenShot:
            return "screenshot"
        case .haptic:
            return "haptics"
        case .airplay:
            return "airplay"
        case .controllerSetting:
            return "controllers"
        case .orientation:
            return "orientation"
        case .functionSort:
            return "functionLayout"
        case .reload:
            return "restart"
        case .quit:
            return "quit"
        case .swapScreen:
            return "reverseScreens"
        case .resolution:
            return "resolution"
        case .consoleHome:
            return "homeMenu"
        case .amiibo:
            return "amiibo"
        case .toggleFullscreen:
            return "toggleControlls"
        case .simBlowing:
            return "blowing"
        case .palette:
            return "palette"
        case .swapDisk:
            return "swapDisk"
        case .retro:
            return "retroAchievements"
        case .airPlayScaling:
            return "airPlayScaling"
        case .airPlayLayout:
            return "airPlayLayout"
        case .toggleAnalog:
            return "toggleAnalog"
        case .gameplayManuals:
            return "gameplayManuals"
        case .triggerPro:
            return "triggerPro"
        case .screenScaling:
            return "screenScaling"
        case .j2meSettings:
            return "j2meSettings"
        }
    }
    
    static func isValidInputKey(_ inputKey: String) -> Bool {
        if GameSetting.ItemType.allCases.contains(where: { GameSetting(type: $0).inputKey == inputKey }) {
            return true
        } else if MappingOnlyType.allCases.contains(where: { $0.inputKey == inputKey }) {
            return true
        }
        return false
    }
}
