//
//  RadialGradientView.swift
//  ManicEmu
//
//  Created by Daiuno on 2025/8/19.
//  Copyright © 2025 Manic EMU. All rights reserved.
//
// SPDX-License-Identifier: AGPL-3.0-or-later

import BlurUIKit

class RadialGradientView: UIView {
    private var lastSize: CGSize? = nil
    private let imageView = UIImageView()
    private var gradientColorChangeNotification: Any? = nil
    private var appearanceChangeNotification: Any? = nil
    
    deinit {
        if let gradientColorChangeNotification {
            NotificationCenter.default.removeObserver(gradientColorChangeNotification)
        }
        if let appearanceChangeNotification {
            NotificationCenter.default.removeObserver(appearanceChangeNotification)
        }
    }
    
    init() {
        super.init(frame: .zero)
        addSubview(imageView)
        imageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        let view = BlurUIKit.VariableBlurView()
        view.maximumBlurRadius = 20
        view.dimmingAlpha = .interfaceStyle(lightModeAlpha: 0.5, darkModeAlpha: 0.6)
        view.dimmingTintColor = Constants.Color.BackgroundPrimary
        addSubview(view)
        view.snp.makeConstraints { make in
            make.leading.top.trailing.equalToSuperview()
            make.height.equalToSuperview().multipliedBy(2)
        }
        
        gradientColorChangeNotification = NotificationCenter.default.addObserver(forName: Constants.NotificationName.GradientColorChange, object: nil, queue: .main) { [weak self] notification in
            guard let self = self else { return }
            self.updateImage()
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        guard size != .zero else { return }
        if let lastSize, lastSize == size { return }
        updateImage()
        lastSize = size
    }
    
    private func updateImage() {
        let size = self.size
        UIImage.radialGradientImage(size: size, colors: Constants.Color.Gradient + [Constants.Color.BackgroundPrimary.forceStyle(.dark)]) { [weak self] darkImage in
            UIImage.radialGradientImage(size: size, colors: Constants.Color.Gradient + [Constants.Color.BackgroundPrimary.forceStyle(.light)]) { [weak self] lightImage in
                if let darkImage, let lightImage {
                    self?.imageView.image = UIImage(.dm, light: lightImage, dark: darkImage)
                }
            }
        }
    }
}
