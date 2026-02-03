//
//  AlertWindow.swift
//  
//
//  Created by xaoxuu on 2022/9/8.
//

import UIKit

class AlertWindow: Window {
    
    var alerts: [AlertTarget] = []
    
    override var usingBackground: Bool { true }
    
    static func createAttachedWindowIfNotExists(config: AlertConfiguration) -> AlertWindow {
        let windowScene = AppContext.windowScene
        if let windowScene = windowScene, let w = AppContext.alertWindow[windowScene] {
            return w
        }
        let w: AlertWindow
        if let scene = windowScene {
            w = .init(windowScene: scene)
        } else {
            w = .init(frame: AppContext.appBounds)
        }
        w.tintColor = UIColor(red: 1, green: 36/255, blue: 66/255, alpha: 1)
        if let windowScene = windowScene {
            AppContext.alertWindow[windowScene] = w
        }
        // 比原生alert层级低一点
        w.windowLevel = .phAlert
        return w
    }
    
}

extension AlertTarget {
    var attachedWindow: AlertWindow? {
        view.window as? AlertWindow ?? AppContext.current?.alertWindow
    }
}
