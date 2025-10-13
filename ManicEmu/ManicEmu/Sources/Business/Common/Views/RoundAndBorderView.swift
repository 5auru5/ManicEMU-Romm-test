//
//  RoundAndBorderView.swift
//  ManicEmu
//
//  Created by Daiuno on 2025/3/2.
//  Copyright © 2025 Manic EMU. All rights reserved.
//
// SPDX-License-Identifier: AGPL-3.0-or-later

class RoundAndBorderView: UIView {
    var roundCorner: UIRectCorner {
        didSet {
            self.layoutSubviews()
        }
    }
    var radius: CGFloat {
        didSet {
            self.layoutSubviews()
        }
    }
    var borderColor: UIColor {
        didSet {
            self.layoutSubviews()
        }
    }
    var borderWidth: CGFloat {
        didSet {
            self.layoutSubviews()
        }
    }
    
    init(roundCorner: UIRectCorner = [],
         radius: CGFloat = Constants.Size.CornerRadiusMax,
         borderColor: UIColor = Constants.Color.Border,
         borderWidth: CGFloat = 1) {
        self.roundCorner = roundCorner
        self.radius = radius
        self.borderColor = borderColor
        self.borderWidth = borderWidth
        super.init(frame: .zero)
        borderLayer.fillColor = nil
        layer.addSublayer(borderLayer)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private let roundShape = CAShapeLayer()
    private let borderLayer = CAShapeLayer()

    override func layoutSubviews() {
        super.layoutSubviews()
        let roundMaskPath = UIBezierPath(roundedRect: bounds, byRoundingCorners: roundCorner, cornerRadii: CGSize(width: radius, height: radius)).cgPath
        roundShape.path = roundMaskPath
        layer.mask = roundShape
        borderLayer.path = roundMaskPath
        borderLayer.lineWidth = borderWidth
        borderLayer.strokeColor = borderColor.cgColor
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            borderLayer.strokeColor = borderColor.cgColor
        }
    }
}
