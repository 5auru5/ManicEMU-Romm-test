//
//  HowToButton.swift
//  ManicEmu
//
//  Created by Daiuno on 2025/2/22.
//  Copyright © 2025 Manic EMU. All rights reserved.
//
// SPDX-License-Identifier: AGPL-3.0-or-later

class HowToButton: UIView {
    // iOS 26+ 使用 UIButton 作为 glass 容器
    private var glassButton: UIButton?
    
    /// 返回应该接收手势识别器的视图（iOS 26 返回内部按钮，iOS 25 返回自身）
    private var interactiveView: UIView {
        if #available(iOS 26.0, *), let glassButton = glassButton {
            return glassButton
        }
        return self
    }
    
    var label: UILabel = {
        let view = UILabel()
        view.textAlignment = .center
        view.font = Constants.Font.caption(size: .l)
        view.textColor = Constants.Color.Main
        return view
    }()
    
    /// 是否启用 Glass 效果（仅 iOS 26+ 有效）
    private var isGlassEnabled: Bool = false
    
    init(title: String, 
         enableGlass: Bool = false, 
         cornerStyle: UIButton.Configuration.CornerStyle = .capsule,
         tapGesture: (()->Void)?) {
        super.init(frame: .zero)
        
        self.isGlassEnabled = enableGlass
        label.text = title
        
        // 只有 iOS 26+ 且 enableGlass 为 true 时才使用 glass 效果
        if #available(iOS 26.0, *), enableGlass {
            setupGlassButton(cornerStyle: cornerStyle)
        } else {
            setupTraditionalView()
        }
        
        // 添加点击手势
        addTapGesture { gesture in
            tapGesture?()
        }
    }
    
    @available(iOS 26.0, *)
    private func setupGlassButton(cornerStyle: UIButton.Configuration.CornerStyle) {
        backgroundColor = .clear
        
        // 创建 glass 容器按钮（只提供 glass 效果，不显示内容）
        var config = UIButton.Configuration.glass()
        config.cornerStyle = cornerStyle
        
        let button = UIButton(configuration: config)
        button.isUserInteractionEnabled = true // iOS 26 的 Liquid Glass 需要处理触摸以显示视觉效果
        glassButton = button
        addSubview(button)
        
        button.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        // 在 glass 容器内添加 label
        button.addSubview(label)
        label.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(Constants.Size.ContentSpaceMin)
            make.centerY.equalToSuperview()
        }
    }
    
    private func setupTraditionalView() {
        enableInteractive = true
        backgroundColor = Constants.Color.BackgroundSecondary
        
        addSubview(label)
        label.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(Constants.Size.ContentSpaceMin)
            make.centerY.equalToSuperview()
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        updateCornerRadius()
    }
    
    private func updateCornerRadius() {
        let radius = height/2
        layerCornerRadius = radius
        
        // 同时更新 glassButton 的圆角
        if #available(iOS 26.0, *), let glassButton = glassButton {
            glassButton.layer.cornerRadius = radius
            glassButton.clipsToBounds = true
        }
    }
    
    /// 重写 addGestureRecognizer，确保手势识别器添加到正确的视图
    /// iOS 26: 添加到内部的 glassButton
    /// iOS 25: 添加到父视图自身
    override func addGestureRecognizer(_ gestureRecognizer: UIGestureRecognizer) {
        if #available(iOS 26.0, *), let glassButton = glassButton {
            glassButton.addGestureRecognizer(gestureRecognizer)
        } else {
            super.addGestureRecognizer(gestureRecognizer)
        }
    }
    
    /// 重写 removeGestureRecognizer，确保从正确的视图移除
    override func removeGestureRecognizer(_ gestureRecognizer: UIGestureRecognizer) {
        if #available(iOS 26.0, *), let glassButton = glassButton {
            glassButton.removeGestureRecognizer(gestureRecognizer)
        } else {
            super.removeGestureRecognizer(gestureRecognizer)
        }
    }
}
