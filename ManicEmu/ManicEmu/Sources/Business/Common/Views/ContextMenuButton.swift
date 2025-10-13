//
//  ContextMenuButton.swift
//  ManicEmu
//
//  Created by Daiuno on 2025/2/22.
//  Copyright © 2025 Manic EMU. All rights reserved.
//
// SPDX-License-Identifier: AGPL-3.0-or-later

class ContextMenuButton: UIButton {
    /// 是否启用 Glass 效果（仅 iOS 26+ 有效）
    private var isGlassEnabled: Bool = false
    
    init(image: UIImage? = nil, 
         menu: UIMenu? = nil, 
         enableGlass: Bool = false,
         cornerStyle: UIButton.Configuration.CornerStyle = .capsule) {
        super.init(frame: .zero)
        
        self.isGlassEnabled = enableGlass
        
        // 只有 iOS 26+ 且 enableGlass 为 true 时才使用 glass 效果
        if #available(iOS 26.0, *), enableGlass {
            // iOS 26 + Glass enabled: 使用 UIButton.Configuration.glass()
            var config = UIButton.Configuration.glass()
            config.cornerStyle = cornerStyle
            
            if let image = image {
                config.image = image
            }
            
            self.configuration = config
            // iOS 26 的 Liquid Glass 自带按压效果，不需要 enableInteractive
        } else {
            // iOS 25 及以下 或 enableGlass 为 false: 使用传统方式
            if let image = image {
                setImageForAllStates(image)
            }
            // 使用 enableInteractive 提供按压动画
            enableInteractive = true
        }
        
        if let menu = menu {
            self.menu = menu
        }
        showsMenuAsPrimaryAction = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override public func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        guard enableInteractive else { return }
        touchMoved(touch: touches.first)
    }
    
    override public func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)
        guard enableInteractive else { return }
        touchMoved(touch: touches.first)
    }
    
    override public func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        guard enableInteractive else { return }
        if delayInteractiveTouchEnd {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05, execute: { [weak self] in
                self?.touchEnded(touch: touches.first)
            })
        } else {
            touchEnded(touch: touches.first)
        }
    }
    
    override public func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        guard enableInteractive else { return }
        if delayInteractiveTouchEnd {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05, execute: { [weak self] in
                self?.touchEnded(touch: touches.first)
            })
        } else {
            touchEnded(touch: touches.first)
        }
    }
    
    func triggerTapGesture() {
        if let gestureRecognizer = gestureRecognizers?.first(where: { $0.description.contains("UITouchDownGestureRecognizer") }) {
            gestureRecognizer.touchesBegan([], with: UIEvent())
        }
    }
}
