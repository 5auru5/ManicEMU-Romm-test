//
//  UIDeviceExtensions.swift
//  ManicEmu
//
//  Created by Aoshuang Lee on 2024/12/25.
//  Copyright © 2024 Manic EMU. All rights reserved.
//
// SPDX-License-Identifier: AGPL-3.0-or-later

import UIKit
import CoreHaptics
import Haptica
import AudioToolbox.AudioServices
import ARKit
import Metal
import Device

extension UIDevice {
    static func generateHaptic(style: HapticFeedbackStyle = .soft) {
        if supportsHaptics {
            Haptic.impact(style).generate()
        } else {
            AudioServicesPlaySystemSound(1130)
        }
    }
    
    static func generateAchievementHaptic() {
        let achievementPattern: [Note] = [
            // 开场强烈震动
            .haptic(.impact(.heavy)),
            .wait(0.1),
            .haptic(.impact(.rigid)),

            // 节奏庆祝（三连击）
            .wait(0.15),
            .haptic(.impact(.medium)),
            .wait(0.1),
            .haptic(.impact(.medium)),
            .wait(0.1),
            .haptic(.impact(.medium)),

            // 收尾轻快感
            .wait(0.2),
            .haptic(.impact(.light)),
            .wait(0.05),
            .haptic(.impact(.soft))
        ]
        Haptic.play(achievementPattern)
    }
    
    static var supportsHaptics: Bool {
        CHHapticEngine.capabilitiesForHardware().supportsHaptics
    }
    
    enum LayoutStyle: String {
        case iPadFullscreen = "iPad Full Screen"
        case iPadHalfScreen = "iPad 1/2 Screen"
        case iPadTwoThirdScreeen = "iPad 2/3 Screen"
        case iPadOneThirdScreen = "iPad 1/3 Screen"
        case iPhoneFullScreen = "iPhone"
    }
    
    static var layoutStyle: LayoutStyle {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return .iPhoneFullScreen
        }
        let screenSize = UIScreen.main.bounds.size
        let appSize = Constants.Size.WindowSize
        let screenWidth = screenSize.width
        let appWidth = appSize.width
        
        if screenSize == appSize {
            return .iPadFullscreen
        }
        let persent = CGFloat(appWidth / screenWidth) * 100.0
        if persent <= 55.0 && persent >= 45.0 {
            // 半分屏
            return .iPadHalfScreen
        } else if persent > 55.0 {
            // 2/3
            return .iPadTwoThirdScreeen
        } else {
            // 1/3
            return .iPadOneThirdScreen
        }
    }
    static var isLandscape: Bool {
        UIDevice.currentOrientation == .landscapeLeft || UIDevice.currentOrientation == .landscapeRight
    }
    
    static var isPadMini: Bool {
        if UIDevice.isPad, Constants.Size.WindowSize.minDimension <= 744 {
            return true
        }
        return false
    }
    
    static var isSmallScreenPhone: Bool {
        return Device.size().rawValue < Size.screen5_8Inch.rawValue
    }
    
    static var currentOrientation: UIInterfaceOrientation {
        UIWindow.applicationWindow?.windowScene?.interfaceOrientation ?? .portrait
    }
    static var hasNotch: Bool {
        let insets = Constants.Size.SafeAera
        let orientation = UIDevice.currentOrientation
        if orientation == .landscapeRight {
            return insets.left > 20
        } else if orientation == .landscapeLeft {
            return insets.right > 20
        } else if orientation == .portraitUpsideDown {
            return insets.bottom > 20
        }
        return insets.top > 20
    }
    
    var language: String {
        if let lan = Locale.preferredLanguages.first {
            switch lan {
            case contains(string: "Hans"):
                return "zh-hans"
            case contains(string: "Hant"):
                return "zh-hant"
            case hasPrefix(prefix: "en"):
                return "en"
            default:
                return "en"
            }
        }
        return "en"
    }
    
    private static var mtlDevice: MTLDevice? = MTLCreateSystemDefaultDevice()
    
    var hasA9ProcessorOrBetter: Bool {
        // ARKit is only supported by devices with an A9 processor or better, according to the documentation.
        // https://developer.apple.com/documentation/arkit/arconfiguration/2923553-issupported
        return ARConfiguration.isSupported
    }
    
    var hasA11ProcessorOrBetter: Bool {
        guard let mtlDevice = UIDevice.mtlDevice else { return false }
        return mtlDevice.supportsFeatureSet(.iOS_GPUFamily4_v1) // iOS GPU Family 4 = A11 GPU
    }
    
    var hasA15ProcessorOrBetter: Bool {
        guard let mtlDevice = UIDevice.mtlDevice else { return false }
        return mtlDevice.supportsFamily(.apple8) // Apple 8 = A15/A16/M2 GPU
    }
    
    static var isPhone: Bool {
        if Device.isPhone() || Device.isPod() {
            return true
        } else if Device.isSimulator() {
            if Constants.Size.WindowSize.minDimension < 744 { //ipad mini 8.3寸 最小宽度是744
                return true
            }
        }
        return false
    }
    
    static var isPad: Bool {
        if Device.isPad() {
            return true
        } else if Device.isSimulator() {
            if Constants.Size.WindowSize.minDimension >= 744 { //ipad mini 8.3寸 最小宽度是744
                return true
            }
        }
        return false
    }
    
    static var deviceInfo: String {
        return "Device:\(Device.version())\nVersion:\(UIDevice.current.systemVersion)"
    }
    
    static var isDarkMode: Bool {
        ApplicationSceneDelegate.applicationWindow?.traitCollection.userInterfaceStyle == .dark
    }
}


